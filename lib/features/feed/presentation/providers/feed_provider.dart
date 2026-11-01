import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/feed_repository.dart';

/// Estado global del feed: las publicaciones en vivo y la publicación en
/// curso. La Cámara publica y el Feed muestra.
class FeedProvider extends ChangeNotifier {
  FeedProvider(this._repository);

  final FeedRepository _repository;
  StreamSubscription<List<Post>>? _subscription;

  AppUser? _user;
  List<Post> _posts = const [];
  bool _isLoading = true;
  bool _isPublishing = false;
  String? _errorMessage;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isPublishing => _isPublishing;
  String? get errorMessage => _errorMessage;
  String? get currentUid => _user?.uid;

  /// Lo llama el `ChangeNotifierProxyProvider` cuando cambia la sesión.
  /// Las reglas de Firestore exigen sesión, por eso se escucha solo con usuario.
  void setUser(AppUser? user) {
    if (user?.uid == _user?.uid) {
      _user = user;
      return;
    }
    _user = user;
    _subscription?.cancel();
    _subscription = null;
    _posts = const [];
    if (user == null) return;
    _listen();
  }

  /// Vuelve a escuchar el feed tras un error (botón "Reintentar").
  void retry() {
    if (_user == null) return;
    _subscription?.cancel();
    _errorMessage = null;
    _listen();
    notifyListeners();
  }

  void _listen() {
    _isLoading = true;
    _subscription = _repository.watchLatest().listen(
      (posts) {
        _posts = posts;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = 'No se pudo cargar el feed';
        notifyListeners();
      },
    );
  }

  /// Sube la foto con filtro. Lanza [AppException] si falla.
  Future<void> publish({required Uint8List pngBytes, required String filterId}) async {
    final user = _user;
    if (user == null) throw const AppException('Inicia sesión primero');
    _isPublishing = true;
    notifyListeners();
    try {
      await _repository.publish(
        uid: user.uid,
        authorName: user.displayName,
        pngBytes: pngBytes,
        filterId: filterId,
      );
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  /// Like optimista: cambia al instante y el stream de Firestore confirma.
  /// Si falla, se revierte y se relanza el error.
  Future<void> toggleLike(Post post) async {
    final uid = _user?.uid;
    if (uid == null) return;
    final liked = !post.isLikedBy(uid);
    final previous = _posts;
    _posts = [
      for (final p in _posts)
        if (p.id == post.id) p.copyWithLike(uid, liked: liked) else p,
    ];
    notifyListeners();
    try {
      await _repository.setLike(postId: post.id, uid: uid, liked: liked);
    } on Exception {
      _posts = previous;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
