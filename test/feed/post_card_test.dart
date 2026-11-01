import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/features/feed/domain/entities/post.dart';
import 'package:hamtimer/features/feed/presentation/widgets/info_bar.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('la barra muestra autor, filtro y likes, y el corazón da like', (tester) async {
    await initializeDateFormatting('es');
    var likes = 0;
    final post = Post(
      id: 'p1',
      authorUid: 'otro',
      authorName: 'Nehemías',
      imageUrl: '',
      storagePath: '',
      filterId: 'crown',
      likedBy: const {'a', 'b'},
      createdAt: DateTime(2026, 11, 1, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InfoBar(
            post: post,
            isLiked: false,
            now: DateTime(2026, 11, 1, 10, 5),
            onLike: () => likes++,
          ),
        ),
      ),
    );

    expect(find.text('Nehemías'), findsOneWidget);
    expect(find.text('hace 5 min · 👑 Corona'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    expect(likes, 1);
  });
}
