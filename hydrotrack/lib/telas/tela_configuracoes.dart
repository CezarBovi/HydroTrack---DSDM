import 'package:flutter/material.dart';
import '../dao/usuario_dao.dart';
import '../modelo/usuario.dart';
import '../utilitarios/calculadora_imc.dart';
import '../utilitarios/tema_controller.dart';

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
  late final VoidCallback _listenerTema;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();

    _listenerTema = () {
      if (mounted) setState(() {});
    };
    TemaController.temaMode.addListener(_listenerTema);
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
    await salvarUsuario(
      Usuario(
        peso: peso,
        altura: altura,
        imc: resultado.imc,
        metaDiariaMl: resultado.metaDiariaMl,
      ),
    );

    await _carregarUsuario();
    setState(() => editando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso!')),
      );
    }
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
    if (usuario == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final temaEscuro = TemaController.temaMode.value == ThemeMode.dark;
    final corFundoCard = Theme.of(context).colorScheme.surface;
    final corOutline = Theme.of(context).colorScheme.outlineVariant;

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

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Modo escuro'),
            value: temaEscuro,
            onChanged: (v) async {
              await TemaController.setModo(
                v ? ThemeMode.dark : ThemeMode.light,
              );
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: corFundoCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: corOutline),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _linhaDado('Peso', '${usuario!.peso} kg'),
                _linhaDado('Altura', '${usuario!.altura} cm'),
                _linhaDado('IMC', '${usuario!.imc}'),
                _linhaDado(
                  'Meta diária',
                  '${usuario!.metaDiariaMl.toStringAsFixed(0)} ml',
                ),
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

  Widget _linhaDado(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
