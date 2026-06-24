import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (historico.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum registro ainda.\nComece bebendo água! 💧',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final metasBatidas =
        historico.where((h) => (h['total'] as int) >= metaDiaria).length;

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
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _cardResumo('$metasBatidas/${historico.length}',
                    'Metas batidas', Colors.green),
                _cardResumo('${historico.length - metasBatidas}', 'Não batidas',
                    Colors.red),
                _cardResumo('${_calcularMedia()} ml', 'Média/dia', Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Últimos 7 dias',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          ...historico.map((h) {
            final total = h['total'] as int;
            final progresso = (total / metaDiaria).clamp(0.0, 1.0);
            final bateu = total >= metaDiaria;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      _diaDaSemana(h['data']),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  SizedBox(
                    width: 42,
                    child: Text(
                      _formatarData(h['data']),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progresso,
                        minHeight: 20,
                        backgroundColor: Colors.grey.shade200,
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
                      color: bateu ? Colors.green : Colors.grey,
                      fontWeight: bateu ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (bateu)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.check_circle,
                          color: Colors.green, size: 14),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          Center(
            child: Text(
              'Gráfico fl_chart será adicionado na Semana 3',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardResumo(String valor, String label, Color cor) {
    return Column(
      children: [
        Text(valor,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
