import '../entities/task_query.dart';
import '../repositories/task_repository.dart';

/// Una página filtrada de tareas: lo que muestra el dashboard.
class GetTaskPageUseCase {
  const GetTaskPageUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskListResult> call(String userId, TaskQuery query) =>
      _repository.fetchPage(userId, query);
}
