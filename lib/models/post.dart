/// Una foto publicada en el feed.
class Post {
  const Post({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.imageUrl,
    required this.storagePath,
    required this.filterId,
    required this.likedBy,
    required this.createdAt,
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String imageUrl;
  final String storagePath;
  final String filterId;

  /// UIDs de quienes dieron like. El contador es su tamaño.
  final Set<String> likedBy;
  final DateTime createdAt;

  int get likes => likedBy.length;

  bool isLikedBy(String uid) => likedBy.contains(uid);

  /// Copia con el like de [uid] puesto o quitado.
  Post copyWithLike(String uid, {required bool liked}) => Post(
    id: id,
    authorUid: authorUid,
    authorName: authorName,
    imageUrl: imageUrl,
    storagePath: storagePath,
    filterId: filterId,
    likedBy: liked ? {...likedBy, uid} : ({...likedBy}..remove(uid)),
    createdAt: createdAt,
  );
}
