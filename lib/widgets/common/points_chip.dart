import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'neo_box.dart';

/// Píldora con los puntos del usuario. La usan el Dashboard y la Cámara.
class PointsChip extends StatelessWidget {
  const PointsChip({super.key, required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return NeoBox(
      style: NeoStyle.raisedSmall,
      radius: AppRadius.pill,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 18, color: AppColors.reward),
          const SizedBox(width: 4),
          Text(
            '$points pts',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}
