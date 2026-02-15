// lib/config/detector_config.dart

enum DetectorBackend { tflite, yolo, mlkit }

class DetectorConfig {
  static const String _raw =
      String.fromEnvironment('DETECTOR_BACKEND', defaultValue: 'tflite');

  static DetectorBackend get backend {
    switch (_raw.toLowerCase()) {
      case 'yolo':
        return DetectorBackend.yolo;
      case 'mlkit':
        return DetectorBackend.mlkit;
      case 'tflite':
      default:
        return DetectorBackend.tflite;
    }
  }

  static String get label {
    switch (backend) {
      case DetectorBackend.yolo:
        return 'YOLO';
      case DetectorBackend.mlkit:
        return 'ML Kit';
      case DetectorBackend.tflite:
        return 'TFLite';
    }
  }
}
