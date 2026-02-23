import 'dart:async';
import 'dart:developer';
import 'package:tensorflow_demo/config/detector_config.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tensorflow_demo/models/detected_object/detected_object_dm.dart';
import 'package:tensorflow_demo/models/screen_params.dart';
import 'package:tensorflow_demo/screens/live_object_detection/widgets/debug_dot_overlay.dart';
import 'package:tensorflow_demo/screens/live_object_detection/widgets/rounded_button.dart';
import 'package:tensorflow_demo/services/detector.dart';
import 'package:tensorflow_demo/services/navigation_service.dart';
import 'package:tensorflow_demo/values/app_routes.dart';
import 'package:tensorflow_demo/widgets/box_widget.dart';
import 'package:flutter/services.dart';

import 'dart:io' show Platform;


class LiveObjectDetectionScreen extends StatefulWidget {
  const LiveObjectDetectionScreen({super.key});

  @override
  State<LiveObjectDetectionScreen> createState() =>
      _LiveObjectDetectionScreenState();
}

class _LiveObjectDetectionScreenState extends State<LiveObjectDetectionScreen> {
  final _imagePicker = ImagePicker();

  String? message;

  late final AppLifecycleListener _appLifecycleListener;

  /// List of available cameras
  late List<CameraDescription> cameras;

  int cameraIndex = 0;

  /// Controller
  CameraController? _cameraController;

  /// Object Detector is running on a background [Isolate]. This is nullable
  /// because acquiring a [Detector] is an asynchronous operation. This
  /// value is `null` until the detector is initialized.
  Detector? _detector;

  StreamSubscription? _objectDetectorStream;

  /// Results to draw bounding boxes
  List<DetectedObjectDm>? detectedObjectList;

  /// Normalized [0.0, 1.0] position of the best-confidence ball detection.
  /// Null when no ball is detected in the current frame.
  Offset? _debugDotPosition;

  @override
  void initState() {
    super.initState();

    // If YOLO is selected, we do NOT start camera_controller + Detector isolate.
    // YOLOView manages its own camera pipeline.
    if (DetectorConfig.backend == DetectorBackend.yolo) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      return;
    }

    _appLifecycleListener = AppLifecycleListener(
      onResume: _init,
      onInactive: () {
        _cameraController?.stopImageStream();
        _objectDetectorStream?.cancel();
        _detector?.stop();
      },
    );

