import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/face_filter.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../providers/wallet_provider.dart';
import '../../../../core/services/analytics_service.dart';
import '../../data/datasource/face_detection_service.dart';
import '../widgets/camera_button.dart';
import '../widgets/capture_preview_sheet.dart';
import '../widgets/face_filter_painter.dart';
import '../widgets/filter_store.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/hamtimer_app_bar.dart';
import '../../../../core/widgets/message_state.dart';
import '../../../../core/widgets/points_chip.dart';

/// Pantalla e) Cámara con filtros en vivo (ML Kit), tienda de filtros con
/// puntos y publicación al feed.
///
/// La cámara, las caras detectadas y el filtro elegido son estado *local*
/// (`setState`): solo los usa esta pantalla. Los puntos y los filtros
/// comprados son globales (`WalletProvider`), y publicar va por `FeedProvider`.
///
/// Ciclo de vida (clase 13): la cámara solo está encendida mientras esta
/// pestaña se ve ([isActive]) y la app está en primer plano.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.isActive, required this.onPublished});

  final bool isActive;

  /// Se llama después de publicar, para ir al feed.
  final VoidCallback onPublished;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final GlobalKey _captureKey = GlobalKey();
  final FaceDetectionService _detector = FaceDetectionService();

  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  CameraController? _camera;
  bool _isStarting = false;
  bool _isProcessingFrame = false;
  bool _isCapturing = false;
  String? _error;
  bool _permissionDenied = false;

  List<Face> _faces = const [];
  Size? _frameSize;
  FaceFilter _filter = FaceFilter.catalog.first;

  bool get _isFrontCamera => _camera?.description.lensDirection == CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) _startCamera();
  }

  @override
  void didUpdateWidget(CameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;
    widget.isActive ? _startCamera() : _stopCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al salir de la app se libera la cámara para que otras apps la usen.
    switch (state) {
      case AppLifecycleState.resumed:
        if (widget.isActive) _startCamera();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _stopCamera();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _detector.dispose();
    super.dispose();
  }

  // --- Cámara ----------------------------------------------------------------

  Future<void> _startCamera() async {
    if (_camera != null || _isStarting) return;
    _isStarting = true;
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        final front = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        _cameraIndex = front >= 0 ? front : 0;
      }
      if (_cameras.isEmpty) {
        _setError('Este dispositivo no tiene cámara');
        return;
      }
      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        // ML Kit en Android necesita los cuadros en NV21.
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await controller.initialize();
      if (!mounted || !widget.isActive) {
        await controller.dispose();
        return;
      }
      await controller.startImageStream(_onFrame);
      setState(() {
        _camera = controller;
        _error = null;
      });
    } on CameraException catch (error) {
      AppLogger.error('camera', 'No se pudo abrir la cámara', error);
      _permissionDenied = error.code == 'CameraAccessDenied';
      _setError(
        _permissionDenied
            ? 'Hamtimer necesita permiso para usar la cámara.\nActívalo en los ajustes de la app.'
            : 'No se pudo abrir la cámara',
      );
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _stopCamera() async {
    final controller = _camera;
    if (controller == null) return;
    _camera = null;
    _faces = const [];
    if (mounted) setState(() {});
    if (controller.value.isStreamingImages) await controller.stopImageStream();
    await controller.dispose();
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    await _stopCamera();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera();
  }

  void _setError(String message) {
    if (mounted) setState(() => _error = message);
  }

  /// Cada cuadro de la cámara pasa por ML Kit. Si el anterior todavía se está
  /// procesando, este se salta: así la vista previa no se traba.
  Future<void> _onFrame(CameraImage image) async {
    final camera = _camera;
    if (_isProcessingFrame || camera == null) return;
    _isProcessingFrame = true;
    try {
      final result = await _detector.process(image, camera.description);
      if (result != null && mounted && _camera != null) {
        setState(() {
          _faces = result.faces;
          _frameSize = result.frameSize;
        });
      }
    } on Exception catch (error) {
      AppLogger.warning('camera', 'Falló la detección: $error');
    } finally {
      _isProcessingFrame = false;
    }
  }

  // --- Tienda de filtros -----------------------------------------------------

  void _selectFilter(FaceFilter filter) {
    setState(() => _filter = filter);
    context.read<AnalyticsService>().logEvent('filter_selected', {'filter': filter.id});
  }

  Future<void> _buyFilter(FaceFilter filter) async {
    final wallet = context.read<WalletProvider>();
    final analytics = context.read<AnalyticsService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${filter.emoji}  ${filter.name}'),
        content: Text(
          '¿Comprar este filtro por ${filter.price} puntos?\n'
          'Tienes ${wallet.points} puntos.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Comprar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      wallet.buy(filter);
    } on AppException catch (error) {
      AppFeedback.show(context, error.message);
      return;
    }
    setState(() => _filter = filter);
    AppFeedback.show(context, '¡${filter.name} es tuyo!');
    await analytics.logEvent('filter_purchased', {'filter': filter.id, 'price': filter.price});
  }

  // --- Foto y publicación ----------------------------------------------------

  /// Rasteriza la vista previa con el filtro (todo lo que está dentro del
  /// `RepaintBoundary`) a un PNG.
  Future<Uint8List?> _capture() async {
    final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  }

  Future<void> _takePhoto() async {
    if (_isCapturing || _camera == null) return;
    setState(() => _isCapturing = true);
    final analytics = context.read<AnalyticsService>();
    final feed = context.read<FeedProvider>();
    final connectivity = context.read<ConnectivityProvider>();
    try {
      final png = await _capture();
      if (png == null || !mounted) return;
      unawaited(analytics.logEvent('photo_taken', {'filter': _filter.id}));
      final publish = await CapturePreviewSheet.show(
        context,
        pngBytes: png,
        isOnline: connectivity.isOnline,
      );
      if (publish != true || !mounted) return;
      await feed.publish(pngBytes: png, filterId: _filter.id);
      await analytics.logEvent('photo_published', {'filter': _filter.id});
      if (!mounted) return;
      AppFeedback.show(context, '¡Foto publicada!');
      widget.onPublished();
    } on AppException catch (error) {
      if (mounted) AppFeedback.show(context, error.message);
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // --- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Column(
      children: [
        HamtimerAppBar(
          title: 'Cámara',
          subtitle: 'Gana puntos con Pomodoros y compra filtros',
          centerTitle: false,
          leading: AppBarIconButton(
            icon: Icons.cameraswitch_outlined,
            tooltip: 'Cambiar cámara',
            onPressed: _switchCamera,
          ),
          actions: [PointsChip(points: wallet.points)],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: ColoredBox(color: Colors.black, child: _buildPreview()),
            ),
          ),
        ),
        FilterStore(
          filters: FaceFilter.catalog,
          points: wallet.points,
          isOwned: wallet.owns,
          selectedId: _filter.id,
          onSelect: _selectFilter,
          onBuy: _buyFilter,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CameraButton(
            onPressed: _camera == null ? null : _takePhoto,
            isBusy: _isCapturing,
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (_error != null) {
      return ColoredBox(
        color: AppColors.surface,
        child: MessageState(
          icon: Icons.no_photography_outlined,
          message: _error!,
          actionLabel: 'Reintentar',
          onAction: () {
            setState(() => _error = null);
            _startCamera();
          },
          secondaryActionLabel: _permissionDenied ? 'Abrir ajustes' : null,
          onSecondaryAction: openAppSettings,
        ),
      );
    }
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    // La vista previa llega en horizontal: en vertical se invierten sus lados.
    final previewSize = camera.value.previewSize!;
    return RepaintBoundary(
      key: _captureKey,
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(camera),
              if (_frameSize != null)
                CustomPaint(
                  painter: FaceFilterPainter(
                    faces: _faces,
                    frameSize: _frameSize!,
                    mirror: _isFrontCamera,
                    filter: _filter,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
