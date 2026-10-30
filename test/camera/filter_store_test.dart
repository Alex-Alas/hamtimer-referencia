import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/models/face_filter.dart';
import 'package:hamtimer/widgets/camera/filter_store.dart';

void main() {
  testWidgets('la tienda deja usar los filtros propios y pide comprar los demás', (tester) async {
    FaceFilter? selected;
    FaceFilter? toBuy;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterStore(
            filters: FaceFilter.catalog.take(2).toList(), // hámster (gratis) y lentes (30)
            points: 20,
            isOwned: (filter) => filter.isFree,
            selectedId: 'hamster',
            onSelect: (filter) => selected = filter,
            onBuy: (filter) => toBuy = filter,
          ),
        ),
      ),
    );

    expect(find.text('Gratis'), findsOneWidget);
    expect(find.text('30 pts'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    await tester.tap(find.text('Lentes cool'));
    expect(toBuy?.id, 'cool');
    await tester.tap(find.text('Hámster'));
    expect(selected?.id, 'hamster');
  });
}
