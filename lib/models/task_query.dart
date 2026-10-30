import 'task.dart';
import 'task_category.dart';

/// Criterios con los que se pide una página de tareas.
class TaskQuery {
  const TaskQuery({required this.page, required this.limit, this.category, this.isCompleted});

  final int page;
  final int limit;
  final TaskCategory? category;
  final bool? isCompleted;

  /// Aplica estos criterios a una lista local (cuando se lee del caché).
  bool matches(Task task) =>
      (category == null || task.category == category) &&
      (isCompleted == null || task.isCompleted == isCompleted);
}

/// Resultado de una lectura de tareas.
///
/// [fromCache] es `true` cuando no hubo red y la lista viene de SQLite, y
/// [pendingSync] cuenta los cambios hechos sin conexión que aún no llegan a
/// MockAPI. El dashboard usa ambos para el aviso "sin conexión".
class TaskListResult {
  const TaskListResult(this.tasks, {this.fromCache = false, this.pendingSync = 0});

  final List<Task> tasks;
  final bool fromCache;
  final int pendingSync;
}
