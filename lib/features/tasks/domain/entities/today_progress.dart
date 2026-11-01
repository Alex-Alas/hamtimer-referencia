import '../../../../shared/utils/date_utils.dart';
import 'task.dart';

/// Resumen del banner "Avance del día": cuántas tareas que vencen hoy ya
/// están completadas.
class TodayProgress {
  const TodayProgress({required this.completed, required this.total});

  factory TodayProgress.fromTasks(Iterable<Task> tasks, DateTime now) {
    final today = tasks.where((task) => task.dueAt.isSameDayAs(now)).toList();
    return TodayProgress(
      completed: today.where((task) => task.isCompleted).length,
      total: today.length,
    );
  }

  static const empty = TodayProgress(completed: 0, total: 0);

  final int completed;
  final int total;

  /// Proporción entre 0 y 1 para la barra de progreso.
  double get ratio => total == 0 ? 0 : completed / total;

  int get percent => (ratio * 100).round();
}
