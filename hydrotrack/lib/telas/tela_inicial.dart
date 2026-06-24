import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dao/usuario_dao.dart';
import '../dao/consumo_dao.dart';
import '../modelo/usuario.dart';
import '../modelo/consumo.dart';
import 'tela_historico.dart';
import 'tela_lembretes.dart';
import 'tela_configuracoes.dart';

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

    await registrarConsumo(Consumo(
      data: dataHoje,
      horario: horarioAtual,
      quantidadeMl: 250,
    ));

    setState(() => botaoClicado = true);
    await _carregarDados();

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => botaoClicado = false);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _formatarData(),
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Card principal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
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
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _calcularProgresso(),
                    minHeight: 12,
                    backgroundColor: Colors.blue.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(_corProgresso()),
                  ),
                ),
                if (_calcularProgresso() >= 1.0) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '🎉 Meta atingida! Parabéns!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
                        ? Colors.green.withOpacity(0.5)
                        : Colors.blue.withOpacity(0.3),
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
                    botaoClicado ? 'Registrado!\n+250 ml' : 'Já bebi\nágua! 💧',
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: registrosDeHoje.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.blue.shade50),
                itemBuilder: (context, index) {
                  final r = registrosDeHoje[index];
                  return ListTile(
                    leading: const Icon(Icons.water_drop, color: Colors.blue),
                    title: Text('${r['quantidade_ml']} ml'),
                    trailing: Text(
                      r['horario'],
                      style: const TextStyle(color: Colors.grey),
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
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade100),
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
      case 3:
        return const TelaConfiguracoes();
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
      case 3:
        return 'Configurações';
      default:
        return 'HydroTrack';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tituloDaAba()),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: usuario == null
          ? const Center(child: CircularProgressIndicator())
          : _telaAtiva(),

      // BottomNavigationBar — Widget Novo #1
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAbaAtiva,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (indice) {
          setState(() => _indiceAbaAtiva = indice);
          if (indice == 0) _carregarDados();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Lembretes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Config.',
          ),
        ],
      ),
    );
  }
}
