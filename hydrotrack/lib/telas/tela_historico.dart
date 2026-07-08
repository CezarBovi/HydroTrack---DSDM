import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../dao/consumo_dao.dart';
import '../dao/usuario_dao.dart';

class TelaHistorico extends StatefulWidget {
  const TelaHistorico({super.key});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  List<Map<String, dynamic>> historico = [];
  double metaDiaria = 0;
  bool carregando = true;
  int barraSelecionada = -1;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    final usuario = await buscarUsuario();
    final dados = await buscarUltimosDias(7);
    setState(() {
      metaDiaria = usuario?.metaDiariaMl ?? 2000;
      historico = dados.reversed.toList();
      carregando = false;
    });
  }

  String _formatarData(String data) {
    try {
      final dt = DateTime.parse(data);
      return DateFormat('dd/MM', 'pt_BR').format(dt);
    } catch (_) {
      return data;
    }
  }

  String _diaDaSemana(String data) {
    try {
      final dt = DateTime.parse(data);
      return DateFormat('E', 'pt_BR').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _calcularMedia() {
    if (historico.isEmpty) return '0';
    final soma = historico.fold<int>(0, (s, h) => s + (h['total'] as int));
    return (soma / historico.length).toStringAsFixed(0);
  }

  double _calcularMaxY() {
    final maiorTotal = historico
        .map((h) => (h['total'] as int).toDouble())
        .fold<double>(
          0,
          (anterior, atual) => atual > anterior ? atual : anterior,
        );
    final referencia = maiorTotal > metaDiaria ? maiorTotal : metaDiaria;
    return referencia * 1.2;
  }

  // Monta as barras do fl_chart — Widget Novo #3
  List<BarChartGroupData> _montarBarras({
    required double maxY,
    required Color backDrawColor,
  }) {
    return List.generate(historico.length, (index) {
      final total = (historico[index]['total'] as int).toDouble();
      final bateu = total >= metaDiaria;
      final selecionado = barraSelecionada == index;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: total,
            width: selecionado ? 22 : 16,
            borderRadius: BorderRadius.circular(6),
            color: bateu
                ? (selecionado ? Colors.green : Colors.green.shade400)
                : (selecionado ? Colors.blue : Colors.blue.shade300),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: backDrawColor,
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (historico.isEmpty) {
      final corTextoSecundario = Theme.of(context).colorScheme.onSurfaceVariant;
      return Center(
        child: Text(
          'Nenhum registro ainda.\nComece bebendo água! 💧',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: corTextoSecundario),
        ),
      );
    }

    final corTextoSecundario = Theme.of(context).colorScheme.onSurfaceVariant;
    final corLinhaGrade = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.35);
    final corFundoProgresso = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.35);

    final metasBatidas = historico
        .where((h) => (h['total'] as int) >= metaDiaria)
        .length;
    final maxY = _calcularMaxY();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card resumo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _cardResumo(
                  '$metasBatidas/${historico.length}',
                  'Metas\nbatidas',
                  Colors.green,
                ),
                _cardResumo(
                  '${historico.length - metasBatidas}',
                  'Não\nbatidas',
                  Colors.red,
                ),
                _cardResumo(
                  '${_calcularMedia()} ml',
                  'Média\n/dia',
                  Colors.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Últimos 7 dias',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),

          // Legenda do gráfico
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Meta batida',
                style: TextStyle(fontSize: 11, color: corTextoSecundario),
              ),
              const SizedBox(width: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Abaixo da meta',
                style: TextStyle(fontSize: 11, color: corTextoSecundario),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gráfico de barras — fl_chart BarChart — Widget Novo #3
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (response == null ||
                            response.spot == null ||
                            event is FlPointerExitEvent) {
                          barraSelecionada = -1;
                        } else {
                          barraSelecionada =
                              response.spot!.touchedBarGroupIndex;
                        }
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = historico[group.x];
                        final total = data['total'] as int;
                        final bateu = total >= metaDiaria;
                        return BarTooltipItem(
                          '${_diaDaSemana(data['data'])}\n$total ml\n${bateu ? '✓ Meta batida' : '✗ Abaixo da meta'}',
                          TextStyle(
                            color: bateu ? Colors.green : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('');
                          return Text(
                            '${(value / 1000).toStringAsFixed(1)}L',
                            style: TextStyle(
                              fontSize: 10,
                              color: corTextoSecundario,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= historico.length) {
                            return const Text('');
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _diaDaSemana(historico[index]['data']),
                              style: TextStyle(
                                fontSize: 11,
                                color: corTextoSecundario,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: metaDiaria / 4,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: corLinhaGrade, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _montarBarras(
                    maxY: maxY,
                    backDrawColor: corFundoProgresso,
                  ),
                  // Linha horizontal da meta
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: metaDiaria,
                        color: Colors.orange.shade300,
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          labelResolver: (_) =>
                              'Meta: ${metaDiaria.toStringAsFixed(0)} ml',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Lista detalhada por dia
          const Text(
            'Detalhes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...historico.map((h) {
            final total = h['total'] as int;
            final progresso = (total / metaDiaria).clamp(0.0, 1.0);
            final bateu = total >= metaDiaria;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      _diaDaSemana(h['data']),
                      style: TextStyle(fontSize: 11, color: corTextoSecundario),
                    ),
                  ),
                  SizedBox(
                    width: 42,
                    child: Text(
                      _formatarData(h['data']),
                      style: TextStyle(fontSize: 11, color: corTextoSecundario),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progresso,
                        minHeight: 16,
                        backgroundColor: corFundoProgresso,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          bateu ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$total ml',
                    style: TextStyle(
                      fontSize: 11,
                      color: bateu ? Colors.green : corTextoSecundario,
                      fontWeight: bateu ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (bateu)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 14,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _cardResumo(String valor, String label, Color cor) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
