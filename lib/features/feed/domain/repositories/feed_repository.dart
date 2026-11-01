import 'dart:typed_data';

import '../entities/post.dart';

/// Contrato del feed de fotos.
abstract interface class FeedRepository {
  /// Publicaciones más recientes, en vivo.
  Stream<List<Post>> watchLatest({int limit = 30});

  /// Sube la foto (PNG) y crea la publicación.
  Future<void> publish({
    required String uid,
    required String authorName,
    required Uint8List pngBytes,
    required String filterId,
  });

  /// Da o quita el like de [uid] en la publicación.
  Future<void> setLike({required String postId, required String uid, required bool liked});
}
