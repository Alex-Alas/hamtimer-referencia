import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../../../shared/widgets/neo_box.dart';

/// Aviso de que la lista viene de SQLite porque no hubo red. Se puede seguir
/// creando y completando tareas: los cambios se envían al volver la conexión.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.pendingSync, required this.onRetry});

  final int pendingSync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return NeoBox(
      style: NeoStyle.insetSmall,
      radius: AppRadius.md,
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 18, color: AppColors.reward),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pendingSync == 0
                  ? 'Sin conexión: tus cambios se guardan en el teléfono'
                  : 'Sin conexión: $pendingSync cambio(s) se enviarán al volver la red',
              style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
