import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/edge_fade.dart';
import '../../../../../core/widgets/neo_button.dart';
import '../../../domain/entities/task_filter.dart';

/// Fila horizontal desplazable de chips de filtro. El chip activo se ve
/// hundido (inset) y en color primario, como en el diseño.
class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({super.key, required this.selected, required this.onSelected});

  final TaskFilter selected;
  final ValueChanged<TaskFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = TaskFilter.options;

    return EdgeFade(
      child: SizedBox(
        height: 60,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          // Margen para que las sombras neomórficas no se recorten.
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          clipBehavior: Clip.none,
          itemCount: filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = filter == selected;
            return NeoButton(
              onPressed: () => onSelected(filter),
              small: true,
              selected: isSelected,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                filter.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
