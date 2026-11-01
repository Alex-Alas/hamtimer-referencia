import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Caras detectadas en un cuadro, con el tamaño del cuadro ya rotado para
/// poder escalar las coordenadas al tamaño de la vista previa.
class FaceDetectionResult {
  const FaceDetectionResult({required this.faces, required this.frameSize});

  final List<Face> faces;
  final Size frameSize;
}

/// Detección de rostros en vivo con ML Kit (clases 24 y 29).
///
/// Recibe los cuadros crudos de la cámara (`CameraImage`), los convierte al
/// formato que entiende ML Kit y devuelve las caras con sus puntos de
/// referencia (ojos, nariz, boca). Corre en el teléfono, sin internet.
class FaceDetectionService {
  FaceDetectionService({FaceDetector? detector})
    : _detector =
          detector ??
          FaceDetector(
            options: FaceDetectorOptions(
              performanceMode: FaceDetectorMode.fast,
              enableLandmarks: true,
            ),
          );

  final FaceDetector _detector;

  /// Procesa un cuadro. Devuelve `null` si el formato no es compatible.
  Future<FaceDetectionResult?> process(CameraImage image, CameraDescription camera) async {
    final input = _toInputImage(image, camera);
    if (input == null) return null;
    final faces = await _detector.processImage(input);
    final rotation = input.metadata!.rotation;
    final rotated =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    return FaceDetectionResult(
      faces: faces,
      frameSize: rotated
          ? Size(image.height.toDouble(), image.width.toDouble())
          : Size(image.width.toDouble(), image.height.toDouble()),
    );
  }

  /// En Android la cámara entrega NV21 (un solo plano) cuando se pide con
  /// `ImageFormatGroup.nv21`; en iOS, BGRA8888.
  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (rotation == null || format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    if (image.planes.length != 1) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> dispose() => _detector.close();
}
