import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_labels.dart';
import '../common/labels.dart';
import '../common/neo_box.dart';
import '../common/neo_button.dart';
import '../common/pomodoro_dots.dart';
import '../../models/task.dart';
import '../common/task_visuals.dart';

/// Tarjeta de una tarea en la lista: check para completarla, título, badges
/// de prioridad / categoría / vencimiento y avance de Pomodoros.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.now,
    required this.onToggleCompleted,
    required this.onDelete,
  });

  final Task task;
  final DateTime now;
  final VoidCallback onToggleCompleted;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isOverdue = !task.isCompleted && task.dueAt.isBefore(now);

    return NeoBox(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          NeoButton(
            onPressed: onToggleCompleted,
            small: true,
            selected: task.isCompleted,
            width: 32,
            height: 32,
            padding: EdgeInsets.zero,
            semanticLabel: task.isCompleted
                ? 'Marcar "${task.title}" como pendiente'
                : 'Completar "${task.title}"',
            child: Icon(
              Icons.check,
              size: 18,
              color: task.isCompleted
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? AppColors.onSurfaceVariant : null,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InfoBadge(label: task.priority.badgeLabel, color: task.priority.color),
                    InfoBadge(
                      label: task.category.label,
                      icon: task.category.icon,
                      color: AppColors.secondary,
                    ),
                    InfoBadge(
                      label: DateLabels.relativeDue(task.dueAt, now),
                      icon: Icons.schedule,
                      color: isOverdue ? AppColors.error : AppColors.onSurfaceVariant,
                      inset: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PomodoroDots(completed: task.completedPomodoros, estimated: task.estimatedPomodoros),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Borrar "${task.title}"',
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
