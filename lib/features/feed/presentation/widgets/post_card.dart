import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/post.dart';
import '../../../../core/widgets/neo_box.dart';
import 'info_bar.dart';
import 'post_image.dart';

/// Tarjeta de una publicación del feed: la foto y su barra de información.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.isLiked,
    required this.now,
    required this.onLike,
  });

  final Post post;
  final bool isLiked;
  final DateTime now;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return NeoBox(
      radius: AppRadius.lg,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PostImage(url: post.imageUrl, onDoubleTap: onLike),
            InfoBar(post: post, isLiked: isLiked, now: now, onLike: onLike),
          ],
        ),
      ),
    );
  }
}
