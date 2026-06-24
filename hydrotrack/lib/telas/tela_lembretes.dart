import 'package:flutter/material.dart';

class TelaLembretes extends StatelessWidget {
  const TelaLembretes({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_outlined,
              size: 64, color: Colors.blue.shade200),
          const SizedBox(height: 16),
          const Text(
            'Lembretes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Será desenvolvido na Semana 3\ncom showTimePicker e Dismissible',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
