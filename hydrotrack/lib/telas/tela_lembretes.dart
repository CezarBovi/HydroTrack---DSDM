import 'package:flutter/material.dart';
import '../dao/lembrete_dao.dart';
import '../modelo/lembrete.dart';
import '../utilitarios/servico_notificacao.dart';

class TelaLembretes extends StatefulWidget {
  const TelaLembretes({super.key});

  @override
  State<TelaLembretes> createState() => _TelaLembretesState();
}

class _TelaLembretesState extends State<TelaLembretes> {
  List<Map<String, dynamic>> lembretes = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarLembretes();
  }

  Future<void> _carregarLembretes() async {
    final dados = await listarLembretes();
    setState(() {
      lembretes = dados;
      carregando = false;
    });
  }

  Future<void> _deletarLembrete(int id) async {
    await cancelarLembrete(id); // cancela notificação
    await deletarLembrete(id); // deleta do banco
    await _carregarLembretes();
  }

  Future<void> _alternarStatus(Map<String, dynamic> lembrete) async {
    final id = lembrete['id'] as int;
    final statusAtual = lembrete['ativo'] as int;
    final novoStatus = statusAtual == 1 ? 0 : 1;
    await atualizarStatusLembrete(id, novoStatus);

    if (novoStatus == 1) {
      await agendarLembrete(
        id: id,
        titulo: lembrete['titulo'],
        horario: lembrete['horario'],
        intervaloHoras: lembrete['intervalo_horas'],
      );
    } else {
      await cancelarLembrete(id);
    }

    await _carregarLembretes();
  }

  Future<void> _abrirFormulario({Map<String, dynamic>? lembrete}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          FormularioLembrete(lembrete: lembrete, onSalvar: _carregarLembretes),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: lembretes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.blue.shade200,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum lembrete ainda.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toque no + para adicionar',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lembretes.length,
              itemBuilder: (context, index) {
                final l = lembretes[index];
                final ativo = l['ativo'] == 1;

                // Dismissible — Widget Novo #4
                return Dismissible(
                  key: Key('lembrete_${l['id']}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, color: Colors.white),
                        Text(
                          'Deletar',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Deletar lembrete'),
                        content: Text('Deseja deletar "${l['titulo']}"?'),
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
                            child: const Text('Deletar'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => _deletarLembrete(l['id']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ativo
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: ativo
                            ? Colors.blue.shade50
                            : Colors.grey.shade100,
                        child: Icon(
                          Icons.notifications,
                          color: ativo ? Colors.blue : Colors.grey,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        l['titulo'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ativo ? Colors.black : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        '${l['horario']} · ${_descreverIntervalo(l['intervalo_horas'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: ativo ? Colors.grey : Colors.grey.shade400,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: ativo
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: ativo
                                    ? Colors.green.shade200
                                    : Colors.orange.shade200,
                              ),
                            ),
                            child: Text(
                              ativo ? 'Ativo' : 'Pausado',
                              style: TextStyle(
                                fontSize: 11,
                                color: ativo ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: ativo,
                            onChanged: (_) => _alternarStatus(l),
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _descreverIntervalo(int horas) {
    switch (horas) {
      case 0:
        return 'Uma vez ao dia';
      case 1:
        return 'A cada 1 hora';
      case 4:
        return 'A cada 4 horas';
      case 8:
        return 'A cada 8 horas';
      case 12:
        return 'A cada 12 horas';
      default:
        return 'A cada $horas horas';
    }
  }
}

// Formulário de criação de lembrete
class FormularioLembrete extends StatefulWidget {
  final Map<String, dynamic>? lembrete;
  final VoidCallback onSalvar;

  const FormularioLembrete({super.key, this.lembrete, required this.onSalvar});

  @override
  State<FormularioLembrete> createState() => _FormularioLembreteState();
}

class _FormularioLembreteState extends State<FormularioLembrete> {
  final tituloController = TextEditingController();
  TimeOfDay horarioSelecionado = TimeOfDay.now();
  int intervaloSelecionado = 0;

  final List<Map<String, dynamic>> intervalos = [
    {'label': 'Uma vez', 'valor': 0},
    {'label': '1 em 1h', 'valor': 1},
    {'label': '4 em 4h', 'valor': 4},
    {'label': '8 em 8h', 'valor': 8},
    {'label': '12 em 12h', 'valor': 12},
  ];

  final List<String> diasSemana = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];
  List<bool> diasSelecionados = [true, true, true, true, true, false, false];

  @override
  void initState() {
    super.initState();
    if (widget.lembrete != null) {
      final l = widget.lembrete!;
      tituloController.text = l['titulo'];
      intervaloSelecionado = l['intervalo_horas'];
      final partes = l['horario'].split(':');
      horarioSelecionado = TimeOfDay(
        hour: int.parse(partes[0]),
        minute: int.parse(partes[1]),
      );
    }
  }

  // showTimePicker — Widget Novo #5
  Future<void> _selecionarHorario() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: horarioSelecionado,
      helpText: 'Selecione o horário',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => horarioSelecionado = picked);
    }
  }

  String _formatarHorario(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _montarDiasSemana() {
    List<String> selecionados = [];
    for (int i = 0; i < diasSelecionados.length; i++) {
      if (diasSelecionados[i]) selecionados.add('${i + 1}');
    }
    return selecionados.isEmpty ? '1,2,3,4,5' : selecionados.join(',');
  }

  Future<void> _salvar() async {
    if (tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um título para o lembrete')),
      );
      return;
    }

    // Salva no banco
    final id = await inserirLembrete(
      Lembrete(
        titulo: tituloController.text.trim(),
        horario: _formatarHorario(horarioSelecionado),
        intervaloHoras: intervaloSelecionado,
        diasSemana: _montarDiasSemana(),
        ativo: 1,
      ),
    );

    // Agenda notificação real no celular
    await agendarLembrete(
      id: id,
      titulo: tituloController.text.trim(),
      horario: _formatarHorario(horarioSelecionado),
      intervaloHoras: intervaloSelecionado,
    );

    widget.onSalvar();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Novo lembrete',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Título
              const Text(
                'Título',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: tituloController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Tomar remédio',
                ),
              ),
              const SizedBox(height: 16),

              // Horário com showTimePicker — Widget Novo #5
              const Text(
                'Horário',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _selecionarHorario,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatarHorario(horarioSelecionado),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.access_time, color: Colors.blue),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Intervalo de repetição
              const Text(
                'Repetir',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: intervalos.map((i) {
                  final selecionado = intervaloSelecionado == i['valor'];
                  return ChoiceChip(
                    label: Text(i['label']),
                    selected: selecionado,
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: selecionado ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    onSelected: (_) =>
                        setState(() => intervaloSelecionado = i['valor']),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Dias da semana
              const Text(
                'Dias da semana',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: List.generate(diasSemana.length, (index) {
                  final selecionado = diasSelecionados[index];
                  return GestureDetector(
                    onTap: () => setState(
                      () => diasSelecionados[index] = !diasSelecionados[index],
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selecionado ? Colors.blue : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          diasSemana[index].substring(0, 1),
                          style: TextStyle(
                            color: selecionado ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Salvar lembrete',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
