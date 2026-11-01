/// Parte de la cara donde se dibuja un filtro.
enum FilterAnchor {
  /// Sobre los ojos (lentes, antifaz).
  eyes,

  /// Encima de la cabeza (corona, orejas, gorro).
  head,

  /// Sobre la boca (bigote, lengua).
  mouth,
}

/// Un filtro facial de la tienda.
///
/// Se dibuja con un emoji para no depender de imágenes: así agregar un filtro
/// nuevo es agregar una línea al [catalog].
class FaceFilter {
  const FaceFilter({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.anchor,
    this.scale = 1,
  });

  final String id;
  final String name;
  final String emoji;
  final int price;
  final FilterAnchor anchor;

  /// Tamaño relativo al ancho de la cara (1 = mismo ancho).
  final double scale;

  bool get isFree => price == 0;

  /// Catálogo de la tienda. El primero es gratis para que todos puedan
  /// probar la cámara desde el inicio.
  static const List<FaceFilter> catalog = [
    FaceFilter(
      id: 'hamster',
      name: 'Hámster',
      emoji: '🐹',
      price: 0,
      anchor: FilterAnchor.head,
      scale: 0.7,
    ),
    FaceFilter(
      id: 'cool',
      name: 'Lentes cool',
      emoji: '🕶️',
      price: 30,
      anchor: FilterAnchor.eyes,
      scale: 0.9,
    ),
    FaceFilter(
      id: 'crown',
      name: 'Corona',
      emoji: '👑',
      price: 60,
      anchor: FilterAnchor.head,
      scale: 0.8,
    ),
    FaceFilter(
      id: 'mustache',
      name: 'Bigote',
      emoji: '🥸',
      price: 80,
      anchor: FilterAnchor.mouth,
      scale: 0.6,
    ),
    FaceFilter(
      id: 'party',
      name: 'Fiesta',
      emoji: '🥳',
      price: 100,
      anchor: FilterAnchor.head,
      scale: 0.75,
    ),
    FaceFilter(
      id: 'star',
      name: 'Estrella',
      emoji: '🌟',
      price: 150,
      anchor: FilterAnchor.eyes,
      scale: 1.1,
    ),
  ];

  static FaceFilter byId(String id) =>
      catalog.firstWhere((filter) => filter.id == id, orElse: () => catalog.first);
}
