import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'face_filter_drawer.dart';
import '../../domain/entities/face_filter.dart';

/// Dibuja el filtro elegido sobre cada cara detectada en la vista previa.
///
/// ML Kit entrega las coordenadas en el tamaño del cuadro que procesó
/// ([frameSize]); aquí se escalan al tamaño del widget. La cámara frontal se
/// ve como espejo, así que también se refleja el dibujo.
class FaceFilterPainter extends CustomPainter {
  FaceFilterPainter({
    required this.faces,
    required this.frameSize,
    required this.mirror,
    required this.filter,
  });

  final List<Face> faces;
  final Size frameSize;
  final bool mirror;
  final FaceFilter filter;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (mirror) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    canvas.scale(size.width / frameSize.width, size.height / frameSize.height);
    for (final face in faces) {
      FaceFilterDrawer.draw(canvas, face, filter);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FaceFilterPainter oldDelegate) =>
      oldDelegate.faces != faces ||
      oldDelegate.frameSize != frameSize ||
      oldDelegate.mirror != mirror ||
      oldDelegate.filter != filter;
}
