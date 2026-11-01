import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_box.dart';

/// Dial circular del temporizador: anillo de progreso sobre una pista hundida
/// y, al centro, el tiempo restante en un núcleo en relieve.
class PomodoroTimer extends StatelessWidget {
  const PomodoroTimer({
    super.key,
    required this.remaining,
    required this.progress,
    required this.caption,
  });

  final Duration remaining;

  /// 0 = recién empieza, 1 = terminó.
  final double progress;
  final String caption;

  static const double _size = 256;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const NeoBox(circle: true, width: _size, height: _size),
          const NeoBox(style: NeoStyle.inset, circle: true, width: _size - 32, height: _size - 32),
          CustomPaint(
            size: const Size.square(_size),
            painter: _RingPainter(progress: progress.clamp(0, 1)),
          ),
          NeoBox(
            circle: true,
            width: 176,
            height: 176,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _format(remaining),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 14, color: AppColors.primary),
                    const SizedBox(width: 2),
                    Text(
                      caption,
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// mm:ss, redondeando hacia arriba para que nunca se vea "00:00" antes de
  /// que la etapa realmente termine.
  static String _format(Duration value) {
    final totalSeconds = (value.inMilliseconds / 1000).ceil();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const radius = 110.0;
    const stroke = 7.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.outlineVariant.withValues(alpha: 0.4),
    );

    // El arco arranca a las 12 en punto (-90°) y avanza en sentido horario.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => progress != oldDelegate.progress;
}
