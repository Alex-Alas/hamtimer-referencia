import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/features/auth/domain/entities/app_user.dart';
import 'package:hamtimer/features/feed/domain/entities/post.dart';
import 'package:hamtimer/features/feed/presentation/providers/feed_provider.dart';

import '../fakes/fake_feed_repository.dart';

Post _post() => Post(
  id: 'p1',
  authorUid: 'otro',
  authorName: 'Gisi',
  imageUrl: 'https://example.com/p1.png',
  storagePath: 'hamtimer/posts/otro/1.png',
  filterId: 'crown',
  likedBy: const {},
  createdAt: DateTime(2026, 10, 30),
);

void main() {
  test('el like es optimista y se revierte si Firestore falla', () async {
    final repository = FakeFeedRepository([_post()]);
    final feed = FeedProvider(repository)
      ..setUser(const AppUser(uid: 'uid-1', email: 'a@esen.edu.sv', displayName: 'Armando'));
    await Future<void>.delayed(Duration.zero);
    expect(feed.posts.single.likes, 0);

    await feed.toggleLike(feed.posts.single);
    expect(feed.posts.single.isLikedBy('uid-1'), isTrue);

    repository.failLikes = true;
    await expectLater(feed.toggleLike(feed.posts.single), throwsException);
    expect(feed.posts.single.isLikedBy('uid-1'), isTrue); // volvió al estado anterior
    feed.dispose();
  });
}
