import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../common/neo_button.dart';

/// Botonera del temporizador: reiniciar · iniciar/pausar · saltar etapa.
class TimerControls extends StatelessWidget {
  const TimerControls({
    super.key,
    required this.isRunning,
    required this.isBreak,
    required this.onToggle,
    required this.onReset,
    required this.onSkip,
  });

  final bool isRunning;
  final bool isBreak;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final startLabel = isBreak ? 'Iniciar descanso' : 'Iniciar enfoque';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SquareButton(icon: Icons.refresh, label: 'Reiniciar', onPressed: onReset),
        const SizedBox(width: 16),
        NeoButton(
          onPressed: onToggle,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isRunning ? Icons.pause : Icons.play_arrow, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                isRunning ? 'Pausar' : startLabel,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _SquareButton(icon: Icons.skip_next, label: 'Saltar etapa', onPressed: onSkip),
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: NeoButton(
        onPressed: onPressed,
        width: 48,
        height: 48,
        padding: EdgeInsets.zero,
        semanticLabel: label,
        child: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
