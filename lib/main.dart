import 'package:flutter/material.dart';
import 'pages/welcome_page.dart'; // Importa WelcomePage

void main() {
  runApp(const LoginApp());
}

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Club France',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Montserrat', // Agregué esta línea para consistencia
      ),
      home: const WelcomePage(), // Cambiado de LoginPage a WelcomePage
    );
  }
}
