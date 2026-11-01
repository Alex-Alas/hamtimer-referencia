import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../shared/errors/app_exception.dart';
import '../../../../shared/logging/app_logger.dart';
import '../../domain/entities/face_filter.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/usecases/buy_filter_usecase.dart';
import '../../domain/usecases/claim_campaign_usecase.dart';
import '../../domain/usecases/earn_points_usecase.dart';
import '../../domain/usecases/ensure_wallet_usecase.dart';
import '../../domain/usecases/watch_wallet_usecase.dart';

/// Estado global del monedero: puntos y filtros comprados, en vivo desde
/// Firestore.
///
/// El Pomodoro suma puntos, la Cámara los gasta y FCM los regala; los tres
/// pasan por aquí, así nadie más toca el documento del usuario.
class WalletProvider extends ChangeNotifier {
  WalletProvider({
    required this._watchWallet,
    required this._ensureWallet,
    required this._earnPoints,
    required this._buyFilter,
    required this._claimCampaign,
  });

  final WatchWalletUseCase _watchWallet;
  final EnsureWalletUseCase _ensureWallet;
  final EarnPointsUseCase _earnPoints;
  final BuyFilterUseCase _buyFilter;
  final ClaimCampaignUseCase _claimCampaign;

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
      _subscription = _watchWallet(uid).listen(
        (wallet) {
          _wallet = wallet;
          notifyListeners();
        },
        onError: (Object error) => AppLogger.warning(_source, 'No se pudo leer: $error'),
      );
      _write('crear el monedero', _ensureWallet(uid));
    });
  }

  /// Suma puntos. No espera al servidor: sin red, Firestore guarda el cambio
  /// en el teléfono, actualiza el saldo al instante y lo sube después.
  void earn(int points) {
    final uid = _uid;
    if (uid == null || points <= 0) return;
    _write('sumar puntos', _earnPoints(uid, points));
  }

  /// Compra un filtro. Lanza [AppException] con el motivo si no se puede
  /// (las reglas están en [BuyFilterUseCase]). Funciona sin conexión, igual
  /// que [earn].
  void buy(FaceFilter filter) {
    final uid = _uid;
    if (uid == null) throw const AppException('Inicia sesión primero');
    _write('comprar ${filter.id}', _buyFilter(uid, filter, _wallet));
  }

  /// Cobra una campaña de FCM. Devuelve los puntos recibidos (0 si no aplica).
  Future<int> claimCampaign(String campaignId) async {
    final uid = _uid;
    if (uid == null) return 0;
    return _claimCampaign(uid, campaignId);
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
