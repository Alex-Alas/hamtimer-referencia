import '../../models/task.dart';

/// Estado de sincronización de una tarea guardada en el teléfono.
enum SyncStatus {
  /// Igual que en MockAPI.
  synced('synced'),

  /// Creada sin conexión: todavía no existe en MockAPI y tiene un id local.
  pendingCreate('pending_create'),

  /// Modificada sin conexión: falta enviar el PUT.
  pendingUpdate('pending_update');

  const SyncStatus(this.dbValue);

  final String dbValue;

  static SyncStatus fromDb(Object? value) =>
      SyncStatus.values.firstWhere((s) => s.dbValue == value, orElse: () => SyncStatus.synced);
}

/// Una tarea de la cola de sincronización.
class PendingTask {
  const PendingTask(this.task, this.status);

  final Task task;
  final SyncStatus status;
}

/// Contrato de la fuente local de tareas (SQLite): la copia en el teléfono y
/// la cola de cambios hechos sin conexión.
abstract interface class TaskLocalDataSource {
  /// Guarda (o reemplaza) tareas con el estado [status].
  ///
  /// Con [SyncStatus.synced] no pisa las que tienen cambios pendientes: esos
  /// cambios son más nuevos que lo que acaba de llegar del servidor.
  Future<void> upsertAll(String userId, List<Task> tasks, {SyncStatus status = SyncStatus.synced});

  /// Todas las tareas guardadas del usuario (pendientes incluidas), ordenadas
  /// por vencimiento.
  Future<List<Task>> getAll(String userId);

  /// Las últimas [limit] completadas, de la más reciente a la más antigua.
  Future<List<Task>> getCompleted(String userId, {required int limit});

  /// Cambios por enviar, del más antiguo al más nuevo.
  Future<List<PendingTask>> getPending(String userId);

  /// Cambia el id local de una tarea creada sin conexión por el definitivo
  /// que asignó MockAPI, y la marca como sincronizada.
  Future<void> replaceLocalId(String userId, {required String localId, required Task synced});

  /// Saca una tarea de la cola sin enviarla (el servidor la rechazó).
  Future<void> markSynced(String userId, String taskId);
}
