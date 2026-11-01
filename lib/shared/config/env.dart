/// Configuración que cambia según cómo se compile la app.
///
/// Los valores llegan con `--dart-define-from-file=env/dev.json` (o con
/// `--dart-define=CLAVE=valor`), así no hay que tocar código para apuntar a
/// otro backend o activar el modo demo. Ejemplo:
///
/// ```sh
/// flutter run --dart-define-from-file=env/dev.json
/// ```
abstract final class Env {
  /// URL base de MockAPI. El recurso `/tasks` se agrega en la fuente remota.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://6acd58b8b406cb8ec0c70e50.mockapi.io',
  );

  /// Modo demo: los bloques de Pomodoro duran segundos en vez de minutos,
  /// para poder mostrar el ciclo completo en la presentación.
  static const bool fastPomodoro = bool.fromEnvironment('FAST_POMODORO');

  /// Modelo de Gemini que usa el estimador de duración.
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash-lite',
  );

  /// Clave de la Gemini API (Google AI Studio). Va en `env/local.json`, que
  /// no se sube al repo. Vacía = el estimador usa solo el historial.
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Tamaño de página para el scroll infinito del dashboard.
  static const int pageSize = 10;

  /// Tiempo máximo de espera de cada petición HTTP.
  static const Duration requestTimeout = Duration(seconds: 15);
}
