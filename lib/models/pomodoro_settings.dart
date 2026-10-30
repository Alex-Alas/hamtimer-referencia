/// Reglas fijas de la técnica Pomodoro que usan el formulario (para validar
/// que el horario alcance) y el temporizador.
abstract final class PomodoroDurations {
  static const Duration focus = Duration(minutes: 25);

  /// Cada cuántos bloques de enfoque toca un descanso largo.
  static const int blocksPerCycle = 4;

  static Duration focusTimeFor(int pomodoros) => focus * pomodoros;
}

/// Etapas por las que pasa el temporizador.
enum PomodoroPhase {
  focus('Enfoque'),
  shortBreak('Descanso corto'),
  longBreak('Descanso largo');

  const PomodoroPhase(this.label);

  final String label;

  bool get isBreak => this != PomodoroPhase.focus;
}

/// Duraciones del temporizador elegidas por el usuario.
///
/// Se guardan en SharedPreferences (clase 25) porque son pares clave-valor
/// sueltos que deben sobrevivir al cerrar la app.
class PomodoroSettings {
  const PomodoroSettings({
    required this.focus,
    required this.shortBreak,
    required this.longBreak,
    this.focusExtension = const Duration(minutes: 5),
    this.breakExtension = const Duration(minutes: 2),
  });

  static const standard = PomodoroSettings(
    focus: Duration(minutes: 25),
    shortBreak: Duration(minutes: 5),
    longBreak: Duration(minutes: 15),
  );

  /// Modo demo: segundos en vez de minutos para presentar en clase.
  static const demo = PomodoroSettings(
    focus: Duration(seconds: 10),
    shortBreak: Duration(seconds: 4),
    longBreak: Duration(seconds: 8),
    focusExtension: Duration(seconds: 5),
    breakExtension: Duration(seconds: 3),
  );

  final Duration focus;
  final Duration shortBreak;
  final Duration longBreak;

  /// "Extender sesión (+5m)" del pop-up de bloque terminado.
  final Duration focusExtension;

  /// "Tomar +2 min" del pop-up de descanso terminado.
  final Duration breakExtension;

  int get blocksPerCycle => PomodoroDurations.blocksPerCycle;

  Duration durationOf(PomodoroPhase phase) => switch (phase) {
    PomodoroPhase.focus => focus,
    PomodoroPhase.shortBreak => shortBreak,
    PomodoroPhase.longBreak => longBreak,
  };

  PomodoroSettings copyWith({Duration? focus, Duration? shortBreak, Duration? longBreak}) {
    return PomodoroSettings(
      focus: focus ?? this.focus,
      shortBreak: shortBreak ?? this.shortBreak,
      longBreak: longBreak ?? this.longBreak,
      focusExtension: focusExtension,
      breakExtension: breakExtension,
    );
  }
}

/// Avisos que emite el temporizador al terminar una etapa, para que la
/// pantalla muestre el pop-up correspondiente.
sealed class PomodoroEvent {
  const PomodoroEvent();
}

/// Terminó un bloque de enfoque. [pointsEarned] son los puntos ganados y
/// [message] trae un aviso (tarea completada o error al guardar).
class FocusBlockFinished extends PomodoroEvent {
  const FocusBlockFinished({required this.nextBreak, this.pointsEarned = 0, this.message});

  final PomodoroPhase nextBreak;
  final int pointsEarned;
  final String? message;
}

/// Terminó un descanso (corto o largo).
class BreakFinished extends PomodoroEvent {
  const BreakFinished();
}
