import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

/// Foto de una publicación, descargada de Firebase Storage, con estados de
/// carga y de error. Un doble toque da like, como en otras redes.
class PostImage extends StatelessWidget {
  const PostImage({super.key, required this.url, required this.onDoubleTap});

  final String url;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ColoredBox(
          color: AppColors.outlineVariant,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final total = progress.expectedTotalBytes;
              return Center(
                child: CircularProgressIndicator(
                  value: total == null ? null : progress.cumulativeBytesLoaded / total,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image_outlined, size: 40, color: AppColors.outline),
            ),
          ),
        ),
      ),
    );
  }
}
