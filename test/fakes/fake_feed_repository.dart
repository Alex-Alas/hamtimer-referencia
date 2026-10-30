import 'dart:async';
import 'dart:typed_data';

import 'package:hamtimer/models/post.dart';
import 'package:hamtimer/repositories/feed_repository.dart';

/// Feed en memoria. Con [failLikes] el like falla, para probar la reversión.
class FakeFeedRepository implements FeedRepository {
  FakeFeedRepository(this.posts);

  final List<Post> posts;
  final _controller = StreamController<List<Post>>.broadcast();
  final List<({String uid, String authorName, String filterId})> published = [];
  bool failLikes = false;

  @override
  Stream<List<Post>> watchLatest({int limit = 30}) async* {
    yield List.of(posts);
    yield* _controller.stream;
  }

  @override
  Future<void> publish({
    required String uid,
    required String authorName,
    required Uint8List pngBytes,
    required String filterId,
  }) async {
    published.add((uid: uid, authorName: authorName, filterId: filterId));
  }

  @override
  Future<void> setLike({required String postId, required String uid, required bool liked}) async {
    if (failLikes) throw Exception('Sin permiso');
  }
}
