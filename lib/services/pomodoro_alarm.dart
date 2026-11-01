import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/logging/app_logger.dart';

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

/// Notificación local con sonido y vibración (flutter_local_notifications).
///
/// Android puede dormir la app con la pantalla apagada, pero un aviso del
/// sistema (AlarmManager) sí llega a la hora. Solo se deja programado cuando
/// la app pasa a segundo plano: con la app abierta ya aparece el pop-up y la
/// notificación sería un duplicado.
class LocalNotificationPomodoroAlarm with WidgetsBindingObserver implements PomodoroAlarm {
  LocalNotificationPomodoroAlarm({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin() {
    WidgetsBinding.instance.addObserver(this);
  }

  final FlutterLocalNotificationsPlugin _plugin;

  static const _source = 'pomodoro_alarm';
  static const _notificationId = 1;
  static const _channelId = 'pomodoro_blocks';

  Future<void>? _initialization;

  /// Lo último que pidió el temporizador; se programa al ir a segundo plano.
  ({DateTime at, String title, String body})? _requested;
  bool _inBackground = false;

  Future<void> _ensureInitialized() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  @override
  Future<void> schedule({required DateTime at, required String title, required String body}) async {
    _requested = (at: at, title: title, body: body);
    if (_inBackground) await _scheduleRequested();
  }

  @override
  Future<void> cancel() async {
    _requested = null;
    await _cancelScheduled();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _inBackground = false;
        _cancelScheduled();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _inBackground = true;
        _scheduleRequested();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _scheduleRequested() async {
    final request = _requested;
    if (request == null || !request.at.isAfter(DateTime.now())) return;
    try {
      await _ensureInitialized();
      await _plugin.zonedSchedule(
        id: _notificationId,
        title: request.title,
        body: request.body,
        // La hora absoluta no depende de la zona horaria: se usa UTC.
        scheduledDate: tz.TZDateTime.from(request.at, tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Bloques del Pomodoro',
            channelDescription: 'Avisa cuando termina un bloque de enfoque o de descanso',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on Exception catch (error, stack) {
      AppLogger.error(_source, 'No se pudo programar el aviso', error, stack);
    }
  }

  Future<void> _cancelScheduled() async {
    try {
      await _ensureInitialized();
      await _plugin.cancel(id: _notificationId);
    } on Exception catch (error, stack) {
      AppLogger.error(_source, 'No se pudo cancelar el aviso', error, stack);
    }
  }
}
