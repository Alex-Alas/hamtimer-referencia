import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_button.dart';

/// Botón redondo para tomar la foto.
class CameraButton extends StatelessWidget {
  const CameraButton({super.key, required this.onPressed, this.isBusy = false});

  final VoidCallback? onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return NeoButton(
      onPressed: isBusy ? null : onPressed,
      circle: true,
      width: 72,
      height: 72,
      padding: EdgeInsets.zero,
      semanticLabel: 'Tomar foto',
      child: isBusy
          ? const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3))
          : Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
              child: const Icon(Icons.camera_alt, color: AppColors.onPrimary),
            ),
    );
  }
}
