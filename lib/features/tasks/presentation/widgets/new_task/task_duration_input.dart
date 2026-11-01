import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/duration_estimate.dart';
import '../../../../../core/widgets/neo_box.dart';
import '../../../../../core/widgets/neo_button.dart';

/// "Duración estimada": contador de Pomodoros con − / + y el botón
/// "Estimar con IA", que pide a Gemini una sugerencia según el historial.
class TaskDurationInput extends StatelessWidget {
  const TaskDurationInput({
    super.key,
    required this.value,
    required this.focusMinutes,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEstimate,
    required this.isEstimating,
    this.estimate,
    this.estimateError,
  });

  final int value;
  final int focusMinutes;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback onEstimate;
  final bool isEstimating;
  final DurationEstimate? estimate;
  final String? estimateError;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NeoBox(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const NeoBox(
                style: NeoStyle.insetSmall,
                width: 40,
                height: 40,
                child: Icon(Icons.timer_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value ${value == 1 ? 'Pomodoro' : 'Pomodoros'}',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$focusMinutes min de enfoque',
                      style: textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _StepButton(icon: Icons.remove, label: 'Quitar un Pomodoro', onPressed: onDecrement),
              SizedBox(
                width: 28,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
              _StepButton(icon: Icons.add, label: 'Agregar un Pomodoro', onPressed: onIncrement),
            ],
          ),
        ),
        const SizedBox(height: 12),
        NeoButton(
          onPressed: isEstimating ? null : onEstimate,
          small: true,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          semanticLabel: 'Estimar duración con IA',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEstimating)
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.auto_awesome, size: 18, color: AppColors.tertiary),
              const SizedBox(width: 8),
              Text(
                isEstimating ? 'Estimando…' : 'Estimar con IA',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.tertiary),
              ),
            ],
          ),
        ),
        if (estimateError != null)
          _EstimateNote(icon: Icons.info_outline, color: AppColors.error, text: estimateError!)
        else if (estimate != null)
          _EstimateNote(
            icon: estimate!.source == EstimateSource.ai ? Icons.auto_awesome : Icons.history,
            color: estimate!.source == EstimateSource.ai
                ? AppColors.tertiary
                : AppColors.onSurfaceVariant,
            text: estimate!.source == EstimateSource.ai
                ? 'Gemini sugiere ${estimate!.pomodoros}: ${estimate!.reason}'
                : 'Sin IA disponible. ${estimate!.reason}: ${estimate!.pomodoros}',
          ),
      ],
    );
  }
}

class _EstimateNote extends StatelessWidget {
  const _EstimateNote({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return NeoButton(
      onPressed: onPressed,
      small: true,
      width: 32,
      height: 32,
      radius: AppRadius.sm,
      padding: EdgeInsets.zero,
      semanticLabel: label,
      child: Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
    );
  }
}
