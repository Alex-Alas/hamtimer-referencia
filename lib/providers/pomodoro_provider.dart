import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/pomodoro_settings.dart';
import '../models/task.dart';
import '../repositories/pomodoro_settings_repository.dart';
import '../services/pomodoro_alarm.dart';
import 'pomodoro_progress_recorder.dart';

/// Motor del temporizador Pomodoro y de la cola de tareas de la sesión.
///
/// Flujo de una sesión:
/// 1. El usuario agrega tareas a la cola; la primera es la tarea activa.
/// 2. Corre un bloque de **enfoque**. Al terminar se registra un Pomodoro en la
///    tarea activa, se ganan puntos y se emite [FocusBlockFinished].
/// 3. Sigue un **descanso**: corto, o largo cada 4 bloques. Al terminar se
///    emite [BreakFinished].
/// 4. Cuando una tarea alcanza sus Pomodoros estimados sale de la cola.
///
/// Es global (vive encima de las pantallas) para que el tiempo siga
/// corriendo aunque el usuario cambie de pestaña.
class PomodoroProvider extends ChangeNotifier {
  PomodoroProvider({
    required this._recorder,
    required this._settingsRepository,
    this.demoMode = false,
    this._alarm = const NoPomodoroAlarm(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _settings = demoMode ? PomodoroSettings.demo : PomodoroSettings.standard;
    _phaseDuration = _settings.focus;
    _remaining = _settings.focus;
  }

  final PomodoroProgressRecorder _recorder;
  final PomodoroSettingsRepository _settingsRepository;

  /// En modo demo los bloques duran segundos y no se leen las preferencias.
  final bool demoMode;
  final PomodoroAlarm _alarm;
  final DateTime Function() _clock;
  final StreamController<PomodoroEvent> _events = StreamController.broadcast();

  late PomodoroSettings _settings;
  PomodoroPhase _phase = PomodoroPhase.focus;
  late Duration _phaseDuration;
  late Duration _remaining;
  DateTime? _endsAt;
  Timer? _ticker;

  /// Bloques de enfoque terminados en el ciclo actual (0 a 4).
  int _completedBlocksInCycle = 0;

  /// `true` mientras corre una extensión (+5m / +2m). Al terminar una extensión
  /// de enfoque NO se registra otro Pomodoro: ese bloque ya se contó.
  bool _isExtension = false;

  List<Task> _queue = const [];

  // --- Lectura de estado para la UI -----------------------------------------

  PomodoroSettings get settings => _settings;
  PomodoroPhase get phase => _phase;
  Duration get remaining => _remaining;
  bool get isRunning => _ticker != null;
  Stream<PomodoroEvent> get events => _events.stream;
  List<Task> get queue => List.unmodifiable(_queue);
  Task? get activeTask => _queue.isEmpty ? null : _queue.first;

  /// Fracción transcurrida de la etapa actual, para el anillo del dial.
  double get progress => _phaseDuration.inMilliseconds == 0
      ? 0
      : 1 - _remaining.inMilliseconds / _phaseDuration.inMilliseconds;

  /// Número de bloque dentro del ciclo, para la píldora "Ciclo X/4".
  int get currentBlock => (_completedBlocksInCycle + (_phase == PomodoroPhase.focus ? 1 : 0)).clamp(
    1,
    _settings.blocksPerCycle,
  );

  // --- Preferencias (SharedPreferences) --------------------------------------

  /// Carga las duraciones guardadas. Se llama una vez al crear el provider.
  Future<void> loadSettings() async {
    if (demoMode) return;
    _settings = await _settingsRepository.load();
    if (!isRunning) _setPhase(_phase, null);
    notifyListeners();
  }

  Future<void> updateSettings(PomodoroSettings settings) async {
    _settings = settings;
    if (!isRunning) _setPhase(_phase, null);
    notifyListeners();
    if (!demoMode) await _settingsRepository.save(settings);
  }

  // --- Controles del temporizador --------------------------------------------

  void toggle() => isRunning ? pause() : start();

  void start() {
    if (isRunning) return;
    // Se guarda la hora de fin en lugar de restar segundos: así el conteo no
    // se desfasa aunque el sistema retrase algún tick.
    _endsAt = _clock().add(_remaining);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
    // Si la app queda en segundo plano, el sistema avisa a la hora exacta.
    unawaited(
      _alarm.schedule(
        at: _endsAt!,
        title: _phase.isBreak ? 'Descanso terminado' : '¡Bloque de enfoque terminado!',
        body: _phase.isBreak
            ? 'Vuelve a tu tarea cuando estés listo.'
            : 'Abre Hamtimer para tomar tu descanso.',
      ),
    );
    notifyListeners();
  }

  void pause() {
    if (!isRunning) return;
    _stopTicker();
    notifyListeners();
  }

  /// Reinicia la etapa actual a su duración completa.
  void reset() {
    _stopTicker();
    _isExtension = false;
    _setPhase(_phase, null);
    notifyListeners();
  }

  /// Salta a la siguiente etapa sin registrar avance.
  void skip() {
    _stopTicker();
    _isExtension = false;
    _setPhase(
      _phase == PomodoroPhase.focus ? _nextBreak(_completedBlocksInCycle) : PomodoroPhase.focus,
      null,
    );
    notifyListeners();
  }

  @visibleForTesting
  void tick() {
    final endsAt = _endsAt;
    if (endsAt == null) return;
    final left = endsAt.difference(_clock());
    _remaining = left.isNegative ? Duration.zero : left;
    if (_remaining == Duration.zero) {
      _stopTicker();
      unawaited(_onPhaseCompleted());
    }
    notifyListeners();
  }

  // --- Acciones de los pop-ups -----------------------------------------------

  /// "Iniciar descanso": arranca el descanso preparado al terminar el enfoque.
  void startBreak() {
    _isExtension = false;
    start();
  }

  /// "Saltar descanso y continuar": vuelve directo a un bloque de enfoque.
  void skipBreakAndContinue() {
    _isExtension = false;
    _setPhase(PomodoroPhase.focus, null);
    start();
  }

  /// "Extender sesión (+5m)": minutos extra de enfoque antes del descanso.
  void extendFocus() {
    _isExtension = true;
    _setPhase(PomodoroPhase.focus, _settings.focusExtension);
    start();
  }

  /// "Iniciar siguiente bloque": nuevo enfoque tras el descanso.
  void startNextFocus() {
    _isExtension = false;
    _setPhase(PomodoroPhase.focus, null);
    start();
  }

  /// "Tomar +2 min": alarga el descanso que acaba de terminar.
  void extendBreak() {
    _isExtension = true;
    _setPhase(_phase.isBreak ? _phase : PomodoroPhase.shortBreak, _settings.breakExtension);
    start();
  }

  /// "Terminar sesión por hoy": vacía la cola y reinicia el ciclo.
  void endSession() {
    _stopTicker();
    _isExtension = false;
    _completedBlocksInCycle = 0;
    _queue = const [];
    _setPhase(PomodoroPhase.focus, null);
    notifyListeners();
  }

  // --- Cola de la sesión -----------------------------------------------------

  /// Agrega tareas al final de la cola, ignorando las que ya están en ella.
  void addToQueue(Iterable<Task> tasks) {
    final queuedIds = _queue.map((t) => t.id).toSet();
    _queue = [..._queue, ...tasks.where((t) => !t.isCompleted && !queuedIds.contains(t.id))];
    notifyListeners();
  }

  void removeFromQueue(Task task) {
    _queue = _queue.where((t) => t.id != task.id).toList(growable: false);
    notifyListeners();
  }

  bool isQueued(Task task) => _queue.any((t) => t.id == task.id);

  // --- Lógica interna --------------------------------------------------------

  Future<void> _onPhaseCompleted() async {
    if (_phase == PomodoroPhase.focus) {
      final wasExtension = _isExtension;
      _isExtension = false;
      var points = 0;
      String? message;
      if (!wasExtension) {
        _completedBlocksInCycle++;
        (points, message) = await _recordActiveTask();
      }
      final nextBreak = _nextBreak(_completedBlocksInCycle);
      _setPhase(nextBreak, null);
      notifyListeners();
      _events.add(FocusBlockFinished(nextBreak: nextBreak, pointsEarned: points, message: message));
    } else {
      _isExtension = false;
      _events.add(const BreakFinished());
    }
  }

  /// Registra el Pomodoro en la tarea activa. Si falla, el bloque igual cuenta
  /// para el ciclo; solo se avisa que no quedó guardado.
  Future<(int, String?)> _recordActiveTask() async {
    final task = activeTask;
    if (task == null) return (0, null);
    try {
      final record = await _recorder.recordFocusBlock(task);
      final updated = record.task;
      // Se busca por el id de la tarea activa: si se creó sin conexión, al
      // sincronizarse cambia su id local por el de MockAPI.
      _queue = updated.isCompleted
          ? _queue.where((t) => t.id != task.id).toList(growable: false)
          : [for (final t in _queue) t.id == task.id ? updated : t];
      final message = updated.isCompleted ? '¡"${updated.title}" completada!' : null;
      return (record.pointsEarned, message);
    } on AppException catch (error) {
      return (0, 'No se pudo guardar el avance: ${error.message}');
    }
  }

  /// Cada [PomodoroSettings.blocksPerCycle] bloques toca un descanso largo.
  PomodoroPhase _nextBreak(int completedBlocks) => completedBlocks >= _settings.blocksPerCycle
      ? PomodoroPhase.longBreak
      : PomodoroPhase.shortBreak;

  /// Cambia de etapa. [duration] nulo = la duración normal de esa etapa.
  void _setPhase(PomodoroPhase phase, Duration? duration) {
    // Al salir de un descanso largo se cierra el ciclo y el contador vuelve a 0.
    if (phase == PomodoroPhase.focus &&
        _phase.isBreak &&
        (_phase == PomodoroPhase.longBreak ||
            _completedBlocksInCycle >= _settings.blocksPerCycle)) {
      _completedBlocksInCycle = 0;
    }
    _phase = phase;
    _phaseDuration = duration ?? _settings.durationOf(phase);
    _remaining = _phaseDuration;
    _endsAt = null;
  }

  void _stopTicker() {
    if (_ticker != null) unawaited(_alarm.cancel());
    _ticker?.cancel();
    _ticker = null;
    _endsAt = null;
  }

  @override
  void dispose() {
    _stopTicker();
    _events.close();
    super.dispose();
  }
}
