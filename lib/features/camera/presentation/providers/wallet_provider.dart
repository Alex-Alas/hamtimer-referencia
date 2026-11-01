import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/face_filter.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';

/// Estado global del monedero: puntos y filtros comprados, en vivo desde
/// Firestore.
///
/// El Pomodoro suma puntos, la Cámara los gasta y FCM los regala; los tres
/// pasan por aquí, así nadie más toca el documento del usuario.
class WalletProvider extends ChangeNotifier {
  WalletProvider(this._repository);

  final WalletRepository _repository;

  static const _source = 'wallet';
  StreamSubscription<Wallet>? _subscription;

  String? _uid;
  Wallet _wallet = Wallet.empty;

  Wallet get wallet => _wallet;
  int get points => _wallet.points;

  /// Filtros disponibles para usar en la cámara (los gratis y los comprados).
  List<FaceFilter> get availableFilters =>
      FaceFilter.catalog.where((f) => f.isFree || _wallet.owns(f.id)).toList(growable: false);

  bool owns(FaceFilter filter) => filter.isFree || _wallet.owns(filter.id);

  /// Lo llama el `ChangeNotifierProxyProvider` cuando cambia la sesión.
  void setUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _subscription?.cancel();
    _subscription = null;
    _wallet = Wallet.empty;
    if (uid == null) return;
    // Se agenda para no notificar mientras Flutter construye el árbol.
    Future.microtask(() {
      if (_uid != uid) return;
      _subscription = _repository.watch(uid).listen(
        (wallet) {
          _wallet = wallet;
          notifyListeners();
        },
        onError: (Object error) => AppLogger.warning(_source, 'No se pudo leer: $error'),
      );
      _write('crear el monedero', _repository.ensureExists(uid));
    });
  }

  /// Suma puntos. No espera al servidor: sin red, Firestore guarda el cambio
  /// en el teléfono, actualiza el saldo al instante y lo sube después.
  void earn(int points) {
    final uid = _uid;
    if (uid == null || points <= 0) return;
    _write('sumar puntos', _repository.addPoints(uid, points));
  }

  /// Compra un filtro. Lanza [AppException] con el motivo si no se puede.
  /// Funciona sin conexión, igual que [earn].
  void buy(FaceFilter filter) {
    final uid = _uid;
    if (uid == null) throw const AppException('Inicia sesión primero');
    if (owns(filter)) throw const AppException('Ya tienes este filtro');
    if (!_wallet.canAfford(filter.price)) throw const AppException('No te alcanzan los puntos');
    _write('comprar ${filter.id}', _repository.buyFilter(uid, filter));
  }

  /// Cobra una campaña de FCM. Devuelve los puntos recibidos (0 si no aplica).
  Future<int> claimCampaign(String campaignId) async {
    final uid = _uid;
    if (uid == null) return 0;
    return _repository.claimCampaign(uid, campaignId);
  }

  /// Deja correr una escritura de Firestore sin esperarla y registra si falla
  /// (por ejemplo, si las reglas la rechazan al llegar al servidor).
  void _write(String action, Future<void> write) {
    unawaited(
      write.catchError((Object error) {
        AppLogger.error(_source, 'No se pudo $action', error);
      }),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
