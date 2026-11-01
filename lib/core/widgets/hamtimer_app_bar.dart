import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'neo_button.dart';

/// Barra superior compartida: botón a la izquierda, título (con subtítulo
/// opcional) y acciones a la derecha, todo sobre la superficie neomórfica.
class HamtimerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HamtimerAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.centerTitle = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleBlock = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        if (subtitle != null)
          Text(subtitle!, style: textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            ?leading,
            if (centerTitle)
              Expanded(child: Center(child: titleBlock))
            else ...[
              const SizedBox(width: 12),
              Expanded(child: titleBlock),
            ],
            for (final action in actions) ...[const SizedBox(width: 8), action],
          ],
        ),
      ),
    );
  }
}

/// Botón cuadrado de ícono usado en la barra superior.
class AppBarIconButton extends StatelessWidget {
  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color = AppColors.onSurfaceVariant,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: NeoButton(
        onPressed: onPressed,
        small: true,
        width: 40,
        height: 40,
        padding: EdgeInsets.zero,
        semanticLabel: tooltip,
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
