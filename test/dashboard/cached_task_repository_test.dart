import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/features/tasks/domain/entities/task.dart';
import 'package:hamtimer/features/tasks/domain/entities/task_category.dart';
import 'package:hamtimer/features/tasks/domain/entities/task_priority.dart';
import 'package:hamtimer/features/tasks/domain/entities/task_query.dart';
import 'package:hamtimer/features/tasks/data/repository/cached_task_repository.dart';

import '../fakes/fake_task_data_sources.dart';

void main() {
  test('sin red guarda la tarea en la cola y la envía a MockAPI al volver la red', () async {
    final remote = FakeTaskRemoteDataSource()..offline = true;
    final local = InMemoryTaskLocalDataSource();
    final repository = CachedTaskRepository(remote: remote, local: local);
    final draft = TaskDraft(
      title: 'Repasar sqflite',
      category: TaskCategory.study,
      priority: TaskPriority.high,
      estimatedPomodoros: 2,
      startAt: DateTime(2026, 11, 1, 9),
      dueAt: DateTime(2026, 11, 1, 11),
    );

    // Sin conexión: se crea con id local y se le suma un Pomodoro.
    final offlineTask = await repository.create('uid-1', draft);
    expect(CachedTaskRepository.isLocalId(offlineTask.id), isTrue);
    await repository.update('uid-1', offlineTask.withCompletedPomodoro());
    final offlineList = await repository.fetchAll('uid-1');
    expect(offlineList.fromCache, isTrue);
    expect(offlineList.pendingSync, 1);
    expect(remote.createCalls, 0);

    // Vuelve la red: la siguiente lectura sincroniza la cola.
    remote.offline = false;
    final online = await repository.fetchAll('uid-1');
    expect(online.fromCache, isFalse);
    expect(remote.createCalls, 1);
    expect(online.tasks.single.title, 'Repasar sqflite');
    expect(online.tasks.single.completedPomodoros, 1); // el avance offline no se pierde
    expect(await local.getPending('uid-1'), isEmpty);

    // Página con filtro desde SQLite cuando se vuelve a caer la red.
    remote.offline = true;
    final page = await repository.fetchPage(
      'uid-1',
      const TaskQuery(page: 1, limit: 10, category: TaskCategory.study),
    );
    expect(page.fromCache, isTrue);
    expect(page.tasks, hasLength(1));

    // Borrar sin red: desaparece de la lista y el DELETE queda en la cola.
    final syncedId = page.tasks.single.id;
    await repository.delete('uid-1', syncedId);
    expect((await repository.fetchAll('uid-1')).tasks, isEmpty);
    expect(remote.tasks, hasLength(1));

    // Con red se envía el DELETE y la tarea ya no existe en ningún lado.
    remote.offline = false;
    expect((await repository.fetchAll('uid-1')).tasks, isEmpty);
    expect(remote.tasks, isEmpty);
    expect(await local.getPending('uid-1'), isEmpty);
  });
}
