import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Guarda los cambios de una tarea (completarla, sumar un Pomodoro).
class UpdateTaskUseCase {
  const UpdateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<Task> call(String userId, Task task) => _repository.update(userId, task);
}
