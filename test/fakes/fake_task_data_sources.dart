import 'package:hamtimer/features/tasks/data/datasource/task_local_data_source.dart';
import 'package:hamtimer/features/tasks/data/datasource/task_remote_data_source.dart';
import 'package:hamtimer/features/tasks/domain/entities/task.dart';
import 'package:hamtimer/features/tasks/domain/entities/task_query.dart';
import 'package:hamtimer/shared/errors/app_exception.dart';

/// MockAPI de mentira. Con [offline] lanza `NetworkException` como Dio sin red.
class FakeTaskRemoteDataSource implements TaskRemoteDataSource {
  final Map<String, Task> tasks = {};
  bool offline = false;
  int createCalls = 0;
  int _nextId = 1;

  void _checkNetwork() {
    if (offline) throw const NetworkException();
  }

  @override
  Future<List<Task>> fetchPage(String userId, TaskQuery query) async {
    _checkNetwork();
    return tasks.values.where(query.matches).toList();
  }

  @override
  Future<List<Task>> fetchAll(String userId) async {
    _checkNetwork();
    return tasks.values.toList();
  }

  @override
  Future<List<Task>> fetchCompleted(String userId, {required int limit}) async {
    _checkNetwork();
    return tasks.values.where((t) => t.isCompleted).take(limit).toList();
  }

  @override
  Future<Task> create(String userId, TaskDraft draft) async {
    _checkNetwork();
    createCalls++;
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
    tasks[task.id] = task;
    return task;
  }

  @override
  Future<Task> update(String userId, Task task) async {
    _checkNetwork();
    tasks[task.id] = task;
    return task;
  }

  @override
  Future<void> delete(String userId, String taskId) async {
    _checkNetwork();
    tasks.remove(taskId);
  }
}

/// SQLite de mentira: un mapa en memoria con el estado de sincronización.
class InMemoryTaskLocalDataSource implements TaskLocalDataSource {
  final Map<String, PendingTask> rows = {};

  @override
  Future<void> upsertAll(
    String userId,
    List<Task> tasks, {
    SyncStatus status = SyncStatus.synced,
  }) async {
    for (final task in tasks) {
      final existing = rows[task.id];
      if (status == SyncStatus.synced && existing != null && existing.status != SyncStatus.synced) {
        continue;
      }
      rows[task.id] = PendingTask(task, status);
    }
  }

  @override
  Future<List<Task>> getAll(String userId) async =>
      rows.values.where((r) => r.status != SyncStatus.pendingDelete).map((r) => r.task).toList();

  @override
  Future<List<Task>> getCompleted(String userId, {required int limit}) async =>
      rows.values.map((r) => r.task).where((t) => t.isCompleted).take(limit).toList();

  @override
  Future<List<PendingTask>> getPending(String userId) async =>
      rows.values.where((r) => r.status != SyncStatus.synced).toList();

  @override
  Future<void> replaceLocalId(
    String userId, {
    required String localId,
    required Task synced,
  }) async {
    rows.remove(localId);
    rows[synced.id] = PendingTask(synced, SyncStatus.synced);
  }

  @override
  Future<void> markSynced(String userId, String taskId) async {
    final row = rows[taskId];
    if (row != null) rows[taskId] = PendingTask(row.task, SyncStatus.synced);
  }

  @override
  Future<void> markPendingDelete(String userId, String taskId) async {
    final row = rows[taskId];
    if (row != null) rows[taskId] = PendingTask(row.task, SyncStatus.pendingDelete);
  }

  @override
  Future<void> remove(String userId, String taskId) async => rows.remove(taskId);
}
