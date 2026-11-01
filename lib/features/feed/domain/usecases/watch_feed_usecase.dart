import '../entities/post.dart';
import '../repositories/feed_repository.dart';

/// Publicaciones más recientes del feed, en vivo.
class WatchFeedUseCase {
  const WatchFeedUseCase(this._repository);

  final FeedRepository _repository;

  Stream<List<Post>> call({int limit = 30}) => _repository.watchLatest(limit: limit);
}
