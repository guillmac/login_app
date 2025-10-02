import 'package:flutter/material.dart';

class BeneficiosPage extends StatelessWidget {
  const BeneficiosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beneficios')),
      body: const Center(
        child: Text(
          'Descuentos y convenios del club',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
