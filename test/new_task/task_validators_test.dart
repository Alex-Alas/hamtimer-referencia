import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/features/tasks/presentation/validators/task_validators.dart';

void main() {
  test('el horario debe terminar después de empezar y alcanzar para los Pomodoros', () {
    final start = DateTime(2026, 11, 1, 9);

    expect(
      TaskValidators.schedule(startAt: start, dueAt: start, estimatedPomodoros: 1),
      'El vencimiento debe ser posterior al inicio',
    );
    // 3 Pomodoros = 75 min, pero solo hay 60.
    expect(
      TaskValidators.schedule(
        startAt: start,
        dueAt: start.add(const Duration(hours: 1)),
        estimatedPomodoros: 3,
      ),
      contains('No alcanza el tiempo'),
    );
    expect(
      TaskValidators.schedule(
        startAt: start,
        dueAt: start.add(const Duration(hours: 2)),
        estimatedPomodoros: 3,
      ),
      isNull,
    );
    expect(TaskValidators.title('ab'), 'Debe tener al menos 3 caracteres');
  });
}