    _init();
  }

  // ---------------------------------------------------------------------------
  // YOLO helper: pick highest-confidence ball result from detection list.
  // ---------------------------------------------------------------------------

  YOLOResult? _pickBestBallYolo(List<YOLOResult> results) {
    const ballClasses = {'Soccer ball', 'ball', 'tennis-ball'};
    final candidates =
        results.where((r) => ballClasses.contains(r.className)).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates.first;
  }

  // ---------------------------------------------------------------------------
  // SSD helper: pick highest-confidence ball result from detection list and
  // return its center as a normalized [0.0, 1.0] Offset.
  // ---------------------------------------------------------------------------

  Offset? _pickBestBallSsd(List<DetectedObjectDm> objects) {
    final previewSize = ScreenParams.screenPreviewSize;
    // Guard against division by zero if ScreenParams has not been populated yet.
    if (previewSize.width == 0 || previewSize.height == 0) return null;
    // SSD MobileNet uses COCO labels — 'sports ball' is the relevant class.
    final candidates =
        objects.where((o) => o.label.toLowerCase().contains('ball')).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final best = candidates.first;
    // renderLocation is in screen-pixel space; normalize to 0.0-1.0.
    return Offset(
      best.renderLocation.center.dx / previewSize.width,
      best.renderLocation.center.dy / previewSize.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (DetectorConfig.backend == DetectorBackend.yolo) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Object Detection')),
        body: Stack(
          fit: StackFit.expand,
          children: [
            YOLOView(
              modelPath: Platform.isIOS ? 'yolo11n' : 'yolo11n.tflite',
              task: YOLOTask.detect,
              // OVLY-03: Suppress native bounding box overlays so only
              // our custom debug dot renders.
              showOverlays: false,
              onResult: (results) {
                // OVLY-04: Guard against setState-after-dispose.
                if (!mounted) return;

                log('YOLO results: ${results.length}');

                // OVLY-01: Extract normalized ball center from best detection.
                final ball = _pickBestBallYolo(results);
                final Offset? newDot = ball != null
                    ? Offset(
                        ball.normalizedBox.center.dx,
                        ball.normalizedBox.center.dy,
                      )
                    : null;
                setState(() => _debugDotPosition = newDot);
              },
            ),

            // OVLY-01: Debug dot overlay — RepaintBoundary wraps CustomPaint.
            RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: DebugDotPainter(dotPosition: _debugDotPosition),
              ),
            ),

            // Diagnostic coordinate text for device-side testing.
            if (_debugDotPosition != null)
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  color: Colors.black54,
                  child: Text(
                    'dot: (${_debugDotPosition!.dx.toStringAsFixed(3)}, '
                    '${_debugDotPosition!.dy.toStringAsFixed(3)})',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),

            // Backend label badge.
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DetectorConfig.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final controller = _cameraController;
    return Scaffold(
      appBar: AppBar(title: const Text('Live Object Detection')),
      body: controller == null || !controller.value.isInitialized
          ? Center(child: Text(message ?? 'Initializing...'))
          : Column(
              children: [
                AspectRatio(
                  aspectRatio: 1 / controller.value.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(controller),
                      // Bounding boxes
                      ...?detectedObjectList?.map(
                        (detectedObject) => Positioned.fromRect(
                          rect: detectedObject.renderLocation,
                          child: BoxWidget.fromDetectedObject(detectedObject),
                        ),
                      ),

                      // OVLY-02: Debug dot overlay — RepaintBoundary wraps CustomPaint.
                      RepaintBoundary(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter:
                              DebugDotPainter(dotPosition: _debugDotPosition),
                        ),
                      ),

                      // Diagnostic coordinate text for device-side testing.
                      if (_debugDotPosition != null)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            color: Colors.black54,
                            child: Text(
                              'dot: (${_debugDotPosition!.dx.toStringAsFixed(3)}, '
                              '${_debugDotPosition!.dy.toStringAsFixed(3)})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),

                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DetectorConfig.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: Colors.black,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RoundedButton(
                          size: 48,
                          side: BorderSide.none,
                          color: Colors.white.withValues(alpha: 0.3),
                          onTap: _pickImageFromGallery,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/vectors/gallery.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        RoundedButton(
                          padding: const EdgeInsets.all(2),
                          onTap: _takePicture,
                        ),
                        const SizedBox(width: 20),
                        RoundedButton(
                          size: 48,
                          side: BorderSide.none,
                          color: Colors.white.withValues(alpha: 0.3),
                          onTap: _flipCamera,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/vectors/repeate-music.svg',
                              width: 28,
                              height: 28,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    // Restore orientations for the rest of the app.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Only dispose if it was created (TFLite mode).
    try {
      _appLifecycleListener.dispose();
    } catch (_) {}

    _cameraController?.dispose();
    _objectDetectorStream?.cancel();
    _detector?.stop();

    super.dispose();
  }

  Future<void> _init() async {
    await _initializeCamera();
    await _initializeDetector();

    /// Listen each frame from calling the image stream
    await _cameraController?.startImageStream(onLatestImageAvailable);

    /// previewSize is size of each image frame captured by controller
    ///
    /// 352x288 on iOS, 240p (320x240) on Android with ResolutionPreset.low
    final size = _cameraController?.value.previewSize;
    if (size != null) ScreenParams.previewSize = size;

    if (mounted) setState(() {});
  }

  /// Initializes the camera by setting [_cameraController]
  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras.isEmpty) {
      message = 'No Camera Available';
      if (mounted) setState(() {});
      log('No Camera Available');
      return;
    }
    // cameras[0] for back-camera
    cameraIndex = 0;
    final camera = cameras[cameraIndex];
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController?.initialize();
    final s = _cameraController?.value.previewSize;
    log('CAMERA previewSize = $s');
  }

  Future<void> _initializeDetector() async {
    // For now this repo only has TFLite implemented via Detector.start().
    // If you pass yolo/mlkit, we show the label but fallback to TFLite.
    if (DetectorConfig.backend != DetectorBackend.tflite) {
      message =
          '${DetectorConfig.label} not implemented yet in this repo. Using TFLite.';
      if (mounted) setState(() {});
    }

    final detector = await Detector.start();
    setState(() {
      _detector = detector;
      // OVLY-02: Update _debugDotPosition inside the same mounted-guarded
      // setState to avoid a double rebuild and prevent setState-after-dispose.
      _objectDetectorStream = detector.resultsStream.listen((detectedObjects) {
        if (mounted) {
          setState(() {
            detectedObjectList = detectedObjects;
            _debugDotPosition = _pickBestBallSsd(detectedObjects);
          });
        }
      });
    });
  }

  void _flipCamera() {
    if (cameras.length <= 1) return;
    final newIndex = cameraIndex == 1 ? 0 : 1;
    cameraIndex = newIndex;
    _cameraController?.stopImageStream();
    _cameraController = CameraController(
      cameras[newIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    )..initialize().then((_) async {
        await _cameraController?.startImageStream(onLatestImageAvailable);
        if (mounted) setState(() {});

        /// previewSize is size of each image frame captured by controller
        ///
        /// 352x288 on iOS, 240p (320x240) on Android with ResolutionPreset.low
        ScreenParams.previewSize =
            _cameraController?.value.previewSize ?? ScreenParams.previewSize;
      });
  }

  Future<void> _takePicture() async {
    final capturedImage = await _cameraController?.takePicture();
    final decodedImage = await capturedImage?.readAsBytes();
    NavigationService.instance
      ..pop()
      ..pushNamed(AppRoutes.photoAnalyzedScreen, arguments: decodedImage);
  }

  Future<void> _pickImageFromGallery() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    final readAsBytesSync = await result?.readAsBytes();
    if (readAsBytesSync != null) {
      NavigationService.instance
        ..pop()
        ..pushNamed(AppRoutes.photoAnalyzedScreen, arguments: readAsBytesSync);
    }
  }

  /// Callback to receive each frame [CameraImage] perform inference on it
  void onLatestImageAvailable(CameraImage cameraImage) {
    _detector?.processFrame(cameraImage);
  }
}
