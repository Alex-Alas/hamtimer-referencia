/// Categorías de una tarea.
///
/// [apiValue] es el texto que viaja a MockAPI y a SQLite: se mantiene estable
/// aunque la etiqueta visible cambie. El ícono de cada una vive en la capa de
/// presentación (`widgets/common/task_visuals.dart`) para que el modelo no
/// dependa de Flutter.
enum TaskCategory {
  deepWork('deepWork', 'Trabajo profundo'),
  quickWin('quickWin', 'Victoria rápida'),
  personal('personal', 'Personal'),
  study('study', 'Estudio'),
  meeting('meeting', 'Reunión');

  const TaskCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Si llega un valor desconocido no se rompe la app: cae en [personal].
  static TaskCategory fromApi(String? value) => TaskCategory.values.firstWhere(
    (category) => category.apiValue == value,
    orElse: () => TaskCategory.personal,
  );
}
