/// Nivel de prioridad elegido en el selector segmentado del formulario.
enum TaskPriority {
  low('low', 'Baja'),
  medium('med', 'Media'),
  high('high', 'Alta');

  const TaskPriority(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static const TaskPriority defaultValue = TaskPriority.medium;

  static TaskPriority fromApi(String? value) => TaskPriority.values.firstWhere(
    (priority) => priority.apiValue == value,
    orElse: () => defaultValue,
  );
}
