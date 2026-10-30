import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Texto rojo pequeño debajo de un campo con error.
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 14, color: AppColors.error),
          const SizedBox(width: 4),
          Expanded(
            child: Text(message!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
