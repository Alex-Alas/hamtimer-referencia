import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'neo_box.dart';

/// Pestañas de la barra inferior, en el orden del flujo de la app.
///
/// [screenName] es el nombre que se registra en Analytics al abrir la pestaña.
enum HomeTab {
  dashboard('Tareas', 'dashboard', Icons.check_circle_outline, Icons.check_circle),
  pomodoro('Pomodoro', 'pomodoro', Icons.timer_outlined, Icons.timer),
  newTask('Nueva', 'new_task', Icons.add_circle_outline, Icons.add_circle),
  camera('Cámara', 'camera', Icons.photo_camera_outlined, Icons.photo_camera),
  feed('Feed', 'feed', Icons.dynamic_feed_outlined, Icons.dynamic_feed);

  const HomeTab(this.label, this.screenName, this.icon, this.selectedIcon);

  final String label;
  final String screenName;
  final IconData icon;
  final IconData selectedIcon;
}

/// Barra inferior neomórfica: el destino activo se ve hundido y en índigo.
class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({super.key, required this.selected, required this.onSelected});

  final HomeTab selected;
  final ValueChanged<HomeTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Color(0x0A000000), offset: Offset(0, -4), blurRadius: 16)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final tab in HomeTab.values)
                _NavItem(tab: tab, isSelected: tab == selected, onTap: () => onSelected(tab)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.isSelected, required this.onTap});

  final HomeTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: tab.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeoBox(
                style: isSelected ? NeoStyle.insetSmall : NeoStyle.raisedSmall,
                width: 44,
                height: 36,
                child: Icon(isSelected ? tab.selectedIcon : tab.icon, size: 22, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
