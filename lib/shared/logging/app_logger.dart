import 'dart:developer' as developer;

/// Bitácora de la app (clase 28).
///
/// Envuelve `dart:developer` para que los mensajes salgan en la consola de
/// `flutter run` y en la pestaña Logging de DevTools, con un nivel y un
/// origen que permiten filtrarlos. Nunca se usa `print`.
abstract final class AppLogger {
  static void info(String source, String message) => _log(source, message, 800);

  static void warning(String source, String message) => _log(source, message, 900);

  static void error(String source, String message, [Object? error, StackTrace? stackTrace]) =>
      _log(source, message, 1000, error, stackTrace);

  static void _log(
    String source,
    String message,
    int level, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    developer.log(
      message,
      name: 'hamtimer.$source',
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
