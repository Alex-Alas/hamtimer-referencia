import 'package:hamtimer/models/pomodoro_settings.dart';
import 'package:hamtimer/models/task.dart';
import 'package:hamtimer/models/wallet.dart';
import 'package:hamtimer/providers/pomodoro_progress_recorder.dart';
import 'package:hamtimer/repositories/pomodoro_settings_repository.dart';

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
