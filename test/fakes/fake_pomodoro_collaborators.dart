import 'package:hamtimer/features/pomodoro/domain/entities/pomodoro_settings.dart';
import 'package:hamtimer/features/tasks/domain/entities/task.dart';
import 'package:hamtimer/features/camera/domain/entities/wallet.dart';
import 'package:hamtimer/features/pomodoro/domain/repositories/pomodoro_progress_recorder.dart';
import 'package:hamtimer/features/pomodoro/domain/repositories/pomodoro_settings_repository.dart';

/// Registra los bloques en memoria y da los puntos de [PointRules].
class FakeProgressRecorder implements PomodoroProgressRecorder {
  final List<Task> recorded = [];

  @override
  Future<FocusBlockRecord> recordFocusBlock(Task task) async {
    recorded.add(task);
    final updated = task.withCompletedPomodoro();
    final completedNow = updated.isCompleted && !task.isCompleted;
    return FocusBlockRecord(
      task: updated,
      pointsEarned: PointRules.forFocusBlock(completedTask: completedNow),
    );
  }
}

class FakePomodoroSettingsRepository implements PomodoroSettingsRepository {
  PomodoroSettings saved = PomodoroSettings.standard;

  @override
  Future<PomodoroSettings> load() async => saved;

  @override
  Future<void> save(PomodoroSettings settings) async => saved = settings;
}
