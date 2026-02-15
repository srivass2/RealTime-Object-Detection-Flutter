import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'package:tensorflow_demo/services/tensorflow_service.dart';

import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supported values:
  //  - tflite  -> SSD MobileNet (ssd_mobilenet_v1.tflite)
  //  - yolo    -> YOLO backend (your yolo11n.tflite flow)
  const backend = String.fromEnvironment(
    'DETECTOR_BACKEND',
    defaultValue: 'tflite',
  );
  print('DETECTOR_BACKEND = $backend');

  // TEMP CHECK: can iOS load YOLO TFLite from Flutter assets?
  if (Platform.isIOS) {
    try {
      final interpreter = await Interpreter.fromAsset('assets/model/yolo11n.tflite');
      print('iOS loaded assets/model/yolo11n.tflite OK. '
          'Inputs: ${interpreter.getInputTensors().map((t) => t.shape).toList()} '
          'Outputs: ${interpreter.getOutputTensors().map((t) => t.shape).toList()}');
      interpreter.close();
    } catch (e) {
      print('iOS FAILED to load assets/model/yolo11n.tflite: $e');
    }
  }

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
  ]);

  runApp(const MyApp());
}
