import '../repositories/wallet_repository.dart';

/// Cobra una campaña de puntos enviada por FCM. Devuelve los puntos sumados, o 0
/// si ya se había cobrado o no existe.
class ClaimCampaignUseCase {
  const ClaimCampaignUseCase(this._repository);

  final WalletRepository _repository;

  Future<int> call(String uid, String campaignId) => _repository.claimCampaign(uid, campaignId);
}
