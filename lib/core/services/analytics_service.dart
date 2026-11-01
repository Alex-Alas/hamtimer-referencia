import 'package:firebase_analytics/firebase_analytics.dart';

import '../logging/app_logger.dart';

/// Contrato de analítica: cada pantalla registra sus eventos con esto.
///
/// Las pantallas no importan `firebase_analytics`; así en las pruebas se usa
/// `FakeAnalyticsService`, que guarda los eventos en una lista para revisarlos.
abstract interface class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object> parameters = const {}]);

  Future<void> logScreen(String screenName);

  Future<void> setUser(String? uid);
}

/// Implementación con Firebase Analytics (clase 29).
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, [Map<String, Object> parameters = const {}]) async {
    AppLogger.info('analytics', '$name $parameters');
    await _analytics.logEvent(name: name, parameters: parameters.isEmpty ? null : parameters);
  }

  @override
  Future<void> logScreen(String screenName) =>
      _analytics.logScreenView(screenName: screenName, screenClass: screenName);

  @override
  Future<void> setUser(String? uid) => _analytics.setUserId(id: uid);
}
