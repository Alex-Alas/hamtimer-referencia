import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../logging/app_logger.dart';

/// Un aviso recibido por FCM, ya sin tipos del paquete de Firebase.
class PushMessage {
  const PushMessage({this.title, this.body, this.campaignId, this.openedFromTray = false});

  final String? title;
  final String? body;

  /// Si trae `campaignId`, la notificación regala puntos.
  final String? campaignId;

  /// `true` si el usuario tocó la notificación (app en segundo plano o cerrada).
  final bool openedFromTray;
}

/// Notificaciones push con Firebase Cloud Messaging (clase 29).
///
/// La app se suscribe al tema [topic]. Desde la consola de Firebase
/// (Messaging → Nueva campaña) se envían:
/// - avisos de actualizaciones de la app, y
/// - campañas que regalan puntos: llevan el dato personalizado
///   `campaignId` que apunta a `hamtimer_campaigns/{id}`.
class PushNotificationService {
  PushNotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  final StreamController<PushMessage> _controller = StreamController.broadcast();

  static const topic = 'hamtimer_all';
  static const _source = 'fcm';

  /// Avisos en primer plano y notificaciones tocadas.
  Stream<PushMessage> get messages => _controller.stream;

  bool _initialized = false;

  /// Pide permiso, se suscribe al tema y empieza a escuchar. Se puede llamar
  /// más de una vez (al volver a iniciar sesión): solo la primera hace algo.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final settings = await _messaging.requestPermission();
    AppLogger.info(_source, 'Permiso: ${settings.authorizationStatus.name}');
    await _messaging.subscribeToTopic(topic);

    FirebaseMessaging.onMessage.listen((message) => _emit(message, openedFromTray: false));
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _emit(message, openedFromTray: true));

    // La app estaba cerrada y se abrió tocando la notificación.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _emit(initial, openedFromTray: true);
  }

  void _emit(RemoteMessage message, {required bool openedFromTray}) {
    AppLogger.info(_source, 'Mensaje ${message.messageId} ${message.data}');
    _controller.add(
      PushMessage(
        title: message.notification?.title,
        body: message.notification?.body,
        campaignId: message.data['campaignId'] as String?,
        openedFromTray: openedFromTray,
      ),
    );
  }

  Future<void> dispose() => _controller.close();
}
