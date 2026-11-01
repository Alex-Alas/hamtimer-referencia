import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/neo_box.dart';
import '../../../../shared/widgets/neo_button.dart';

/// Opciones del pop-up "¡Sesión completada!" (fin de un bloque de enfoque).
enum FocusFinishedChoice { startBreak, skipBreak, extendFocus }

/// Opciones del pop-up "Se acabó el descanso".
enum BreakFinishedChoice { startNextFocus, extendBreak, endSession }

/// Los pop-ups solo devuelven la opción elegida; quien los abre decide qué
/// hacer con ella. Así no dependen del temporizador y son fáciles de reutilizar.
abstract final class PomodoroDialogs {
  static Future<FocusFinishedChoice?> showFocusFinished(
    BuildContext context, {
    required String breakLabel,
    required String extensionLabel,
    int pointsEarned = 0,
  }) {
    return showDialog<FocusFinishedChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PomodoroDialog<FocusFinishedChoice>(
        icon: Icons.check_circle,
        title: '¡Sesión completada!',
        subtitle: pointsEarned > 0 ? '+$pointsEarned puntos para tus filtros' : null,
        showClose: true,
        actions: [
          _DialogAction(
            FocusFinishedChoice.startBreak,
            'Iniciar $breakLabel',
            Icons.coffee,
            primary: true,
          ),
          const _DialogAction(
            FocusFinishedChoice.skipBreak,
            'Saltar descanso y continuar',
            Icons.fast_forward,
          ),
          _DialogAction(
            FocusFinishedChoice.extendFocus,
            'Extender sesión ($extensionLabel)',
            Icons.more_time,
          ),
        ],
      ),
    );
  }

  static Future<BreakFinishedChoice?> showBreakFinished(
    BuildContext context, {
    required String focusLabel,
    required String extensionLabel,
  }) {
    return showDialog<BreakFinishedChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PomodoroDialog<BreakFinishedChoice>(
        icon: Icons.energy_savings_leaf,
        title: 'Se acabó el descanso',
        actions: [
          _DialogAction(
            BreakFinishedChoice.startNextFocus,
            'Iniciar siguiente sprint ($focusLabel)',
            Icons.play_arrow,
            primary: true,
          ),
          _DialogAction(BreakFinishedChoice.extendBreak, 'Tomar $extensionLabel más', Icons.snooze),
          const _DialogAction(
            BreakFinishedChoice.endSession,
            'Terminar sesión por hoy',
            Icons.power_settings_new,
          ),
        ],
      ),
    );
  }
}

class _DialogAction<T> {
  const _DialogAction(this.value, this.label, this.icon, {this.primary = false});

  final T value;
  final String label;
  final IconData icon;
  final bool primary;
}

/// Tarjeta modal neomórfica común a ambos pop-ups.
class _PomodoroDialog<T> extends StatelessWidget {
  const _PomodoroDialog({
    required this.icon,
    required this.title,
    required this.actions,
    this.subtitle,
    this.showClose = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<_DialogAction<T>> actions;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      child: NeoBox(
        radius: AppRadius.xl,
        padding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                NeoBox(
                  circle: true,
                  width: 72,
                  height: 72,
                  child: Center(
                    child: NeoBox(
                      style: NeoStyle.inset,
                      circle: true,
                      width: 54,
                      height: 54,
                      child: Icon(icon, color: AppColors.primary, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, size: 18, color: AppColors.reward),
                      const SizedBox(width: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.reward,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                for (final action in actions) ...[
                  _ActionButton(
                    action: action,
                    onPressed: () => Navigator.of(context).pop(action.value),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
            if (showClose)
              Positioned(
                top: 0,
                right: 0,
                child: NeoButton(
                  onPressed: () => Navigator.of(context).pop(),
                  small: true,
                  circle: true,
                  width: 32,
                  height: 32,
                  padding: EdgeInsets.zero,
                  semanticLabel: 'Cerrar',
                  child: const Icon(Icons.close, size: 16, color: AppColors.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton<T> extends StatelessWidget {
  const _ActionButton({required this.action, required this.onPressed});

  final _DialogAction<T> action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = action.primary ? AppColors.primary : AppColors.onSurface;
    return NeoButton(
      onPressed: onPressed,
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: action.primary ? 15 : 12, horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            action.icon,
            size: 18,
            color: action.primary ? AppColors.primary : AppColors.secondary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              action.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: action.primary ? 14 : 12,
                fontWeight: action.primary ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
