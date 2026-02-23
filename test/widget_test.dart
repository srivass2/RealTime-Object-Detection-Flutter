import 'package:flutter_test/flutter_test.dart';
import 'package:tensorflow_demo/config/detector_config.dart';

void main() {
  group('DetectorConfig', () {
    test('defaults to tflite backend when no env var is set', () {
      expect(DetectorConfig.backend, DetectorBackend.tflite);
    });

    test('label returns TFLite for default backend', () {
      expect(DetectorConfig.label, 'TFLite');
    });

    test('DetectorBackend enum has all expected values', () {
      expect(DetectorBackend.values, containsAll([
        DetectorBackend.tflite,
        DetectorBackend.yolo,
        DetectorBackend.mlkit,
      ]));
    });
  });
}
