import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

/// Escucha el monedero del usuario (puntos y filtros comprados) en vivo.
class WatchWalletUseCase {
  const WatchWalletUseCase(this._repository);

  final WalletRepository _repository;

  Stream<Wallet> call(String uid) => _repository.watch(uid);
}
