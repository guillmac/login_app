import 'package:flutter/material.dart';

class MembresiaPage extends StatelessWidget {
  const MembresiaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Membresía')),
      body: const Center(
        child: Text(
          'Estado de membresía, pagos y vencimientos',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
