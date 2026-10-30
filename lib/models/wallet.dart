/// Monedero del usuario: puntos y filtros comprados.
///
/// Vive en Firestore (`hamtimer_users/{uid}`) para que no se pierda al borrar
/// el caché o cambiar de teléfono.
class Wallet {
  const Wallet({
    required this.points,
    required this.ownedFilterIds,
    required this.claimedCampaignIds,
  });

  static const empty = Wallet(points: 0, ownedFilterIds: {}, claimedCampaignIds: {});

  final int points;
  final Set<String> ownedFilterIds;
  final Set<String> claimedCampaignIds;

  bool owns(String filterId) => ownedFilterIds.contains(filterId);

  bool canAfford(int price) => points >= price;
}

/// Reglas de puntos del juego.
abstract final class PointRules {
  static const int perPomodoro = 10;
  static const int perCompletedTask = 25;

  /// Puntos por un bloque de enfoque terminado: base más el bono si con ese
  /// bloque la tarea quedó completada.
  static int forFocusBlock({required bool completedTask}) =>
      perPomodoro + (completedTask ? perCompletedTask : 0);
}
