import 'package:flutter/material.dart';
import '../dao/usuario_dao.dart';
import '../modelo/usuario.dart';
import '../utilitarios/calculadora_imc.dart';

class TelaConfiguracoes extends StatefulWidget {
  const TelaConfiguracoes({super.key});

  @override
  State<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends State<TelaConfiguracoes> {
  Usuario? usuario;
  final pesoController = TextEditingController();
  final alturaController = TextEditingController();
  bool editando = false;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    final u = await buscarUsuario();
    setState(() {
      usuario = u;
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
    await salvarUsuario(Usuario(
      peso: peso,
      altura: altura,
      imc: resultado.imc,
      metaDiariaMl: resultado.metaDiariaMl,
    ));

    await _carregarUsuario();
    setState(() => editando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (usuario == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seus dados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _linhaDado('Peso', '${usuario!.peso} kg'),
                _linhaDado('Altura', '${usuario!.altura} cm'),
                _linhaDado('IMC', '${usuario!.imc}'),
                _linhaDado('Meta diária',
                    '${usuario!.metaDiariaMl.toStringAsFixed(0)} ml'),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
            const Text('Peso (kg)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: pesoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: 70',
              ),
            ),
            const SizedBox(height: 12),
            const Text('Altura (cm)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: alturaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: 175',
              ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
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

  Widget _linhaDado(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(valor,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }
}
