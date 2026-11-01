import 'dart:typed_data';

import '../repositories/feed_repository.dart';

/// Sube la foto con filtro (PNG) y crea la publicación.
class PublishPostUseCase {
  const PublishPostUseCase(this._repository);

  final FeedRepository _repository;

  Future<void> call({
    required String uid,
    required String authorName,
    required Uint8List pngBytes,
    required String filterId,
  }) =>
      _repository.publish(uid: uid, authorName: authorName, pngBytes: pngBytes, filterId: filterId);
}
