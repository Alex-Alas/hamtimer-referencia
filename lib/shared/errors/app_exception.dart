/// Error con un mensaje listo para mostrar al usuario.
///
/// Las capas de datos traducen los errores técnicos (Dio, Firebase, SQLite)
/// a esta clase, así las pantallas nunca tienen que conocer esos paquetes.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No hubo conexión o el servidor no respondió a tiempo.
///
/// Se separa de [AppException] porque el repositorio con caché la usa para
/// decidir cuándo responder con la copia local en lugar de fallar.
class NetworkException extends AppException {
  const NetworkException([super.message = 'Sin conexión con el servidor']);
}
