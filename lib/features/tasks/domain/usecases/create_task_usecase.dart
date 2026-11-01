import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Crea una tarea. Sin red queda guardada en el teléfono y se envía al volver la conexión.
class CreateTaskUseCase {
  const CreateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<Task> call(String userId, TaskDraft draft) => _repository.create(userId, draft);
}
