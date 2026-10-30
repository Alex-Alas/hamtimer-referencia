import '../models/face_filter.dart';
import '../models/wallet.dart';

/// Contrato del monedero: puntos, filtros comprados y campañas cobradas.
abstract interface class WalletRepository {
  /// Emite el monedero cada vez que cambia en el servidor.
  Stream<Wallet> watch(String uid);

  /// Crea el monedero en cero si el usuario aún no tiene uno.
  Future<void> ensureExists(String uid);

  /// Suma puntos (Pomodoro terminado, tarea completada).
  Future<void> addPoints(String uid, int points);

  /// Compra un filtro. Lanza `AppException` si no alcanzan los puntos o si ya
  /// lo tenía.
  Future<void> buyFilter(String uid, FaceFilter filter);

  /// Cobra una campaña de puntos enviada por FCM. Devuelve los puntos
  /// sumados, o 0 si ya se había cobrado o no existe.
  Future<int> claimCampaign(String uid, String campaignId);
}
