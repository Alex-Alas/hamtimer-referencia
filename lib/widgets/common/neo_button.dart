import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'neo_box.dart';

/// Botón táctil neomórfico: en reposo sobresale y, al presionarlo, se "hunde"
/// (pasa a estilo inset), imitando el `active:neo-inset` del diseño.
class NeoButton extends StatefulWidget {
  const NeoButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.radius = AppRadius.md,
    this.padding = const EdgeInsets.all(10),
    this.circle = false,
    this.selected = false,
    this.small = false,
    this.width,
    this.height,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool circle;

  /// Un botón seleccionado (p. ej. el filtro activo) se muestra hundido.
  final bool selected;
  final bool small;
  final double? width;
  final double? height;
  final String? semanticLabel;

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final sunken = _pressed || widget.selected;
    final style = sunken
        ? (widget.small ? NeoStyle.insetSmall : NeoStyle.inset)
        : (widget.small ? NeoStyle.raisedSmall : NeoStyle.raised);

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: Opacity(
            opacity: widget.onPressed == null ? 0.5 : 1,
            child: NeoBox(
              style: style,
              radius: widget.radius,
              circle: widget.circle,
              padding: widget.padding,
              width: widget.width,
              height: widget.height,
              child: Center(widthFactor: 1, heightFactor: 1, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de acción principal (relleno índigo con brillo), como "Crear actividad".
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          elevation: 6,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Text(label),
                ],
              ),
      ),
    );
  }
}
