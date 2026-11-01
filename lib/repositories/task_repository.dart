import '../models/task.dart';
import '../models/task_query.dart';

/// Contrato de acceso a las tareas (principio de inversión de dependencias).
///
/// `TaskProvider` solo conoce esta interfaz. Hoy la implementa
/// `CachedTaskRepository` (MockAPI + SQLite) y en las pruebas
/// `FakeTaskRepository`, sin tocar pantallas ni providers.
abstract interface class TaskRepository {
  /// Página filtrada (lo que muestra el dashboard).
  Future<TaskListResult> fetchPage(String userId, TaskQuery query);

  /// Todas las tareas, para el progreso del día, el filtro "Hoy" y la sesión
  /// de Pomodoro.
  Future<TaskListResult> fetchAll(String userId);

  /// Historial de tareas completadas que usa el estimador de Gemini.
  Future<List<Task>> fetchHistory(String userId, {int limit = 20});

  Future<Task> create(String userId, TaskDraft draft);

  Future<Task> update(String userId, Task task);

  /// Borra la tarea. Sin red queda pendiente y se envía al volver la conexión.
  Future<void> delete(String userId, String taskId);
}
