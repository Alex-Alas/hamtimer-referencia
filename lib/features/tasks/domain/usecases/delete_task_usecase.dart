import '../repositories/task_repository.dart';

/// Borra una tarea. Sin red queda pendiente y se borra al volver la conexión.
class DeleteTaskUseCase {
  const DeleteTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call(String userId, String taskId) => _repository.delete(userId, taskId);
}
