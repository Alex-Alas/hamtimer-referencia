import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'neo_button.dart';

/// Estado vacío o de error, con una acción opcional (p. ej. "Reintentar").
class MessageState extends StatelessWidget {
  const MessageState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.outline),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            NeoButton(
              onPressed: onAction,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                actionLabel!,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
