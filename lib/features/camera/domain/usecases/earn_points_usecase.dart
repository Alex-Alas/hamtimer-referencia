import '../repositories/wallet_repository.dart';

/// Suma puntos al monedero (Pomodoro terminado, tarea completada). Ignora
/// cantidades de cero o negativas.
class EarnPointsUseCase {
  const EarnPointsUseCase(this._repository);

  final WalletRepository _repository;

  Future<void> call(String uid, int points) async {
    if (points <= 0) return;
    await _repository.addPoints(uid, points);
  }
}
