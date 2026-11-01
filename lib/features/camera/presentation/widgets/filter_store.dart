import 'package:flutter/material.dart';

import '../../../../core/widgets/edge_fade.dart';
import '../../domain/entities/face_filter.dart';
import 'filter_card.dart';

/// Tienda de filtros: fila desplazable con todo el catálogo. Los filtros
/// propios se eligen con un toque; los bloqueados piden comprarse.
///
/// No conoce el monedero: recibe los datos y avisa con [onSelect] y [onBuy],
/// así se puede probar sin Firebase.
class FilterStore extends StatelessWidget {
  const FilterStore({
    super.key,
    required this.filters,
    required this.points,
    required this.isOwned,
    required this.selectedId,
    required this.onSelect,
    required this.onBuy,
  });

  final List<FaceFilter> filters;
  final int points;
  final bool Function(FaceFilter filter) isOwned;
  final String selectedId;
  final ValueChanged<FaceFilter> onSelect;
  final ValueChanged<FaceFilter> onBuy;

  @override
  Widget build(BuildContext context) {
    return EdgeFade(
      child: SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final filter = filters[index];
            final owned = isOwned(filter);
            return FilterCard(
              filter: filter,
              isOwned: owned,
              isSelected: filter.id == selectedId,
              canAfford: points >= filter.price,
              onTap: () => owned ? onSelect(filter) : onBuy(filter),
            );
          },
        ),
      ),
    );
  }
}
