import 'package:flutter/material.dart';
import 'pages/welcome_page.dart'; // WelcomePage original

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
        fontFamily: 'Montserrat', // Agregar la fuente si es necesaria
      ),
      home: const WelcomePage(), // WelcomePage ORIGINAL
    );
  }
}