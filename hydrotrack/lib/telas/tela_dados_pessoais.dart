import 'package:flutter/material.dart';
import '../utilitarios/calculadora_imc.dart';
import '../modelo/usuario.dart';
import '../dao/usuario_dao.dart';
import 'tela_inicial.dart';

class TelaDadosPessoais extends StatefulWidget {
  const TelaDadosPessoais({super.key});

  @override
  State<TelaDadosPessoais> createState() => _TelaDadosPessoaisState();
}

class _TelaDadosPessoaisState extends State<TelaDadosPessoais> {
  final TextEditingController pesoController = TextEditingController();
  final TextEditingController alturaController = TextEditingController();

  ResultadoCalculo? resultado;

  void calcular() {
    final peso = double.tryParse(pesoController.text.replaceAll(',', '.'));
    final altura = double.tryParse(alturaController.text.replaceAll(',', '.'));

    if (peso == null || altura == null || peso <= 0 || altura <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha peso e altura corretamente')),
      );
      return;
    }

    setState(() {
      resultado = calcularImcEMeta(peso, altura);
    });
  }

  Future<void> confirmar() async {
    if (resultado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calcule o IMC antes de confirmar')),
      );
      return;
    }

    final peso = double.parse(pesoController.text.replaceAll(',', '.'));
    final altura = double.parse(alturaController.text.replaceAll(',', '.'));

    await salvarUsuario(
      Usuario(
        peso: peso,
        altura: altura,
        imc: resultado!.imc,
        metaDiariaMl: resultado!.metaDiariaMl,
      ),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TelaInicial()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seus dados')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
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
            const SizedBox(height: 16),

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

            ElevatedButton(
              onPressed: calcular,
              child: const Text('Calcular IMC'),
            ),
            const SizedBox(height: 16),

            if (resultado != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
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
                    Text(
                      'IMC calculado: ${resultado!.imc} — ${resultado!.classificacao}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
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
                    const Text(
                      'Meta diária',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '${resultado!.metaDiariaMl.toStringAsFixed(0)} ml / dia',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: confirmar,
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
