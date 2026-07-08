import 'package:flutter/material.dart';
import 'tela_dados_pessoais.dart';

class TelaBoasVindas extends StatelessWidget {
  const TelaBoasVindas({super.key});

  @override
  Widget build(BuildContext context) {
    final corTextoSecundario = Theme.of(context).colorScheme.onSurfaceVariant;
    final corPrimaria = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('HydroTrack')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: corPrimaria.withValues(alpha: 0.2)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.water_drop, size: 68, color: corPrimaria),
            ),
            const SizedBox(height: 32),
            const Text(
              'Bem-vindo ao HydroTrack',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Vamos calcular sua hidratação ideal\ncom base no seu peso e altura.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: corTextoSecundario),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TelaDadosPessoais(),
                    ),
                  );
                },
                child: const Text('Começar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
