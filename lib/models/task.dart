import 'task_category.dart';
import 'task_priority.dart';

/// Datos que el usuario captura en el formulario, antes de existir en la API.
///
/// Se separa de [Task] porque una tarea nueva todavía no tiene `id`, ni
/// progreso, ni fecha de creación: eso lo asigna el backend al hacer POST.
class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.category,
    required this.priority,
    required this.estimatedPomodoros,
    required this.startAt,
    required this.dueAt,
  });

  final String title;
  final TaskCategory category;
  final TaskPriority priority;
  final int estimatedPomodoros;
  final DateTime startAt;
  final DateTime dueAt;
}

/// Una tarea registrada en Hamtimer.
///
/// Es inmutable: cualquier cambio produce una copia nueva con [copyWith], lo
/// que hace predecible el estado que comparten las pantallas.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.estimatedPomodoros,
    required this.completedPomodoros,
    required this.startAt,
    required this.dueAt,
    required this.isCompleted,
    required this.createdAt,
  });

  final String id;
  final String title;
  final TaskCategory category;
  final TaskPriority priority;
  final int estimatedPomodoros;
  final int completedPomodoros;
  final DateTime startAt;
  final DateTime dueAt;
  final bool isCompleted;
  final DateTime createdAt;

  /// Pomodoros que faltan para cumplir el estimado (nunca negativo).
  int get remainingPomodoros =>
      (estimatedPomodoros - completedPomodoros).clamp(0, estimatedPomodoros);

  /// Regla de negocio central del temporizador: cada bloque de enfoque suma un
  /// Pomodoro y, al alcanzar el estimado, la tarea queda completada.
  Task withCompletedPomodoro() {
    final completed = completedPomodoros + 1;
    return copyWith(
      completedPomodoros: completed,
      isCompleted: isCompleted || completed >= estimatedPomodoros,
    );
  }

  /// Los datos capturados, para volver a enviarla con POST (la cola de
  /// sincronización la usa con las tareas creadas sin conexión).
  TaskDraft toDraft() => TaskDraft(
    title: title,
    category: category,
    priority: priority,
    estimatedPomodoros: estimatedPomodoros,
    startAt: startAt,
    dueAt: dueAt,
  );

  /// Copia con otro [id]; se usa cuando MockAPI asigna el id definitivo.
  Task withId(String newId) => Task(
    id: newId,
    title: title,
    category: category,
    priority: priority,
    estimatedPomodoros: estimatedPomodoros,
    completedPomodoros: completedPomodoros,
    startAt: startAt,
    dueAt: dueAt,
    isCompleted: isCompleted,
    createdAt: createdAt,
  );

  Task copyWith({
    String? title,
    TaskCategory? category,
    TaskPriority? priority,
    int? estimatedPomodoros,
    int? completedPomodoros,
    DateTime? startAt,
    DateTime? dueAt,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      startAt: startAt ?? this.startAt,
      dueAt: dueAt ?? this.dueAt,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}
