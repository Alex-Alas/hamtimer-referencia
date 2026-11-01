import '../../domain/entities/task.dart';
import '../../domain/entities/task_query.dart';

/// Contrato de la fuente remota de tareas (patrón de la clase 22).
///
/// El repositorio programa contra esta interfaz, nunca contra Dio ni MockAPI.
/// Todas las operaciones van filtradas por [userId]: cada usuario solo ve sus
/// tareas. Ante fallas de red lanza `NetworkException`; ante cualquier otro
/// problema, `AppException`.
abstract interface class TaskRemoteDataSource {
  /// GET paginado y filtrado en el servidor.
  Future<List<Task>> fetchPage(String userId, TaskQuery query);

  /// GET de todas las tareas del usuario.
  Future<List<Task>> fetchAll(String userId);

  /// GET de las últimas [limit] tareas completadas (historial para Gemini).
  Future<List<Task>> fetchCompleted(String userId, {required int limit});

  /// POST: registra una tarea y devuelve la versión guardada (con `id`).
  Future<Task> create(String userId, TaskDraft draft);

  /// PUT: reemplaza una tarea existente y devuelve la versión guardada.
  Future<Task> update(String userId, Task task);

  /// DELETE: borra la tarea. Si ya no existe se considera borrada.
  Future<void> delete(String userId, String taskId);
}
