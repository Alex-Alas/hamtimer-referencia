import 'package:hamtimer/models/task.dart';
import 'package:hamtimer/models/task_query.dart';
import 'package:hamtimer/repositories/task_repository.dart';

/// Repositorio de tareas en memoria. Con [offline] responde como si las
/// tareas vinieran de SQLite.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository(this.tasks);

  final List<Task> tasks;
  bool offline = false;
  int _nextId = 100;

  @override
  Future<TaskListResult> fetchPage(String userId, TaskQuery query) async {
    final matching = tasks.where(query.matches).toList();
    final start = (query.page - 1) * query.limit;
    final page = matching.skip(start).take(query.limit).toList();
    return TaskListResult(page, fromCache: offline);
  }

  @override
  Future<TaskListResult> fetchAll(String userId) async =>
      TaskListResult(List.of(tasks), fromCache: offline);

  @override
  Future<List<Task>> fetchHistory(String userId, {int limit = 20}) async =>
      tasks.where((t) => t.isCompleted).take(limit).toList();

  @override
  Future<Task> create(String userId, TaskDraft draft) async {
    final task = Task(
      id: '${_nextId++}',
      title: draft.title,
      category: draft.category,
      priority: draft.priority,
      estimatedPomodoros: draft.estimatedPomodoros,
      completedPomodoros: 0,
      startAt: draft.startAt,
      dueAt: draft.dueAt,
      isCompleted: false,
      createdAt: DateTime(2026, 10, 30),
    );
    tasks.add(task);
    return task;
  }

  @override
  Future<Task> update(String userId, Task task) async {
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) tasks[index] = task;
    return task;
  }

  @override
  Future<void> delete(String userId, String taskId) async =>
      tasks.removeWhere((t) => t.id == taskId);
}
