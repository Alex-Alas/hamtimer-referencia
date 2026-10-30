import '../models/task.dart';

/// Lo único que el temporizador necesita saber de las tareas y los puntos:
/// cómo registrar un bloque de enfoque terminado (segregación de interfaces).
abstract interface class PomodoroProgressRecorder {
  /// Suma un Pomodoro a [task], lo guarda, entrega los puntos ganados y
  /// devuelve el resultado.
  Future<FocusBlockRecord> recordFocusBlock(Task task);
}

/// Resultado de registrar un bloque: la tarea actualizada y los puntos.
class FocusBlockRecord {
  const FocusBlockRecord({required this.task, required this.pointsEarned});

  final Task task;
  final int pointsEarned;
}
