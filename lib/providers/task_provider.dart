import 'package:flutter/foundation.dart';

import '../core/config/env.dart';
import '../core/errors/app_exception.dart';
import '../models/task.dart';
import '../models/task_filter.dart';
import '../models/task_query.dart';
import '../models/today_progress.dart';
import '../repositories/task_repository.dart';

/// Estado global de las tareas: la lista visible, su paginación, el filtro
/// activo, el progreso del día y si los datos vienen de SQLite (sin red).
///
/// Lo usan el Dashboard (lista), el formulario (crear) y el Pomodoro (sumar
/// avance). Ninguno habla con MockAPI: todos pasan por aquí, y aquí solo se
/// conoce el contrato [TaskRepository].
class TaskProvider extends ChangeNotifier {
  TaskProvider({
    required this._repository,
    this.pageSize = Env.pageSize,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final TaskRepository _repository;
  final int pageSize;
  final DateTime Function() _clock;

  String? _userId;
  List<Task> _tasks = const [];
  TaskFilter _filter = const AllTasksFilter();
  TodayProgress _todayProgress = TodayProgress.empty;
  int _nextPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isOffline = false;
  int _pendingSync = 0;
  String? _errorMessage;

  /// Se incrementa en cada recarga. Si cambia el filtro mientras una petición
  /// sigue en vuelo, su respuesta llega con una generación vieja y se descarta.
  int _generation = 0;

  String? get userId => _userId;
  List<Task> get tasks => List.unmodifiable(_tasks);
  TaskFilter get filter => _filter;
  TodayProgress get todayProgress => _todayProgress;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isOffline => _isOffline;

  /// Cambios hechos sin conexión que todavía no llegan a MockAPI.
  int get pendingSync => _pendingSync;
  String? get errorMessage => _errorMessage;

  /// Lo llama el `ChangeNotifierProxyProvider` cada vez que cambia la sesión.
  ///
  /// Ocurre mientras Flutter construye el árbol, cuando no se puede llamar a
  /// `notifyListeners`; por eso la recarga se agenda con `Future.microtask`.
  void setUser(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _tasks = const [];
    _todayProgress = TodayProgress.empty;
    _filter = const AllTasksFilter();
    if (userId != null) Future.microtask(refresh);
  }

  // --- GET -------------------------------------------------------------------

  /// Recarga desde cero la lista (con el filtro actual) y el banner del día.
  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) return;
    final generation = ++_generation;
    _tasks = const [];
    _nextPage = 1;
    _hasMore = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.wait([_loadNextPage(userId, generation), _loadTodayProgress(userId)]);

    if (generation == _generation) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Siguiente página; la pide el scroll infinito al llegar al final.
  Future<void> loadMore() async {
    final userId = _userId;
    if (userId == null || _isLoading || _isLoadingMore || !_hasMore) return;
    final generation = _generation;
    _isLoadingMore = true;
    notifyListeners();

    await _loadNextPage(userId, generation);

    if (generation == _generation) {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> changeFilter(TaskFilter filter) async {
    if (filter == _filter) return;
    _filter = filter;
    await refresh();
  }

  Future<void> _loadNextPage(String userId, int generation) async {
    try {
      final TaskListResult result;
      if (_filter.isClientSide) {
        // MockAPI no filtra por rango de fechas: se trae todo y se filtra aquí.
        final now = _clock();
        final all = await _repository.fetchAll(userId);
        result = TaskListResult(
          all.tasks.where((t) => _filter.matches(t, now)).toList(),
          fromCache: all.fromCache,
        );
        if (generation != _generation) return;
        _hasMore = false;
      } else {
        result = await _repository.fetchPage(
          userId,
          _filter.toQuery(page: _nextPage, limit: pageSize),
        );
        if (generation != _generation) return;
        // Del caché llega todo de una vez; de la API, una página incompleta
        // significa que ya no quedan más registros.
        _hasMore = !result.fromCache && result.tasks.length == pageSize;
        _nextPage++;
      }
      _isOffline = result.fromCache;
      _pendingSync = result.pendingSync;
      _tasks = [..._tasks, ...result.tasks];
    } on AppException catch (error) {
      if (generation != _generation) return;
      _errorMessage = error.message;
      _hasMore = false;
    }
  }

  /// El banner siempre refleja todas las tareas de hoy, sin importar el
  /// filtro ni cuántas páginas se hayan cargado.
  Future<void> _loadTodayProgress(String userId) async {
    try {
      final all = await _repository.fetchAll(userId);
      _todayProgress = TodayProgress.fromTasks(all.tasks, _clock());
    } on AppException {
      // El banner es secundario: si falla, se queda con el último valor.
    }
  }

  /// Tareas pendientes para agregar a la sesión de Pomodoro.
  Future<List<Task>> fetchPendingTasks() async {
    final userId = _requireUser();
    final all = await _repository.fetchAll(userId);
    return all.tasks.where((task) => !task.isCompleted).toList(growable: false);
  }

  /// Historial de tareas completadas para el estimador de Gemini.
  Future<List<Task>> fetchHistory() => _repository.fetchHistory(_requireUser());

  // --- POST ------------------------------------------------------------------

  /// Registra la tarea y recarga la lista. Sin red también funciona: el
  /// repositorio la deja pendiente en SQLite. Lanza [AppException] si falla,
  /// para que el formulario lo muestre sin perder lo que el usuario escribió.
  Future<Task> create(TaskDraft draft) async {
    final created = await _repository.create(_requireUser(), draft);
    await refresh();
    return created;
  }

  // --- PUT -------------------------------------------------------------------

  /// Marca o desmarca una tarea desde la tarjeta del dashboard.
  ///
  /// Actualización optimista: la UI cambia al instante y, si el PUT falla, se
  /// revierte y se relanza el error para avisar al usuario.
  Future<void> toggleCompleted(Task task) async {
    final userId = _requireUser();
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    _replace(updated);
    try {
      _replace(await _repository.update(userId, updated));
      await _loadTodayProgress(userId);
      notifyListeners();
    } on AppException {
      _replace(task);
      rethrow;
    }
  }

  // --- DELETE ----------------------------------------------------------------

  /// Quita la tarea de la lista sin borrarla todavía: da tiempo a "Deshacer".
  void hideTask(Task task) {
    _tasks = _tasks.where((t) => t.id != task.id).toList(growable: false);
    notifyListeners();
  }

  /// Borra la tarea de verdad (MockAPI y SQLite; sin red queda en la cola).
  Future<void> deleteTask(Task task) async {
    final userId = _requireUser();
    await _repository.delete(userId, task.id);
    await _loadTodayProgress(userId);
    notifyListeners();
  }

  /// "Deshacer": la tarea nunca se borró, solo se ocultó; basta recargar.
  Future<void> restoreTask() => refresh();

  /// Suma un Pomodoro a la tarea y la guarda. Lo usa el temporizador.
  Future<Task> addPomodoro(Task task) async {
    final userId = _requireUser();
    final saved = await _repository.update(userId, task.withCompletedPomodoro());
    _replace(saved);
    await _loadTodayProgress(userId);
    notifyListeners();
    return saved;
  }

  String _requireUser() {
    final userId = _userId;
    if (userId == null) throw const AppException('Inicia sesión primero');
    return userId;
  }

  void _replace(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    _tasks = [..._tasks]..[index] = task;
    notifyListeners();
  }
}
