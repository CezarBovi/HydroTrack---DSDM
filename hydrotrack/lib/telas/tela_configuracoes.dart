import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../dao/usuario_dao.dart';
import '../dao/historico_peso_dao.dart';
import '../modelo/usuario.dart';
import '../modelo/historico_peso.dart';
import '../utilitarios/calculadora_imc.dart';
import '../utilitarios/tema_controller.dart';

class TelaConfiguracoes extends StatefulWidget {
  const TelaConfiguracoes({super.key});

  @override
  State<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends State<TelaConfiguracoes> {
  Usuario? usuario;
  List<HistoricoPeso> historico = [];
  final pesoController = TextEditingController();
  final alturaController = TextEditingController();
  bool editando = false;
  bool carregando = true;
  late final VoidCallback _listenerTema;

  @override
  void initState() {
    super.initState();
    _carregarDados();

    _listenerTema = () {
      if (mounted) setState(() {});
    };
    TemaController.temaMode.addListener(_listenerTema);
  }

  Future<void> _carregarDados() async {
    await migrarUsuarioAtualParaHistorico();
    final u = await buscarUsuario();
    final h = await listarHistoricoPeso();
    setState(() {
      usuario = u;
      historico = h;
      carregando = false;
      if (u != null) {
        pesoController.text = u.peso.toString();
        alturaController.text = u.altura.toString();
      }
    });
  }

  Future<void> _salvarAlteracoes() async {
    final peso = double.tryParse(pesoController.text.replaceAll(',', '.'));
    final altura = double.tryParse(alturaController.text.replaceAll(',', '.'));

    if (peso == null || altura == null || peso <= 0 || altura <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha peso e altura corretamente')),
      );
      return;
    }

    final resultado = calcularImcEMeta(peso, altura);
    await salvarUsuario(
      Usuario(
        peso: peso,
        altura: altura,
        imc: resultado.imc,
        metaDiariaMl: resultado.metaDiariaMl,
      ),
    );

    await _carregarDados();
    setState(() => editando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso!')),
      );
    }
  }

  double? _variacaoPeso() {
    if (historico.length < 2) return null;
    return historico.last.peso - historico.first.peso;
  }

  double? _variacaoImc() {
    if (historico.length < 2) return null;
    return historico.last.imc - historico.first.imc;
  }

  String _formatarData(String data) {
    try {
      final dt = DateTime.parse(data);
      return DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(dt);
    } catch (_) {
      return data;
    }
  }

  String _classificacaoImc(double imc) {
    if (imc < 18.5) return 'Abaixo do peso';
    if (imc < 25) return 'Normal';
    if (imc < 30) return 'Sobrepeso';
    return 'Obesidade';
  }

  Color _corImc(double imc) {
    if (imc < 18.5) return Colors.orange;
    if (imc < 25) return Colors.green;
    if (imc < 30) return Colors.orange.shade700;
    return Colors.red;
  }

  @override
  void dispose() {
    TemaController.temaMode.removeListener(_listenerTema);
    pesoController.dispose();
    alturaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final corPrimaria = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: carregando || usuario == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _construirCabecalho(corPrimaria),
                  const SizedBox(height: 24),
                  _construirResumoVariacao(),
                  const SizedBox(height: 24),
                  _construirSecaoTitulo('Aparência', Icons.palette_outlined),
                  const SizedBox(height: 10),
                  _construirCardTema(),
                  const SizedBox(height: 24),
                  _construirSecaoTitulo('Seus dados', Icons.person_outline),
                  const SizedBox(height: 10),
                  _construirCardDados(),
                  const SizedBox(height: 24),
                  _construirSecaoTitulo(
                    'Histórico de peso',
                    Icons.monitor_weight_outlined,
                  ),
                  const SizedBox(height: 10),
                  if (historico.length >= 2) ...[
                    _construirGraficoPeso(corPrimaria),
                    const SizedBox(height: 16),
                  ],
                  _construirTimelineHistorico(),
                ],
              ),
            ),
    );
  }

  Widget _construirSecaoTitulo(String titulo, IconData icone) {
    return Row(
      children: [
        Icon(icone, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _construirCabecalho(Color corPrimaria) {
    final classificacao = _classificacaoImc(usuario!.imc);
    final corImc = _corImc(usuario!.imc);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [corPrimaria, corPrimaria.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: corPrimaria.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            '${usuario!.peso.toStringAsFixed(1)} kg',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '${usuario!.altura.toStringAsFixed(0)} cm · IMC ${usuario!.imc}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: corImc.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white38),
            ),
            child: Text(
              classificacao,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirResumoVariacao() {
    final varPeso = _variacaoPeso();
    final varImc = _variacaoImc();

    if (varPeso == null) {
      return _cardBase(
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Atualize seus dados para acompanhar ganho ou perda de peso.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final perdeu = varPeso < 0;
    final manteve = varPeso.abs() < 0.1;

    return Row(
      children: [
        Expanded(
          child: _cardResumo(
            icone: manteve
                ? Icons.trending_flat
                : (perdeu ? Icons.trending_down : Icons.trending_up),
            titulo: 'Variação de peso',
            valor: manteve
                ? 'Estável'
                : '${perdeu ? '' : '+'}${varPeso.toStringAsFixed(1)} kg',
            cor: manteve
                ? Colors.blue
                : (perdeu ? Colors.green : Colors.orange),
            subtitulo: manteve
                ? 'Sem mudança'
                : (perdeu ? 'Você emagreceu' : 'Você engordou'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cardResumo(
            icone: Icons.favorite_outline,
            titulo: 'Variação IMC',
            valor: '${varImc! >= 0 ? '+' : ''}${varImc.toStringAsFixed(1)}',
            cor: varImc.abs() < 0.5 ? Colors.blue : Colors.purple,
            subtitulo: 'Desde o 1º registro',
          ),
        ),
      ],
    );
  }

  Widget _cardResumo({
    required IconData icone,
    required String titulo,
    required String valor,
    required String subtitulo,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 22),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          Text(
            subtitulo,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardBase({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _construirCardTema() {
    final temaEscuro = TemaController.temaMode.value == ThemeMode.dark;

    return _cardBase(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Modo escuro',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          temaEscuro ? 'Tema escuro ativado' : 'Tema claro ativado',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        secondary: Icon(
          temaEscuro ? Icons.dark_mode : Icons.light_mode,
          color: Theme.of(context).colorScheme.primary,
        ),
        value: temaEscuro,
        onChanged: (v) async {
          await TemaController.setModo(
            v ? ThemeMode.dark : ThemeMode.light,
          );
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Widget _construirCardDados() {
    return _cardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _linhaDado('Peso atual', '${usuario!.peso} kg'),
          _linhaDado('Altura', '${usuario!.altura} cm'),
          _linhaDado('IMC', '${usuario!.imc}'),
          _linhaDado(
            'Meta diária',
            '${usuario!.metaDiariaMl.toStringAsFixed(0)} ml',
          ),
          const SizedBox(height: 16),
          if (!editando)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => editando = true),
                icon: const Icon(Icons.edit),
                label: const Text('Atualizar meus dados'),
              ),
            )
          else ...[
            const Text(
              'Peso (kg)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: pesoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Ex: 70'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Altura (cm)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: alturaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Ex: 175'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => editando = false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _salvarAlteracoes,
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirGraficoPeso(Color corPrimaria) {
    final spots = historico.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.peso);
    }).toList();

    final minPeso = historico.map((h) => h.peso).reduce((a, b) => a < b ? a : b);
    final maxPeso = historico.map((h) => h.peso).reduce((a, b) => a > b ? a : b);
    final margem = ((maxPeso - minPeso) * 0.2).clamp(2.0, 10.0);

    return _cardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evolução do peso',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: minPeso - margem,
                maxY: maxPeso + margem,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= historico.length) {
                          return const SizedBox.shrink();
                        }
                        try {
                          final dt = DateTime.parse(historico[i].dataRegistro);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('dd/MM').format(dt),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        } catch (_) {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: corPrimaria,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: corPrimaria,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: corPrimaria.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTimelineHistorico() {
    if (historico.isEmpty) {
      return _cardBase(
        child: const Text(
          'Nenhum registro ainda. Salve seus dados para começar o histórico.',
          style: TextStyle(fontSize: 13),
        ),
      );
    }

    return Column(
      children: List.generate(historico.length, (index) {
        final registro = historico[index];
        final anterior = index > 0 ? historico[index - 1] : null;
        final diff = anterior != null ? registro.peso - anterior.peso : null;

        String? badgeTexto;
        Color? badgeCor;
        if (diff != null) {
          if (diff.abs() < 0.1) {
            badgeTexto = 'Estável';
            badgeCor = Colors.blue;
          } else if (diff > 0) {
            badgeTexto = '+${diff.toStringAsFixed(1)} kg';
            badgeCor = Colors.orange;
          } else {
            badgeTexto = '${diff.toStringAsFixed(1)} kg';
            badgeCor = Colors.green;
          }
        }

        final isUltimo = index == historico.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isUltimo
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isUltimo)
                  Container(
                    width: 2,
                    height: 72,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUltimo
                        ? Theme.of(context).colorScheme.primary.withValues(
                            alpha: 0.4,
                          )
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                  boxShadow: isUltimo
                      ? [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${registro.peso.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (badgeTexto != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeCor!.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badgeTexto,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeCor,
                              ),
                            ),
                          )
                        else if (index == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Início',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'IMC ${registro.imc} · ${_classificacaoImc(registro.imc)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _corImc(registro.imc),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatarData(registro.dataRegistro),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).reversed.toList(),
    );
  }

  Widget _linhaDado(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
