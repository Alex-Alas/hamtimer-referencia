import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/core/errors/app_exception.dart';
import 'package:hamtimer/features/auth/domain/entities/app_user.dart';
import 'package:hamtimer/features/feed/presentation/providers/feed_provider.dart';

import '../fakes/fake_feed_repository.dart';

void main() {
  test('publicar exige sesión y manda autor y filtro al repositorio', () async {
    final repository = FakeFeedRepository([]);
    final feed = FeedProvider(repository);
    final png = Uint8List.fromList([1, 2, 3]);

    await expectLater(
      feed.publish(pngBytes: png, filterId: 'star'),
      throwsA(isA<AppException>()),
    );

    feed.setUser(const AppUser(uid: 'uid-9', email: 'arm@esen.edu.sv', displayName: 'Armando'));
    await feed.publish(pngBytes: png, filterId: 'star');
    expect(repository.published.single, (uid: 'uid-9', authorName: 'Armando', filterId: 'star'));
    expect(feed.isPublishing, isFalse);
    feed.dispose();
  });
}
