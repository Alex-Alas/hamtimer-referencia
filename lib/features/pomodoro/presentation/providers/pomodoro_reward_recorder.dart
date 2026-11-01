import '../../../tasks/domain/entities/task.dart';
import '../../../camera/domain/entities/wallet.dart';
import '../../domain/repositories/pomodoro_progress_recorder.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../camera/presentation/providers/wallet_provider.dart';

/// Conecta el temporizador con las tareas y el monedero.
///
/// Al terminar un bloque: suma el Pomodoro a la tarea (PUT a MockAPI, o a la
/// cola de SQLite sin red) y luego da los puntos en Firestore. Así `PomodoroProvider` no depende ni de
/// `TaskProvider` ni de `WalletProvider`, solo de [PomodoroProgressRecorder].
class PomodoroRewardRecorder implements PomodoroProgressRecorder {
  PomodoroRewardRecorder({required this.tasks, required this.wallet});

  final TaskProvider tasks;
  final WalletProvider wallet;

  @override
  Future<FocusBlockRecord> recordFocusBlock(Task task) async {
    final updated = await tasks.addPomodoro(task);
    final completedNow = updated.isCompleted && !task.isCompleted;
    final points = PointRules.forFocusBlock(completedTask: completedNow);
    wallet.earn(points);
    return FocusBlockRecord(task: updated, pointsEarned: points);
  }
}
