import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/connectivity_service.dart';

/// Estado global de la conexión.
///
/// La app funciona sin red salvo el feed: el Feed muestra "sin conexión", la
/// Cámara desactiva "Publicar" y, al volver la red, la app sincroniza las
/// tareas pendientes.
class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider(this._service) {
    _subscription = _service.onlineChanges.listen(_set);
    _service.isOnline().then(_set);
  }

  final ConnectivityService _service;
  late final StreamSubscription<bool> _subscription;

  // Se asume conexión hasta saber lo contrario, para no mostrar el aviso de
  // "sin conexión" un instante al abrir la app.
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  void _set(bool online) {
    if (online == _isOnline) return;
    _isOnline = online;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
