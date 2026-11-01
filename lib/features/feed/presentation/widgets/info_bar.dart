import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../camera/domain/entities/face_filter.dart';
import '../../domain/entities/post.dart';

/// Barra de una publicación: autor, hace cuánto, filtro usado y el botón de
/// like con su contador.
class InfoBar extends StatelessWidget {
  const InfoBar({
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
    final filter = FaceFilter.byId(post.filterId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryFixed,
            child: Text(
              post.authorName.isEmpty ? '?' : post.authorName[0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimaryFixed,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${DateLabels.timeAgo(post.createdAt, now)} · ${filter.emoji} ${filter.name}',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onLike,
            tooltip: isLiked ? 'Quitar like' : 'Dar like',
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? AppColors.like : AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            '${post.likes}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
