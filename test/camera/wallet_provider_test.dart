import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/core/errors/app_exception.dart';
import 'package:hamtimer/features/camera/domain/entities/face_filter.dart';
import 'package:hamtimer/features/camera/presentation/providers/wallet_provider.dart';

import '../fakes/fake_wallet_repository.dart';

void main() {
  test('solo se compra un filtro si alcanzan los puntos', () async {
    final repository = FakeWalletRepository(points: 40);
    final wallet = WalletProvider(repository)..setUser('uid-1');
    await Future<void>.delayed(Duration.zero); // microtask de setUser + stream
    final crown = FaceFilter.byId('crown'); // 60 pts
    final cool = FaceFilter.byId('cool'); // 30 pts

    expect(() => wallet.buy(crown), throwsA(isA<AppException>()));
    expect(repository.boughtFilterIds, isEmpty);

    wallet.buy(cool);
    await Future<void>.delayed(Duration.zero);
    expect(wallet.points, 10);
    expect(wallet.owns(cool), isTrue);
    expect(wallet.availableFilters.map((f) => f.id), ['hamster', 'cool']);
    wallet.dispose();
  });
}
