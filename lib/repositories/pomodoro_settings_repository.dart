import '../models/pomodoro_settings.dart';

/// Contrato para leer y guardar las duraciones del temporizador.
abstract interface class PomodoroSettingsRepository {
  Future<PomodoroSettings> load();

  Future<void> save(PomodoroSettings settings);
}
