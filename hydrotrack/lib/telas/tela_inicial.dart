import 'package:flutter/material.dart';

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hoje')),
      body: const Center(
        child: Text('Tela inicial — será desenvolvida na Semana 2'),
      ),
    );
  }
}