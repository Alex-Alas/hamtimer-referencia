/// Aviso de que termina una etapa del Pomodoro (contrato).
///
/// El temporizador solo conoce esta interfaz; en las pruebas no suena nada.
abstract interface class PomodoroAlarm {
  /// Programa el aviso para la hora [at], reemplazando el anterior.
  Future<void> schedule({required DateTime at, required String title, required String body});

  /// Cancela el aviso programado, si hay uno.
  Future<void> cancel();
}

/// No hace nada: valor por defecto y para las pruebas.
class NoPomodoroAlarm implements PomodoroAlarm {
  const NoPomodoroAlarm();

  @override
  Future<void> schedule({
    required DateTime at,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancel() async {}
}
