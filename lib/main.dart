import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'package:tensorflow_demo/services/tensorflow_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supported values:
  //  - tflite  -> SSD MobileNet (ssd_mobilenet_v1.tflite)
  //  - yolo    -> YOLO backend (your yolo11n.tflite flow)
  const backend = String.fromEnvironment(
    'DETECTOR_BACKEND',
    defaultValue: 'tflite',
  );
  log('DETECTOR_BACKEND = $backend', name: 'main');

  // Initialize ONLY the selected backend
  if (backend == 'tflite') {
    await TensorflowService.ssdMobileNet.initialize();
  } else if (backend == 'yolo') {
    // IMPORTANT:
    // Do NOT initialize SSD here.
    // Your YOLO backend should load its model when it is used.
    // (If your YOLO backend has an explicit initialize() method,
    // we will add it here in the next step.)
  } else {
    // If someone passes a wrong value, default safely to tflite
    await TensorflowService.ssdMobileNet.initialize();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}
