import '../entities/pomodoro_settings.dart';
import '../repositories/pomodoro_settings_repository.dart';

/// Guarda las duraciones del temporizador.
class SavePomodoroSettingsUseCase {
  const SavePomodoroSettingsUseCase(this._repository);

  final PomodoroSettingsRepository _repository;

  Future<void> call(PomodoroSettings settings) => _repository.save(settings);
}
