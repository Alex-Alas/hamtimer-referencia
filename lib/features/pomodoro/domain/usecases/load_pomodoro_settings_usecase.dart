import '../entities/pomodoro_settings.dart';
import '../repositories/pomodoro_settings_repository.dart';

/// Lee las duraciones guardadas del temporizador.
class LoadPomodoroSettingsUseCase {
  const LoadPomodoroSettingsUseCase(this._repository);

  final PomodoroSettingsRepository _repository;

  Future<PomodoroSettings> call() => _repository.load();
}
