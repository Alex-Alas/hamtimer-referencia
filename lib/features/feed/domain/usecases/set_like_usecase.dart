import '../repositories/feed_repository.dart';

/// Da o quita el like de un usuario en una publicación.
class SetLikeUseCase {
  const SetLikeUseCase(this._repository);

  final FeedRepository _repository;

  Future<void> call({required String postId, required String uid, required bool liked}) =>
      _repository.setLike(postId: postId, uid: uid, liked: liked);
}
