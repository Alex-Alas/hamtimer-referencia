import 'dart:async';

import 'package:hamtimer/features/camera/domain/entities/face_filter.dart';
import 'package:hamtimer/features/camera/domain/entities/wallet.dart';
import 'package:hamtimer/features/camera/domain/repositories/wallet_repository.dart';

/// Monedero en memoria que emite los cambios como lo haría Firestore.
class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository({int points = 0})
    : _wallet = Wallet(
        points: points,
        ownedFilterIds: const {},
        claimedCampaignIds: const {},
      );

  Wallet _wallet;
  final _controller = StreamController<Wallet>.broadcast();
  final List<String> boughtFilterIds = [];

  void _emit(Wallet wallet) {
    _wallet = wallet;
    _controller.add(wallet);
  }

  @override
  Stream<Wallet> watch(String uid) async* {
    yield _wallet;
    yield* _controller.stream;
  }

  @override
  Future<void> ensureExists(String uid) async {}

  @override
  Future<void> addPoints(String uid, int points) async => _emit(
    Wallet(
      points: _wallet.points + points,
      ownedFilterIds: _wallet.ownedFilterIds,
      claimedCampaignIds: _wallet.claimedCampaignIds,
    ),
  );

  @override
  Future<void> buyFilter(String uid, FaceFilter filter) async {
    boughtFilterIds.add(filter.id);
    _emit(
      Wallet(
        points: _wallet.points - filter.price,
        ownedFilterIds: {..._wallet.ownedFilterIds, filter.id},
        claimedCampaignIds: _wallet.claimedCampaignIds,
      ),
    );
  }

  @override
  Future<int> claimCampaign(String uid, String campaignId) async => 0;
}
