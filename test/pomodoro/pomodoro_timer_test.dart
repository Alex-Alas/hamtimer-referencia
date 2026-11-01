import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/features/pomodoro/presentation/widgets/pomodoro_timer.dart';

void main() {
  testWidgets('el dial muestra el tiempo restante en mm:ss y la etapa', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PomodoroTimer(
            remaining: Duration(minutes: 24, seconds: 59, milliseconds: 300),
            progress: 0.1,
            caption: 'Enfoque',
          ),
        ),
      ),
    );

    // Redondea hacia arriba: nunca muestra 00:00 antes de terminar.
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Enfoque'), findsOneWidget);
  });
}
