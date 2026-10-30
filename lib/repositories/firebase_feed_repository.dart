import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/errors/app_exception.dart';
import '../core/logging/app_logger.dart';
import '../models/post.dart';
import 'feed_repository.dart';

/// Feed con Firebase Storage (la imagen) y Cloud Firestore (los datos).
///
/// - Imagen: `hamtimer/posts/{uid}/{timestamp}.png` en Storage.
/// - Documento: `hamtimer_posts/{id}` con autor, URL, filtro, `likedBy` y fecha.
class FirebaseFeedRepository implements FeedRepository {
  FirebaseFeedRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _db = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  static const postsCollection = 'hamtimer_posts';

  CollectionReference<Map<String, dynamic>> get _posts => _db.collection(postsCollection);

  @override
  Stream<List<Post>> watchLatest({int limit = 30}) => _posts
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((query) => query.docs.map(_fromDoc).toList(growable: false));

  @override
  Future<void> publish({
    required String uid,
    required String authorName,
    required Uint8List pngBytes,
    required String filterId,
  }) async {
    final path = 'hamtimer/posts/$uid/${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      final ref = _storage.ref(path);
      await ref.putData(pngBytes, SettableMetadata(contentType: 'image/png'));
      final url = await ref.getDownloadURL();
      await _posts.add({
        'authorUid': uid,
        'authorName': authorName,
        'imageUrl': url,
        'storagePath': path,
        'filterId': filterId,
        'likedBy': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stack) {
      AppLogger.error('feed', 'No se pudo publicar', error, stack);
      throw const AppException('No se pudo publicar la foto');
    }
  }

  @override
  Future<void> setLike({required String postId, required String uid, required bool liked}) {
    return _posts.doc(postId).update({
      'likedBy': liked ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
    });
  }

  Post _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    // createdAt es null por un instante, hasta que el servidor pone la hora.
    final timestamp = data['createdAt'];
    return Post(
      id: doc.id,
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Anónimo',
      imageUrl: data['imageUrl'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      filterId: data['filterId'] as String? ?? '',
      likedBy: (data['likedBy'] is List)
          ? (data['likedBy'] as List).whereType<String>().toSet()
          : <String>{},
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }
}
