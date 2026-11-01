import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/neo_box.dart';
import '../../../domain/entities/today_progress.dart';

/// Banner superior "Avance del día": fracción, porcentaje y barra de progreso.
class DailyProgressBanner extends StatelessWidget {
  const DailyProgressBanner({super.key, required this.progress});

  final TodayProgress progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return NeoBox(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avance del día',
                      style: textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${progress.completed}/${progress.total}',
                          style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'tareas hechas',
                          style: textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              NeoBox(
                style: NeoStyle.insetSmall,
                radius: AppRadius.sm,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  '${progress.percent}%',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProgressTrack(ratio: progress.ratio),
        ],
      ),
    );
  }
}

/// Pista hundida con el relleno índigo animado.
class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    return NeoBox(
      style: NeoStyle.insetSmall,
      radius: AppRadius.pill,
      height: 10,
      padding: const EdgeInsets.all(2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          widthFactor: ratio,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
      ),
    );
  }
}
