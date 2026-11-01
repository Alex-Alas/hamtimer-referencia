import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'neo_box.dart';

/// Encabezado pequeño en mayúsculas para cada sección de un formulario.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Insignia compacta (prioridad, categoría, vencimiento...).
class InfoBadge extends StatelessWidget {
  const InfoBadge({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.onSurfaceVariant,
    this.inset = false,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    return NeoBox(
      style: inset ? NeoStyle.insetSmall : NeoStyle.raisedSmall,
      radius: AppRadius.sm,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
