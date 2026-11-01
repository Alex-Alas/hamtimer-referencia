import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/neo_box.dart';
import '../../../../shared/widgets/neo_button.dart';
import '../../../../shared/widgets/pomodoro_dots.dart';
import '../../../tasks/domain/entities/task.dart';

/// Tarjeta de una tarea dentro de la cola de la sesión. La activa lleva una
/// barra índigo a la izquierda y la etiqueta "Activa"; la siguiente, "Siguiente".
class SessionTask extends StatelessWidget {
  const SessionTask({
    super.key,
    required this.task,
    required this.position,
    required this.onComplete,
    required this.onRemove,
  });

  final Task task;

  /// 0 = activa, 1 = siguiente, resto = en cola.
  final int position;
  final VoidCallback onComplete;
  final VoidCallback onRemove;

  bool get _isActive => position == 0;

  @override
  Widget build(BuildContext context) {
    // Pomodoro en curso: el siguiente al último completado, sin pasar del estimado.
    final current = (task.completedPomodoros + 1).clamp(1, task.estimatedPomodoros);

    return Dismissible(
      key: ValueKey('session-${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: const Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: 20),
          child: Icon(Icons.remove_circle_outline, color: AppColors.error),
        ),
      ),
      child: NeoBox(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: _isActive ? AppColors.primary : Colors.transparent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        NeoButton(
                          onPressed: onComplete,
                          small: true,
                          width: 26,
                          height: 26,
                          radius: AppRadius.sm,
                          padding: EdgeInsets.zero,
                          semanticLabel: 'Completar "${task.title}"',
                          child: Icon(
                            Icons.circle_outlined,
                            size: 14,
                            color: _isActive ? AppColors.primary : AppColors.outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _isActive ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  _PositionTag(position: position),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Pomodoro $current/${task.estimatedPomodoros}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const Spacer(),
                                  PomodoroDots(
                                    completed: task.completedPomodoros,
                                    estimated: task.estimatedPomodoros,
                                    showCount: false,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionTag extends StatelessWidget {
  const _PositionTag({required this.position});

  final int position;

  @override
  Widget build(BuildContext context) {
    if (position == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primaryFixed,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Activa',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.onPrimaryFixed,
          ),
        ),
      );
    }
    return Text(
      position == 1 ? 'Siguiente' : 'En cola',
      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
    );
  }
}
