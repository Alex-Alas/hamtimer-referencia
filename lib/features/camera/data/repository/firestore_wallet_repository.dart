import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/face_filter.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';

/// Monedero en Cloud Firestore.
///
/// Documento `hamtimer_users/{uid}`:
/// `{ points: int, ownedFilters: [id], claimedCampaigns: [id], lastSeenAt }`.
/// Campañas en `hamtimer_campaigns/{id}`: `{ points: int, title: string }`.
///
/// Sin conexión, Firestore guarda las escrituras en su caché del teléfono,
/// avisa el cambio al instante por [watch] y las sube cuando vuelve la red.
/// El `Future` de cada escritura termina solo cuando el servidor confirma.
class FirestoreWalletRepository implements WalletRepository {
  FirestoreWalletRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const usersCollection = 'hamtimer_users';
  static const campaignsCollection = 'hamtimer_campaigns';

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection(usersCollection).doc(uid);

  @override
  Stream<Wallet> watch(String uid) => _userDoc(uid).snapshots().map((snapshot) {
    final data = snapshot.data();
    if (data == null) return Wallet.empty;
    return Wallet(
      points: (data['points'] as num?)?.toInt() ?? 0,
      ownedFilterIds: _stringSet(data['ownedFilters']),
      claimedCampaignIds: _stringSet(data['claimedCampaigns']),
    );
  });

  /// Crea el documento si no existe, sin transacción para que funcione sin
  /// conexión: `increment(0)` y `arrayUnion([])` dejan 0 y `[]` si el campo
  /// no existe, y no cambian nada si ya existe.
  @override
  Future<void> ensureExists(String uid) => _userDoc(uid).set({
    'points': FieldValue.increment(0),
    'ownedFilters': FieldValue.arrayUnion(<String>[]),
    'claimedCampaigns': FieldValue.arrayUnion(<String>[]),
    'lastSeenAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  @override
  Future<void> addPoints(String uid, int points) =>
      _userDoc(uid).set({'points': FieldValue.increment(points)}, SetOptions(merge: true));

  /// Descuenta el precio y agrega el filtro en una sola escritura.
  ///
  /// No es una transacción porque las transacciones necesitan red, y comprar
  /// tiene que funcionar sin conexión. El saldo se valida en `WalletProvider`
  /// con el monedero en caché, y las reglas de Firestore rechazan un saldo
  /// negativo cuando la escritura llega al servidor.
  @override
  Future<void> buyFilter(String uid, FaceFilter filter) => _userDoc(uid).set({
    'points': FieldValue.increment(-filter.price),
    'ownedFilters': FieldValue.arrayUnion([filter.id]),
  }, SetOptions(merge: true));

  /// Las campañas llegan por FCM, o sea con red: aquí sí se usa una
  /// transacción, para que la misma campaña no se cobre dos veces.
  @override
  Future<int> claimCampaign(String uid, String campaignId) async {
    final userDoc = _userDoc(uid);
    final campaignDoc = _db.collection(campaignsCollection).doc(campaignId);
    return _db.runTransaction((tx) async {
      final campaign = (await tx.get(campaignDoc)).data();
      final user = (await tx.get(userDoc)).data() ?? const {};
      final points = (campaign?['points'] as num?)?.toInt() ?? 0;
      if (points <= 0 || _stringSet(user['claimedCampaigns']).contains(campaignId)) return 0;
      tx.update(userDoc, {
        'points': FieldValue.increment(points),
        'claimedCampaigns': FieldValue.arrayUnion([campaignId]),
      });
      return points;
    });
  }

  static Set<String> _stringSet(Object? value) =>
      value is List ? value.whereType<String>().toSet() : <String>{};
}
