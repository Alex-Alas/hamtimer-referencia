import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Indicador "●●○ 2/3": un punto por Pomodoro estimado, relleno si ya se hizo.
class PomodoroDots extends StatelessWidget {
  const PomodoroDots({
    super.key,
    required this.completed,
    required this.estimated,
    this.showCount = true,
  });

  final int completed;
  final int estimated;
  final bool showCount;

  /// A partir de este número se muestra solo el conteo para no desbordar.
  static const int _maxDots = 6;

  @override
  Widget build(BuildContext context) {
    final done = completed.clamp(0, estimated);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        if (estimated <= _maxDots)
          for (var i = 0; i < estimated; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < done ? AppColors.primary : AppColors.outlineVariant,
              ),
            ),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            '$done/$estimated',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}
