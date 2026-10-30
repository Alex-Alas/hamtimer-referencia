import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/task.dart';
import '../../models/task_category.dart';
import '../../models/task_priority.dart';
import 'task_local_data_source.dart';

/// Tareas en SQLite con sqflite (clase 26): la copia local y la cola de
/// sincronización (columna `sync_status`).
///
/// Se eligió SQL porque las tareas son una colección de registros con los
/// mismos campos y se consultan con filtros y orden (`WHERE`, `ORDER BY`).
class SqfliteTaskLocalDataSource implements TaskLocalDataSource {
  SqfliteTaskLocalDataSource({DatabaseFactory? factory, this._fileName = 'hamtimer.db'})
    : _factory = factory ?? databaseFactory;

  final DatabaseFactory _factory;
  final String _fileName;
  Database? _db;

  static const _table = 'tasks';

  /// Abre la base solo la primera vez que se necesita.
  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final path = p.join(await _factory.getDatabasesPath(), _fileName);
    final db = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => db.execute('''
          CREATE TABLE $_table (
            id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            priority TEXT NOT NULL,
            estimated_pomodoros INTEGER NOT NULL,
            completed_pomodoros INTEGER NOT NULL,
            start_at INTEGER NOT NULL,
            due_at INTEGER NOT NULL,
            is_completed INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'synced',
            PRIMARY KEY (id, user_id)
          )
        '''),
      ),
    );
    _db = db;
    return db;
  }

  @override
  Future<void> upsertAll(
    String userId,
    List<Task> tasks, {
    SyncStatus status = SyncStatus.synced,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final pendingIds = status == SyncStatus.synced
          ? (await _pendingRows(txn, userId)).map((row) => row['id']! as String).toSet()
          : const <String>{};
      final batch = txn.batch();
      for (final task in tasks) {
        if (pendingIds.contains(task.id)) continue;
        batch.insert(
          _table,
          _toRow(userId, task, status),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<List<Task>> getAll(String userId) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'due_at ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<Task>> getCompleted(String userId, {required int limit}) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: 'user_id = ? AND is_completed = 1',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<PendingTask>> getPending(String userId) async {
    final rows = await _pendingRows(await _database, userId);
    return [
      for (final row in rows) PendingTask(_fromRow(row), SyncStatus.fromDb(row['sync_status'])),
    ];
  }

  @override
  Future<void> replaceLocalId(
    String userId, {
    required String localId,
    required Task synced,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete(_table, where: 'id = ? AND user_id = ?', whereArgs: [localId, userId]);
      await txn.insert(
        _table,
        _toRow(userId, synced, SyncStatus.synced),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> markSynced(String userId, String taskId) async {
    final db = await _database;
    await db.update(
      _table,
      {'sync_status': SyncStatus.synced.dbValue},
      where: 'id = ? AND user_id = ?',
      whereArgs: [taskId, userId],
    );
  }

  Future<List<Map<String, Object?>>> _pendingRows(DatabaseExecutor db, String userId) => db.query(
    _table,
    where: 'user_id = ? AND sync_status != ?',
    whereArgs: [userId, SyncStatus.synced.dbValue],
    orderBy: 'created_at ASC',
  );

  Map<String, Object?> _toRow(String userId, Task task, SyncStatus status) => {
    'id': task.id,
    'user_id': userId,
    'title': task.title,
    'category': task.category.apiValue,
    'priority': task.priority.apiValue,
    'estimated_pomodoros': task.estimatedPomodoros,
    'completed_pomodoros': task.completedPomodoros,
    'start_at': task.startAt.millisecondsSinceEpoch,
    'due_at': task.dueAt.millisecondsSinceEpoch,
    'is_completed': task.isCompleted ? 1 : 0,
    'created_at': task.createdAt.millisecondsSinceEpoch,
    'sync_status': status.dbValue,
  };

  Task _fromRow(Map<String, Object?> row) => Task(
    id: row['id']! as String,
    title: row['title']! as String,
    category: TaskCategory.fromApi(row['category'] as String?),
    priority: TaskPriority.fromApi(row['priority'] as String?),
    estimatedPomodoros: row['estimated_pomodoros']! as int,
    completedPomodoros: row['completed_pomodoros']! as int,
    startAt: DateTime.fromMillisecondsSinceEpoch(row['start_at']! as int),
    dueAt: DateTime.fromMillisecondsSinceEpoch(row['due_at']! as int),
    isCompleted: row['is_completed'] == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
  );
}
