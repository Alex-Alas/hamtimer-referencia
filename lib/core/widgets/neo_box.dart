import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Variantes del estilo neomórfico usadas en el diseño de Stitch.
///
/// - `raised`: la superficie "sobresale" (sombra oscura abajo-derecha y luz
///   arriba-izquierda).
/// - `inset`: la superficie está "tallada" hacia adentro; se usa para campos de
///   texto, pistas de progreso y elementos seleccionados.
enum NeoStyle { raised, raisedSmall, inset, insetSmall, flat }

/// Bloque visual base de toda la UI: una superficie con relieve neomórfico.
///
/// Flutter solo trae sombras externas, así que las sombras internas se dibujan
/// con [_InsetShadowPainter]. Encapsularlo aquí permite que ninguna pantalla
/// sepa cómo se implementa el relieve (y cambiarlo en un solo lugar).
class NeoBox extends StatelessWidget {
  const NeoBox({
    super.key,
    this.child,
    this.style = NeoStyle.raised,
    this.radius = AppRadius.md,
    this.circle = false,
    this.color = AppColors.surface,
    this.padding,
    this.width,
    this.height,
  });

  final Widget? child;
  final NeoStyle style;
  final double radius;
  final bool circle;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding ?? EdgeInsets.zero, child: child);

    if (style == NeoStyle.inset || style == NeoStyle.insetSmall) {
      return SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _InsetShadowPainter(
            color: color,
            radius: radius,
            circle: circle,
            depth: style == NeoStyle.inset ? 4 : 2,
          ),
          child: content,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
        boxShadow: _raisedShadows(style),
      ),
      child: content,
    );
  }

  static List<BoxShadow> _raisedShadows(NeoStyle style) {
    return switch (style) {
      NeoStyle.raised => const [
        BoxShadow(color: AppColors.shadowDark, offset: Offset(6, 6), blurRadius: 14),
        BoxShadow(color: AppColors.shadowLight, offset: Offset(-6, -6), blurRadius: 14),
      ],
      NeoStyle.raisedSmall => const [
        BoxShadow(color: AppColors.shadowDark, offset: Offset(3, 3), blurRadius: 8),
        BoxShadow(color: AppColors.shadowLight, offset: Offset(-3, -3), blurRadius: 8),
      ],
      _ => const [],
    };
  }
}

/// Dibuja el fondo y dos sombras internas (oscura arriba-izquierda, luz
/// abajo-derecha), equivalente al `box-shadow: inset ...` del CSS de Stitch.
class _InsetShadowPainter extends CustomPainter {
  _InsetShadowPainter({
    required this.color,
    required this.radius,
    required this.circle,
    required this.depth,
  });

  final Color color;
  final double radius;
  final bool circle;
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveRadius = circle ? size.shortestSide / 2 : radius;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(effectiveRadius));

    canvas.drawRRect(rrect, Paint()..color = color);
    _paintInnerShadow(canvas, rrect, const Color(0x12000000), Offset(depth, depth));
    _paintInnerShadow(canvas, rrect, const Color(0xA6FFFFFF), Offset(-depth, -depth));
  }

  /// Truco clásico: se recorta a la forma y se pinta, desenfocado, un "anillo"
  /// que es todo lo de afuera de la forma desplazada. La parte visible del
  /// anillo queda pegada al borde interior del lado opuesto al desplazamiento.
  void _paintInnerShadow(Canvas canvas, RRect rrect, Color shadowColor, Offset offset) {
    final blur = depth * 2;
    final outer = Path()..addRect(rrect.outerRect.inflate(blur * 3));
    final hole = Path()..addRRect(rrect.shift(offset));
    final ring = Path.combine(PathOperation.difference, outer, hole);

    canvas
      ..save()
      ..clipRRect(rrect)
      ..drawPath(
        ring,
        Paint()
          ..color = shadowColor
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, Shadow.convertRadiusToSigma(blur)),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_InsetShadowPainter oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      circle != oldDelegate.circle ||
      depth != oldDelegate.depth;
}
