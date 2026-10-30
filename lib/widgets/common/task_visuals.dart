import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/task_category.dart';
import '../../models/task_priority.dart';

/// Decisiones visuales que dependen del modelo, centralizadas para que el
/// dashboard, el formulario y el Pomodoro pinten igual una misma categoría o
/// prioridad. Los modelos no importan Flutter; los íconos viven aquí.
extension TaskCategoryVisuals on TaskCategory {
  IconData get icon => switch (this) {
    TaskCategory.deepWork => Icons.psychology_outlined,
    TaskCategory.quickWin => Icons.bolt,
    TaskCategory.personal => Icons.person_outline,
    TaskCategory.study => Icons.menu_book_outlined,
    TaskCategory.meeting => Icons.groups_outlined,
  };
}

extension TaskPriorityVisuals on TaskPriority {
  Color get color => switch (this) {
    TaskPriority.high => AppColors.tertiary,
    TaskPriority.medium => AppColors.primary,
    TaskPriority.low => AppColors.secondary,
  };

  String get badgeLabel => 'Prioridad ${label.toLowerCase()}';
}
