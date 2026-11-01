import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/neo_button.dart';
import '../../domain/entities/face_filter.dart';

/// Tarjeta de un filtro en la tienda: emoji, nombre y, si no es tuyo, el
/// precio con un candado.
class FilterCard extends StatelessWidget {
  const FilterCard({
    super.key,
    required this.filter,
    required this.isOwned,
    required this.isSelected,
    required this.canAfford,
    required this.onTap,
  });

  final FaceFilter filter;
  final bool isOwned;
  final bool isSelected;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeoButton(
      onPressed: onTap,
      small: true,
      selected: isSelected,
      width: 92,
      radius: AppRadius.lg,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      semanticLabel: isOwned ? 'Usar ${filter.name}' : 'Comprar ${filter.name}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: isOwned ? 1 : 0.45,
            child: Text(filter.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 4),
          Text(
            filter.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          _PriceTag(filter: filter, isOwned: isOwned, canAfford: canAfford),
        ],
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.filter, required this.isOwned, required this.canAfford});

  final FaceFilter filter;
  final bool isOwned;
  final bool canAfford;

  @override
  Widget build(BuildContext context) {
    if (isOwned) {
      return Text(
        filter.isFree ? 'Gratis' : 'Tuyo',
        style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
      );
    }
    final color = canAfford ? AppColors.reward : AppColors.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 11, color: color),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '${filter.price} pts',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }
}
