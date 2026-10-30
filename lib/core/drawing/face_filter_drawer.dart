import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../models/face_filter.dart';

/// Dibuja un filtro (emoji) sobre una cara detectada por ML Kit.
///
/// Trabaja en las coordenadas del cuadro que procesó ML Kit: quien lo llama
/// escala el canvas al tamaño de la vista previa antes de dibujar.
abstract final class FaceFilterDrawer {
  static void draw(Canvas canvas, Face face, FaceFilter filter) {
    final box = face.boundingBox;
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;

    // Inclinación de la cabeza a partir de la línea entre los ojos.
    final angle = (leftEye != null && rightEye != null)
        ? math.atan2((rightEye.y - leftEye.y).toDouble(), (rightEye.x - leftEye.x).toDouble())
        : 0.0;

    final center = _anchorPoint(face, filter.anchor);
    final size = box.width * filter.scale;

    final painter = TextPainter(
      text: TextSpan(
        text: filter.emoji,
        style: TextStyle(fontSize: size),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(angle);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  /// Punto de la cara donde se centra el filtro según su ancla.
  static Offset _anchorPoint(Face face, FilterAnchor anchor) {
    final box = face.boundingBox;
    Offset? landmark(FaceLandmarkType type) {
      final position = face.landmarks[type]?.position;
      return position == null ? null : Offset(position.x.toDouble(), position.y.toDouble());
    }

    switch (anchor) {
      case FilterAnchor.eyes:
        final left = landmark(FaceLandmarkType.leftEye);
        final right = landmark(FaceLandmarkType.rightEye);
        if (left != null && right != null) return (left + right) / 2;
        return Offset(box.center.dx, box.top + box.height * 0.4);
      case FilterAnchor.head:
        return Offset(box.center.dx, box.top - box.height * 0.15);
      case FilterAnchor.mouth:
        final nose = landmark(FaceLandmarkType.noseBase);
        final mouth = landmark(FaceLandmarkType.bottomMouth);
        if (nose != null && mouth != null) return (nose + mouth) / 2;
        return Offset(box.center.dx, box.top + box.height * 0.72);
    }
  }
}
