import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/features/tasks/domain/entities/task.dart';
import 'package:hamtimer/features/tasks/domain/entities/task_category.dart';
import 'package:hamtimer/features/tasks/presentation/widgets/new_task/task_form_controller.dart';

import '../fakes/fake_duration_estimator.dart';
import '../fakes/task_factory.dart';

void main() {
  test('estimar con IA pide objetivo y categoría, y aplica la sugerencia', () async {
    final estimator = FakeDurationEstimator(4);
    final history = [buildTask(completed: 4, isCompleted: true)];
    final controller = TaskFormController(
      onSubmit: (TaskDraft draft) async => throw UnimplementedError(),
      estimator: estimator,
      loadHistory: () async => history,
      now: DateTime(2026, 11, 1, 8, 30),
    );

    // Sin categoría todavía no se puede estimar.
    controller.titleController.text = 'Proyecto final';
    expect(await controller.estimateDuration(), isNull);
    expect(controller.estimateError, isNotNull);

    controller.selectCategory(TaskCategory.deepWork);
    final estimate = await controller.estimateDuration();
    expect(estimate?.pomodoros, 4);
    expect(controller.pomodoros, 4);
    expect(estimator.receivedHistory, history);
    // El vencimiento se movió para que quepan 4 × 25 min.
    expect(controller.scheduleError, isNull);
    controller.dispose();
  });
}
