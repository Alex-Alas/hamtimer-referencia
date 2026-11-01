import '../entities/task_query.dart';
import '../repositories/task_repository.dart';

/// Todas las tareas del usuario (progreso del día, filtro "Hoy" y la sesión de Pomodoro).
class GetTasksUseCase {
  const GetTasksUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskListResult> call(String userId) => _repository.fetchAll(userId);
}
