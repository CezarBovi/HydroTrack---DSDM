import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dao/usuario_dao.dart';
import '../dao/consumo_dao.dart';
import '../modelo/usuario.dart';
import '../modelo/consumo.dart';
import 'tela_historico.dart';
import 'tela_lembretes.dart';
import 'tela_configuracoes.dart';
import '../utilitarios/servico_notificacao.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  // BottomNavigationBar — Widget Novo #1
  int _indiceAbaAtiva = 0;

  Usuario? usuario;
  int consumidoHoje = 0;
  bool botaoClicado = false;
  List<Map<String, dynamic>> registrosDeHoje = [];
  int quantidadeSelecionadaMl = 250;
  final List<int> opcoesQuantidadeMl = [200, 250, 300, 450, 500, 750, 1000];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final u = await buscarUsuario();
    final dataHoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final total = await totalConsumidoNoDia(dataHoje);
    final registros = await buscarConsumoPorData(dataHoje);

    setState(() {
      usuario = u;
      consumidoHoje = total;
      registrosDeHoje = registros;
    });
  }

  Future<void> _registrarConsumo() async {
    final dataHoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final horarioAtual = DateFormat('HH:00').format(DateTime.now());

    await registrarConsumo(
      Consumo(
        data: dataHoje,
        horario: horarioAtual,
        quantidadeMl: quantidadeSelecionadaMl,
      ),
    );

    // Reagenda a notificação de água para 1 hora a partir de agora
    await reagendarAposConsumo();

    setState(() => botaoClicado = true);
    await _carregarDados();

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => botaoClicado = false);
  }

  Future<void> _deletarRegistro(int id) async {
    await deletarConsumo(id);
    await reagendarAposConsumo();
    await _carregarDados();
  }

  double _calcularProgresso() {
    if (usuario == null || usuario!.metaDiariaMl == 0) return 0;
    return (consumidoHoje / usuario!.metaDiariaMl).clamp(0.0, 1.0);
  }

  String _formatarData() {
    return DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(DateTime.now());
  }

  Color _corProgresso() {
    final p = _calcularProgresso();
    if (p >= 1.0) return Colors.green;
    if (p >= 0.5) return Colors.blue;
    return Colors.orange;
  }

  Widget _construirHome() {
    final corCard = Theme.of(context).colorScheme.surface;
    final corOutline = Theme.of(context).colorScheme.outlineVariant;
    final corTextoSecundario = Theme.of(context).colorScheme.onSurfaceVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _formatarData(),
            style: TextStyle(fontSize: 13, color: corTextoSecundario),
          ),
          const SizedBox(height: 20),

          // Card principal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: corCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: corOutline),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '$consumidoHoje ml',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: _corProgresso(),
                  ),
                ),
                Text(
                  'de ${usuario!.metaDiariaMl.toStringAsFixed(0)} ml — ${(_calcularProgresso() * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 14, color: corTextoSecundario),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _calcularProgresso(),
                    minHeight: 12,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.18),
                    valueColor: AlwaysStoppedAnimation<Color>(_corProgresso()),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final p = _calcularProgresso();
                    final meta = usuario!.metaDiariaMl;
                    if (p < 0.65) return const SizedBox.shrink();

                    final faltamMl = (meta - consumidoHoje)
                        .clamp(0, meta)
                        .round();
                    final excedenteMl = (consumidoHoje - meta).round();

                    String titulo;
                    String detalhe;
                    Color cor;

                    if (p < 0.8) {
                      titulo = 'Só mais um pouquinho!';
                      detalhe = 'Faltam $faltamMl ml';
                      cor = Colors.blue;
                    } else if (p < 1.0) {
                      titulo = 'Quase lá!';
                      detalhe =
                          'Faltam ${faltamMl.clamp(0, meta.round()).toString()} ml';
                      cor = Colors.orange;
                    } else if (p < 1.2) {
                      titulo = 'Meta batida! Parabéns!';
                      detalhe = 'Você já fez +$excedenteMl ml';
                      cor = Colors.green;
                    } else {
                      titulo = 'Passou da meta! Mandou muito bem!';
                      detalhe = 'Hoje você fez +$excedenteMl ml';
                      cor = Colors.green.shade700;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            titulo,
                            style: TextStyle(
                              color: cor,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            detalhe,
                            style: TextStyle(
                              color: cor.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Botão garrafa — AnimatedContainer — Widget Novo #2
          GestureDetector(
            onTap: botaoClicado ? null : _registrarConsumo,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: botaoClicado ? 130 : 110,
              height: botaoClicado ? 150 : 130,
              decoration: BoxDecoration(
                color: botaoClicado ? Colors.green : Colors.blue,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: botaoClicado
                        ? Colors.green.withValues(alpha: 0.5)
                        : Colors.blue.withValues(alpha: 0.3),
                    blurRadius: botaoClicado ? 24 : 10,
                    spreadRadius: botaoClicado ? 4 : 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    botaoClicado ? Icons.check_circle : Icons.local_drink,
                    size: botaoClicado ? 52 : 44,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    botaoClicado
                        ? 'Registrado!\n+$quantidadeSelecionadaMl ml'
                        : 'Já bebi\nágua! 💧',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: botaoClicado ? 13 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: corCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: corOutline),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Quantidade por registro',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: opcoesQuantidadeMl.map((ml) {
                    final selecionado = quantidadeSelecionadaMl == ml;
                    return ChoiceChip(
                      label: Text('$ml ml'),
                      selected: selecionado,
                      showCheckmark: false,
                      selectedColor: Colors.blue,
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(
                        color: selecionado
                            ? Colors.white
                            : Colors.blue.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: selecionado
                              ? Colors.blue
                              : Colors.blue.shade100,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() {
                          quantidadeSelecionadaMl = ml;
                          botaoClicado = false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Registros do dia
          if (registrosDeHoje.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Registros de hoje',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: corCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: corOutline),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: registrosDeHoje.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: Colors.blue.shade50),
                itemBuilder: (context, index) {
                  final r = registrosDeHoje[index];
                  return Dismissible(
                    key: Key('consumo_${r['id']}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, color: Colors.white),
                          Text(
                            'Apagar',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Apagar registro'),
                          content: Text(
                            'Deseja apagar ${r['quantidade_ml']} ml?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Apagar'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) => _deletarRegistro(r['id'] as int),
                    child: ListTile(
                      leading: const Icon(Icons.water_drop, color: Colors.blue),
                      title: Text('${r['quantidade_ml']} ml'),
                      trailing: Text(
                        r['horario'],
                        style: TextStyle(color: corTextoSecundario),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: corCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade100),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                '💡 Toque na garrafa sempre que beber água!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _telaAtiva() {
    switch (_indiceAbaAtiva) {
      case 0:
        return _construirHome();
      case 1:
        return const TelaHistorico();
      case 2:
        return const TelaLembretes();
      default:
        return _construirHome();
    }
  }

  String _tituloDaAba() {
    switch (_indiceAbaAtiva) {
      case 0:
        return 'Hoje';
      case 1:
        return 'Histórico';
      case 2:
        return 'Lembretes';
      default:
        return 'HydroTrack';
    }
  }

  Future<void> _abrirConfiguracoes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TelaConfiguracoes()),
    );
    _carregarDados();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_tituloDaAba()),
        actions: [
          IconButton(
            onPressed: _abrirConfiguracoes,
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: usuario == null
          ? const Center(child: CircularProgressIndicator())
          : _telaAtiva(),

      // BottomNavigationBar — Widget Novo #1
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAbaAtiva,
        onTap: (indice) {
          setState(() => _indiceAbaAtiva = indice);
          if (indice == 0) _carregarDados();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Lembretes',
          ),
        ],
      ),
    );
  }
}
