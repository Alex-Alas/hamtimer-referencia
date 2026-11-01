import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/widgets/dashboard/task_card.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../fakes/task_factory.dart';

void main() {
  testWidgets('la tarjeta muestra la tarea y avisa al tocar el check', (tester) async {
    await initializeDateFormatting('es');
    var toggled = 0;
    var deleted = 0;
    final task = buildTask(title: 'Leer guía M3', completed: 1, estimated: 3);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task,
            now: DateTime(2026, 11, 2, 9),
            onToggleCompleted: () => toggled++,
            onDelete: () => deleted++,
          ),
        ),
      ),
    );

    expect(find.text('Leer guía M3'), findsOneWidget);
    expect(find.text('Prioridad media'), findsOneWidget);
    expect(find.text('Hoy 18:00'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check));
    expect(toggled, 1);

    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(deleted, 1);
  });
}
