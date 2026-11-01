import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/features/tasks/domain/entities/task_filter.dart';
import 'package:hamtimer/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:hamtimer/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:hamtimer/features/tasks/domain/usecases/get_task_history_usecase.dart';
import 'package:hamtimer/features/tasks/domain/usecases/get_task_page_usecase.dart';
import 'package:hamtimer/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:hamtimer/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:hamtimer/features/tasks/presentation/providers/task_provider.dart';

import '../fakes/fake_task_repository.dart';
import '../fakes/task_factory.dart';

void main() {
  test('carga por páginas, filtra y avisa cuando los datos vienen de SQLite', () async {
    final repository = FakeTaskRepository([
      for (var i = 1; i <= 5; i++) buildTask(id: '$i', isCompleted: i == 5),
    ]);
    final provider = TaskProvider(
      getTasks: GetTasksUseCase(repository),
      getTaskPage: GetTaskPageUseCase(repository),
      getTaskHistory: GetTaskHistoryUseCase(repository),
      createTask: CreateTaskUseCase(repository),
      updateTask: UpdateTaskUseCase(repository),
      deleteTask: DeleteTaskUseCase(repository),
      pageSize: 2,
    )..setUser('uid-1');
    await Future<void>.delayed(Duration.zero); // setUser agenda la carga

    await provider.refresh();
    expect(provider.tasks.map((t) => t.id), ['1', '2']);
    expect(provider.hasMore, isTrue);

    await provider.loadMore();
    expect(provider.tasks.map((t) => t.id), ['1', '2', '3', '4']);

    await provider.changeFilter(const CompletedFilter());
    expect(provider.tasks.map((t) => t.id), ['5']);

    repository.offline = true;
    await provider.refresh();
    expect(provider.isOffline, isTrue);
  });
}
