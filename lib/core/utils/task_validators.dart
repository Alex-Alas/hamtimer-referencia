import '../../models/pomodoro_settings.dart';
import '../../models/task_category.dart';

/// Reglas de validación del formulario "Nueva tarea".
///
/// Funciones puras (sin Flutter de por medio): reciben valores y devuelven
/// `null` si todo está bien o el mensaje de error a mostrar.
abstract final class TaskValidators {
  static const int titleMinLength = 3;
  static const int titleMaxLength = 80;
  static const int minPomodoros = 1;
  static const int maxPomodoros = 12;

  static String? title(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe el objetivo de la tarea';
    if (text.length < titleMinLength) return 'Debe tener al menos $titleMinLength caracteres';
    if (text.length > titleMaxLength) return 'Máximo $titleMaxLength caracteres';
    return null;
  }

  static String? category(TaskCategory? value) => value == null ? 'Elige una categoría' : null;

  static String? pomodoros(int value) {
    if (value < minPomodoros) return 'Necesitas al menos $minPomodoros Pomodoro';
    if (value > maxPomodoros) return 'Máximo $maxPomodoros Pomodoros por tarea';
    return null;
  }

  /// Validación cruzada del horario: combina tres campos (inicio, vencimiento
  /// y Pomodoros), por eso no puede vivir en el validador de un solo campo.
  ///
  /// 1. El vencimiento debe ser posterior al inicio.
  /// 2. Entre ambos debe caber el tiempo de enfoque (Pomodoros × 25 min).
  static String? schedule({
    required DateTime startAt,
    required DateTime dueAt,
    required int estimatedPomodoros,
  }) {
    if (!dueAt.isAfter(startAt)) return 'El vencimiento debe ser posterior al inicio';

    final available = dueAt.difference(startAt);
    final required = PomodoroDurations.focusTimeFor(estimatedPomodoros);
    if (available < required) {
      return 'No alcanza el tiempo: $estimatedPomodoros Pomodoro(s) '
          'necesitan ${required.inMinutes} min y solo hay ${available.inMinutes} min';
    }
    return null;
  }
}
