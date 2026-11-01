import 'package:hamtimer/shared/services/analytics_service.dart';

/// Guarda los eventos en una lista para revisarlos en las pruebas.
class FakeAnalyticsService implements AnalyticsService {
  final List<String> events = [];
  final List<String> screens = [];

  @override
  Future<void> logEvent(String name, [Map<String, Object> parameters = const {}]) async =>
      events.add(name);

  @override
  Future<void> logScreen(String screenName) async => screens.add(screenName);

  @override
  Future<void> setUser(String? uid) async {}
}
