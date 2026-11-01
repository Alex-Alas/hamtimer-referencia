import '../../../../shared/errors/app_exception.dart';
import '../entities/face_filter.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

/// Compra un filtro con puntos. Aquí viven las reglas de negocio de la compra:
/// no se compra un filtro que ya se tiene ni uno que no alcanza.
class BuyFilterUseCase {
  const BuyFilterUseCase(this._repository);

  final WalletRepository _repository;

  /// Lanza [AppException] con el motivo si no se puede comprar.
  Future<void> call(String uid, FaceFilter filter, Wallet wallet) {
    if (filter.isFree || wallet.owns(filter.id)) throw const AppException('Ya tienes este filtro');
    if (!wallet.canAfford(filter.price)) throw const AppException('No te alcanzan los puntos');
    return _repository.buyFilter(uid, filter);
  }
}
