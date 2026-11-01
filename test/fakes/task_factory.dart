import 'package:hamtimer/features/tasks/domain/entities/task.dart';
import 'package:hamtimer/features/tasks/domain/entities/task_category.dart';
import 'package:hamtimer/features/tasks/domain/entities/task_priority.dart';

/// Crea tareas de prueba con valores por defecto razonables.
Task buildTask({
  String id = '1',
  String title = 'Estudiar Provider',
  TaskCategory category = TaskCategory.study,
  int estimated = 2,
  int completed = 0,
  bool isCompleted = false,
  DateTime? dueAt,
}) {
  final due = dueAt ?? DateTime(2026, 11, 2, 18);
  return Task(
    id: id,
    title: title,
    category: category,
    priority: TaskPriority.medium,
    estimatedPomodoros: estimated,
    completedPomodoros: completed,
    startAt: due.subtract(const Duration(hours: 2)),
    dueAt: due,
    isCompleted: isCompleted,
    createdAt: DateTime(2026, 10, 30),
  );
}
