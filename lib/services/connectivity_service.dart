import 'package:connectivity_plus/connectivity_plus.dart';

/// Contrato para saber si hay conexión. En las pruebas se usa un fake.
abstract interface class ConnectivityService {
  Future<bool> isOnline();

  /// Emite `true`/`false` cada vez que cambia la conexión.
  Stream<bool> get onlineChanges;
}

/// Implementación con `connectivity_plus`.
///
/// Detecta si el teléfono tiene Wi-Fi o datos, no si internet responde: por
/// eso las fuentes de datos igual manejan los errores de red por su cuenta.
class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async => _hasNetwork(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onlineChanges => _connectivity.onConnectivityChanged.map(_hasNetwork).distinct();

  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
