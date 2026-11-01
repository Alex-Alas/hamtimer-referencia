import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../datasource/task_local_data_source.dart';
import '../datasource/task_remote_data_source.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_query.dart';
import '../../domain/repositories/task_repository.dart';

/// Repositorio de tareas que funciona con y sin conexión.
///
/// - **Lectura:** primero envía la cola de cambios pendientes y luego pide a
///   MockAPI. Si responde, guarda la copia en SQLite y la devuelve. Si no hay
///   red, devuelve lo que hay en SQLite marcado con `fromCache: true`.
/// - **Escritura:** intenta MockAPI. Sin red, guarda el cambio en SQLite como
///   pendiente (`pending_create`, `pending_update` o `pending_delete`) y lo devuelve igual, así
///   el usuario sigue trabajando. La próxima lectura con red lo sincroniza.
///
/// `TaskProvider` no sabe que existen el caché ni la cola: solo ve
/// [TaskRepository]. Conflictos: gana el último cambio que llega a MockAPI
/// (cada tarea la edita solo su dueño, desde un teléfono).
class CachedTaskRepository implements TaskRepository {
  CachedTaskRepository({required this._remote, required this._local, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final TaskRemoteDataSource _remote;
  final TaskLocalDataSource _local;
  final DateTime Function() _clock;

  /// Ids locales ya sincronizados → id definitivo de MockAPI. Sirve para las
  /// pantallas que todavía guardan la tarea con el id viejo (la cola del
  /// Pomodoro, por ejemplo).
  final Map<String, String> _syncedIds = {};

  static const _source = 'tasks';
  static const localIdPrefix = 'local-';

  static bool isLocalId(String id) => id.startsWith(localIdPrefix);

  @override
  Future<TaskListResult> fetchPage(String userId, TaskQuery query) async {
    try {
      await _syncPending(userId);
      final tasks = await _remote.fetchPage(userId, query);
      await _saveCopy(userId, tasks);
      return TaskListResult(tasks);
    } on NetworkException {
      AppLogger.warning(_source, 'Sin red: página ${query.page} desde SQLite');
      // SQLite no pagina: la primera "página" trae todo lo guardado.
      if (query.page > 1) return const TaskListResult([], fromCache: true);
      final cached = await _local.getAll(userId);
      return TaskListResult(
        cached.where(query.matches).toList(),
        fromCache: true,
        pendingSync: (await _local.getPending(userId)).length,
      );
    }
  }

  @override
  Future<TaskListResult> fetchAll(String userId) async {
    try {
      await _syncPending(userId);
      final tasks = await _remote.fetchAll(userId);
      await _saveCopy(userId, tasks);
      return TaskListResult(tasks);
    } on NetworkException {
      AppLogger.warning(_source, 'Sin red: lista completa desde SQLite');
      return TaskListResult(
        await _local.getAll(userId),
        fromCache: true,
        pendingSync: (await _local.getPending(userId)).length,
      );
    }
  }

  @override
  Future<List<Task>> fetchHistory(String userId, {int limit = 20}) async {
    try {
      return await _remote.fetchCompleted(userId, limit: limit);
    } on NetworkException {
      return _local.getCompleted(userId, limit: limit);
    }
  }

  @override
  Future<Task> create(String userId, TaskDraft draft) async {
    try {
      final created = await _remote.create(userId, draft);
      await _saveCopy(userId, [created]);
      return created;
    } on NetworkException {
      final now = _clock();
      final local = Task(
        id: '$localIdPrefix${now.microsecondsSinceEpoch}',
        title: draft.title.trim(),
        category: draft.category,
        priority: draft.priority,
        estimatedPomodoros: draft.estimatedPomodoros,
        completedPomodoros: 0,
        startAt: draft.startAt,
        dueAt: draft.dueAt,
        isCompleted: false,
        createdAt: now,
      );
      await _local.upsertAll(userId, [local], status: SyncStatus.pendingCreate);
      AppLogger.info(_source, 'Sin red: "${local.title}" queda pendiente de crear');
      return local;
    }
  }

  @override
  Future<Task> update(String userId, Task task) async {
    // Si la tarea ya se sincronizó, se usa su id definitivo.
    final syncedId = _syncedIds[task.id];
    final current = syncedId == null ? task : task.withId(syncedId);

    // Una tarea que aún no existe en MockAPI no tiene a quién hacerle PUT:
    // se actualiza en SQLite y se sigue enviando como "crear".
    if (isLocalId(current.id)) {
      await _local.upsertAll(userId, [current], status: SyncStatus.pendingCreate);
      return current;
    }
    try {
      final saved = await _remote.update(userId, current);
      await _saveCopy(userId, [saved]);
      return saved;
    } on NetworkException {
      await _local.upsertAll(userId, [current], status: SyncStatus.pendingUpdate);
      AppLogger.info(_source, 'Sin red: cambio en "${current.title}" pendiente');
      return current;
    }
  }

  @override
  Future<void> delete(String userId, String taskId) async {
    final id = _syncedIds[taskId] ?? taskId;
    // Una tarea que nunca llegó a MockAPI solo existe en SQLite.
    if (isLocalId(id)) {
      await _local.remove(userId, id);
      return;
    }
    try {
      await _remote.delete(userId, id);
      await _local.remove(userId, id);
    } on NetworkException {
      await _local.markPendingDelete(userId, id);
      AppLogger.info(_source, 'Sin red: borrado de $id pendiente');
    }
  }

  /// Envía la cola a MockAPI, del cambio más viejo al más nuevo.
  ///
  /// Si se cae la red a la mitad, relanza [NetworkException] y lo que falta se
  /// intenta en la próxima lectura. Si el servidor rechaza un cambio (por
  /// ejemplo, la tarea ya no existe), se descarta para no reintentarlo siempre.
  Future<void> _syncPending(String userId) async {
    final pending = await _local.getPending(userId);
    if (pending.isEmpty) return;
    AppLogger.info(_source, 'Sincronizando ${pending.length} cambio(s)');
    for (final item in pending) {
      try {
        switch (item.status) {
          case SyncStatus.pendingCreate:
            final local = item.task;
            final created = await _remote.create(userId, local.toDraft());
            // El POST crea la tarea en cero; se le pone el avance hecho offline.
            final withProgress = created.copyWith(
              completedPomodoros: local.completedPomodoros,
              isCompleted: local.isCompleted,
            );
            await _local.replaceLocalId(userId, localId: local.id, synced: withProgress);
            _syncedIds[local.id] = created.id;
            if (local.completedPomodoros > 0 || local.isCompleted) {
              // Ya existe en MockAPI: el avance queda como PUT pendiente, así
              // si la red se cae aquí no se vuelve a crear la tarea.
              await _local.upsertAll(userId, [withProgress], status: SyncStatus.pendingUpdate);
              await _remote.update(userId, withProgress);
              await _local.markSynced(userId, created.id);
            }
          case SyncStatus.pendingUpdate:
            final saved = await _remote.update(userId, item.task);
            await _local.markSynced(userId, saved.id);
          case SyncStatus.pendingDelete:
            await _remote.delete(userId, item.task.id);
            await _local.remove(userId, item.task.id);
          case SyncStatus.synced:
            break;
        }
      } on NetworkException {
        rethrow;
      } on AppException catch (error) {
        AppLogger.warning(_source, 'Se descarta "${item.task.title}": ${error.message}');
        if (item.status == SyncStatus.pendingDelete) {
          await _local.remove(userId, item.task.id);
        } else {
          await _local.markSynced(userId, item.task.id);
        }
      }
    }
  }

  /// Si falla el guardado local no se interrumpe al usuario: con red, la
  /// fuente de verdad sigue siendo MockAPI.
  Future<void> _saveCopy(String userId, List<Task> tasks) async {
    try {
      await _local.upsertAll(userId, tasks);
    } on Exception catch (error, stack) {
      AppLogger.error(_source, 'No se pudo guardar en SQLite', error, stack);
    }
  }
}
