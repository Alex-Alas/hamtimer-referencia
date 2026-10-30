import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../common/neo_box.dart';

/// Logo y saludo de las pantallas de acceso.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        const NeoBox(
          circle: true,
          width: 96,
          height: 96,
          child: Center(child: Text('🐹', style: TextStyle(fontSize: 48))),
        ),
        const SizedBox(height: 20),
        Text(title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
