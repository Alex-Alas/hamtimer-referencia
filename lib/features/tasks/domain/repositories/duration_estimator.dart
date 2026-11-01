import '../entities/duration_estimate.dart';
import '../entities/task.dart';
import '../entities/task_category.dart';

/// Contrato del estimador de duración del formulario: un solo método
/// (segregación de interfaces).
abstract interface class DurationEstimator {
  /// Estima cuántos Pomodoros tomará la tarea [title] de [category], usando
  /// las tareas ya completadas del usuario como referencia.
  Future<DurationEstimate> estimate({
    required String title,
    required TaskCategory category,
    required List<Task> history,
  });
}

/// Estimador de respaldo: promedio de Pomodoros reales del historial.
///
/// Se usa cuando no hay red o Gemini falla. Prefiere las tareas de la misma
/// categoría; si no hay, usa todo el historial; si no hay historial, 2.
class HistoryAverageEstimator implements DurationEstimator {
  const HistoryAverageEstimator();

  static const int defaultPomodoros = 2;

  @override
  Future<DurationEstimate> estimate({
    required String title,
    required TaskCategory category,
    required List<Task> history,
  }) async {
    final sameCategory = history.where((task) => task.category == category).toList();
    final sample = sameCategory.isNotEmpty ? sameCategory : history;
    if (sample.isEmpty) {
      return const DurationEstimate(
        pomodoros: defaultPomodoros,
        reason: 'Aún no tienes historial; se sugiere el valor por defecto',
        source: EstimateSource.history,
      );
    }
    final total = sample.fold<int>(0, (sum, task) => sum + task.completedPomodoros);
    final average = (total / sample.length).round().clamp(1, 12);
    final scope = sameCategory.isNotEmpty ? 'tus tareas de ${category.label}' : 'tu historial';
    return DurationEstimate(
      pomodoros: average,
      reason: 'Promedio de ${sample.length} tarea(s) de $scope',
      source: EstimateSource.history,
    );
  }
}
