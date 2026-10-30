/// De dónde salió una estimación de duración.
enum EstimateSource {
  /// Respuesta de Gemini.
  ai,

  /// Promedio del historial (respaldo si no hay red o Gemini falla).
  history,
}

/// Cuántos Pomodoros debería tomar una tarea, con una razón corta.
class DurationEstimate {
  const DurationEstimate({required this.pomodoros, required this.reason, required this.source});

  final int pomodoros;
  final String reason;
  final EstimateSource source;
}
