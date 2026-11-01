import '../repositories/wallet_repository.dart';

/// Crea el monedero en cero si el usuario todavía no tiene uno.
class EnsureWalletUseCase {
  const EnsureWalletUseCase(this._repository);

  final WalletRepository _repository;

  Future<void> call(String uid) => _repository.ensureExists(uid);
}
