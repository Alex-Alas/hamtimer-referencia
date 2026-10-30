import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../common/neo_button.dart';

/// Vista previa de la foto tomada. Devuelve `true` si el usuario quiere
/// publicarla. Sin conexión, "Publicar" queda desactivado: el feed es lo
/// único de la app que necesita internet.
class CapturePreviewSheet extends StatelessWidget {
  const CapturePreviewSheet({super.key, required this.pngBytes, required this.isOnline});

  final Uint8List pngBytes;
  final bool isOnline;

  static Future<bool?> show(
    BuildContext context, {
    required Uint8List pngBytes,
    required bool isOnline,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => CapturePreviewSheet(pngBytes: pngBytes, isOnline: isOnline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.6;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.memory(pngBytes, fit: BoxFit.contain),
              ),
            ),
            if (!isOnline) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.cloud_off_outlined, size: 16, color: AppColors.reward),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sin conexión: para publicar en el feed necesitas internet',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: NeoButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: const Text(
                      'Descartar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: isOnline ? () => Navigator.of(context).pop(true) : null,
                    icon: const Icon(Icons.send),
                    label: const Text('Publicar en el feed'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
