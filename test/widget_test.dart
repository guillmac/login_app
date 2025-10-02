// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_app/main.dart'; // Asegúrate de que esto apunta a tu main.dart

void main() {
  testWidgets('Smoke test de la app', (WidgetTester tester) async {
    // Construye nuestro widget principal
    await tester.pumpWidget(const LoginApp());

    // Espera un frame para renderizar
    await tester.pumpAndSettle();

    // Verifica que se muestre algo de la pantalla de inicio
    expect(find.text('Club France'), findsOneWidget);

    // Como ejemplo, puedes verificar que el logo exista
    expect(find.byType(Image), findsOneWidget);

    // Si quieres simular interacción con botones, por ejemplo:
    // final loginButton = find.text('Iniciar sesión');
    // expect(loginButton, findsOneWidget);
    // await tester.tap(loginButton);
    // await tester.pumpAndSettle();
  });
}
