import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Tareas completadas del usuario: el historial que usa el estimador de duración.
class GetTaskHistoryUseCase {
  const GetTaskHistoryUseCase(this._repository);

  final TaskRepository _repository;

  Future<List<Task>> call(String userId, {int limit = 20}) =>
      _repository.fetchHistory(userId, limit: limit);
}
