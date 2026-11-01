import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/features/camera/domain/entities/face_filter.dart';
import 'package:hamtimer/features/camera/domain/entities/wallet.dart';

void main() {
  test('reglas de puntos y catálogo de filtros', () {
    expect(PointRules.forFocusBlock(completedTask: false), 10);
    expect(PointRules.forFocusBlock(completedTask: true), 35);

    // Hay un filtro gratis para probar la cámara desde el inicio.
    expect(FaceFilter.catalog.where((f) => f.isFree), hasLength(1));
    // Los ids no se repiten (se guardan en Firestore).
    final ids = FaceFilter.catalog.map((f) => f.id);
    expect(ids.toSet(), hasLength(ids.length));
    // Un id desconocido no rompe la app.
    expect(FaceFilter.byId('no-existe').id, 'hamster');
  });
}
