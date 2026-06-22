import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../dao/consumo_dao.dart';
import '../dao/usuario_dao.dart';
import '../modelo/consumo.dart';
import '../modelo/usuario.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  static const _corPrimaria = Color(0xFF3B82F6);
  static const _corPrimariaEscura = Color(0xFF1E40AF);
  static const _corFundoCard = Color(0xFFEFF6FF);
  static const _corTextoSecundario = Color(0xFF9CA3AF);
  static const _horaInicio = 8;
  static const _horaFim = 20;
  static const _coposPorDia = 6;

  int _abaSelecionada = 0;
  bool _carregando = true;
  bool _registrando = false;
  bool _botaoPressionado = false;
  Usuario? _usuario;
  int _totalConsumido = 0;
  Set<String> _horariosConsumidos = {};
  List<Map<String, dynamic>> _consumosHoje = [];

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await initializeDateFormatting('pt_BR');
    await _carregarDados();
  }

  String get _dataHoje => DateFormat('yyyy-MM-dd').format(DateTime.now());

  String get _horarioAtual {
    final hora = DateTime.now().hour;
    return '${hora.toString().padLeft(2, '0')}:00';
  }

  int _mlPorCopo(double meta) => (meta / _coposPorDia).round();

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    final usuario = await buscarUsuario();
    final total = await totalConsumidoNoDia(_dataHoje);
    final consumos = await buscarConsumoPorData(_dataHoje);
    final horarios = consumos.map((c) => c['horario'] as String).toSet();

    if (!mounted) return;

    setState(() {
      _usuario = usuario;
      _totalConsumido = total;
      _horariosConsumidos = horarios;
      _consumosHoje = consumos;
      _carregando = false;
    });
  }

  Future<void> _registrarAgua() async {
    if (_usuario == null || _registrando) return;

    final hora = DateTime.now().hour;
    if (hora < _horaInicio || hora > _horaFim) {
      _mostrarMensagem('Registros disponíveis das ${_horaInicio}h às ${_horaFim}h');
      return;
    }

    final horario = _horarioAtual;
    if (_horariosConsumidos.contains(horario)) {
      _mostrarMensagem('Você já registrou água neste horário!');
      return;
    }

    setState(() => _registrando = true);

    final ml = _mlPorCopo(_usuario!.metaDiariaMl);
    await registrarConsumo(Consumo(
      data: _dataHoje,
      horario: horario,
      quantidadeMl: ml,
    ));

    if (!mounted) return;

    setState(() => _registrando = false);
    await _carregarDados();

    if (!mounted) return;
    _mostrarMensagem('+$ml ml registrados! Continue hidratado 💧');
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatarDataCabecalho() {
    final agora = DateTime.now();
    final diaSemana = DateFormat('EEEE', 'pt_BR').format(agora);
    final diaMes = DateFormat("dd 'de' MMMM", 'pt_BR').format(agora);
    final diaCapitalizado = diaSemana[0].toUpperCase() + diaSemana.substring(1);
    return 'Hoje — $diaCapitalizado\n$diaMes';
  }

  List<int> _horasVisiveis() {
    final horaAtual = DateTime.now().hour.clamp(_horaInicio, _horaFim);
    final inicio = (horaAtual - 2).clamp(_horaInicio, _horaFim);
    final fim = (horaAtual + 1).clamp(_horaInicio, _horaFim);
    return List.generate(fim - inicio + 1, (i) => inicio + i);
  }

  String _formatarHora(int hora) => '${hora.toString().padLeft(2, '0')}h';

  String _formatarMl(num valor) =>
      NumberFormat('#,###', 'pt_BR').format(valor.round());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(child: _buildCorpo()),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _abaSelecionada,
        selectedItemColor: _corPrimaria,
        unselectedItemColor: _corTextoSecundario,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) => setState(() => _abaSelecionada = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Hist.',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Lemb.',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Dados',
          ),
        ],
      ),
    );
  }

  Widget _buildCorpo() {
    if (_abaSelecionada != 0) {
      const titulos = ['Home', 'Histórico', 'Lembretes', 'Dados'];
      return Center(
        child: Text(
          '${titulos[_abaSelecionada]} — em breve',
          style: const TextStyle(fontSize: 18, color: _corTextoSecundario),
        ),
      );
    }

    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: _corPrimaria),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCabecalho(),
          const SizedBox(height: 20),
          _buildProgresso(),
          const SizedBox(height: 20),
          _buildBotaoGarrafa(),
          const SizedBox(height: 16),
          _buildHistoricoHoras(),
          const SizedBox(height: 16),
          Expanded(child: _buildAreaConteudo()),
        ],
      ),
    );
  }

  Widget _buildCabecalho() {
    final partes = _formatarDataCabecalho().split('\n');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: BoxDecoration(
        color: _corFundoCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Text(
                partes[0],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _corPrimariaEscura,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                partes[1],
                style: const TextStyle(
                  fontSize: 15,
                  color: _corPrimaria,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: _corTextoSecundario),
              onSelected: (valor) {
                if (valor == 'atualizar') _carregarDados();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'atualizar', child: Text('Atualizar')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgresso() {
    final meta = _usuario?.metaDiariaMl ?? 2000;
    final percentual = meta > 0 ? (_totalConsumido / meta).clamp(0.0, 1.0) : 0.0;
    final percentualTexto = (percentual * 100).round();

    return Column(
      children: [
        Text(
          '${_formatarMl(_totalConsumido)} ml',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: _corPrimariaEscura,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'de ${_formatarMl(meta)} ml — $percentualTexto%',
          style: const TextStyle(
            fontSize: 15,
            color: _corTextoSecundario,
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: percentual,
            minHeight: 10,
            backgroundColor: const Color(0xFFE5E7EB),
            color: _corPrimaria,
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoGarrafa() {
    final jaRegistrou = _horariosConsumidos.contains(_horarioAtual);
    final desabilitado = _registrando || jaRegistrou;

    return GestureDetector(
      onTapDown: desabilitado
          ? null
          : (_) => setState(() => _botaoPressionado = true),
      onTapUp: desabilitado
          ? null
          : (_) => setState(() => _botaoPressionado = false),
      onTapCancel: () => setState(() => _botaoPressionado = false),
      onTap: desabilitado ? null : _registrarAgua,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: _botaoPressionado ? 50 : 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: desabilitado
              ? _corPrimaria.withValues(alpha: 0.5)
              : (_botaoPressionado
                  ? const Color(0xFF2563EB)
                  : _corPrimaria),
          borderRadius: BorderRadius.circular(_botaoPressionado ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: _corPrimaria.withValues(
                alpha: desabilitado ? 0.1 : (_botaoPressionado ? 0.2 : 0.35),
              ),
              blurRadius: _botaoPressionado ? 4 : 10,
              offset: Offset(0, _botaoPressionado ? 2 : 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_registrando)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              AnimatedScale(
                scale: _botaoPressionado ? 0.85 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.water_drop,
                  color: Colors.white.withValues(alpha: desabilitado ? 0.7 : 1),
                  size: 22,
                ),
              ),
            const SizedBox(width: 10),
            Text(
              'Já bebi água! ✓',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: desabilitado ? 0.7 : 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricoHoras() {
    final horas = _horasVisiveis();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < horas.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '·',
                    style: TextStyle(
                      color: _corTextoSecundario,
                      fontSize: 16,
                    ),
                  ),
                ),
              _buildTextoHora(horas[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextoHora(int hora) {
    final horario = '${hora.toString().padLeft(2, '0')}:00';
    final concluido = _horariosConsumidos.contains(horario);
    final ehProximo = !concluido && hora == DateTime.now().hour;
    final simbolo = concluido ? '✓' : '○';

    return Text(
      '${_formatarHora(hora)} $simbolo',
      style: TextStyle(
        fontSize: 14,
        color: concluido
            ? _corPrimariaEscura
            : (ehProximo ? _corPrimaria : _corTextoSecundario),
        fontWeight: concluido || ehProximo ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildAreaConteudo() {
    if (_consumosHoje.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _consumosHoje.length,
        separatorBuilder: (context, _) => const Divider(height: 16),
        itemBuilder: (context, index) {
          final item = _consumosHoje[index];
          final horario = (item['horario'] as String).substring(0, 2);
          final ml = item['quantidade_ml'] as int;

          return Row(
            children: [
              const Icon(Icons.water_drop_outlined, color: _corPrimaria, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${horario}h',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _corPrimariaEscura,
                  ),
                ),
              ),
              Text(
                '+${_formatarMl(ml)} ml',
                style: const TextStyle(color: _corTextoSecundario),
              ),
            ],
          );
        },
      ),
    );
  }
}
