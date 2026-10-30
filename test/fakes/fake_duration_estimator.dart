import 'package:hamtimer/models/duration_estimate.dart';
import 'package:hamtimer/models/task.dart';
import 'package:hamtimer/models/task_category.dart';
import 'package:hamtimer/services/duration_estimator.dart';

/// Estimador que siempre responde [pomodoros] como si fuera Gemini.
class FakeDurationEstimator implements DurationEstimator {
  FakeDurationEstimator(this.pomodoros);

  final int pomodoros;
  List<Task>? receivedHistory;

  @override
  Future<DurationEstimate> estimate({
    required String title,
    required TaskCategory category,
    required List<Task> history,
  }) async {
    receivedHistory = history;
    return DurationEstimate(
      pomodoros: pomodoros,
      reason: 'Parecida a otras',
      source: EstimateSource.ai,
    );
  }
}
