import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/providers/auth_provider.dart';
import 'package:hamtimer/screens/login_screen.dart';
import 'package:hamtimer/services/analytics_service.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_analytics_service.dart';
import '../fakes/fake_auth_repository.dart';

void main() {
  testWidgets('el login valida los campos antes de llamar a Firebase', (tester) async {
    final repository = FakeAuthRepository();
    final analytics = FakeAnalyticsService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AnalyticsService>.value(value: analytics),
          ChangeNotifierProvider(create: (_) => AuthProvider(repository)),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    expect(analytics.screens, ['login']);

    // Vacío: muestra los errores y no intenta iniciar sesión.
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Escribe tu correo'), findsOneWidget);
    expect(find.text('Escribe tu contraseña'), findsOneWidget);
    expect(repository.signInCalls, isEmpty);

    // Con datos válidos llama al repositorio y registra el evento.
    await tester.enterText(find.byType(TextField).at(0), 'jade@esen.edu.sv');
    await tester.enterText(find.byType(TextField).at(1), 'secreta123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(repository.signInCalls, ['jade@esen.edu.sv']);
    expect(analytics.events, contains('login'));
  });
}
