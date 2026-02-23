import 'dart:ui' show Offset, Size;

/// Shared coordinate utility for mapping YOLO normalized detection coordinates
/// to canvas pixel coordinates, accounting for FILL_CENTER (BoxFit.cover) crop.
///
/// YOLOView renders using FILL_CENTER scaling: the camera preview is scaled so
/// the entire widget is covered while maintaining aspect ratio. One dimension
/// fills the widget exactly; the other is scaled beyond the widget edge and
/// cropped symmetrically. Normalized coordinates from the model are relative
/// to the full uncropped camera frame, so the crop offset must be subtracted
/// when converting to widget-local pixel coordinates.
///
/// This math is extracted verbatim from [DebugDotPainter.paint()] — it was
/// verified on iPhone 12 in Phase 6 and must not be modified without
/// re-validating on device.
class YoloCoordUtils {
  YoloCoordUtils._();

  /// Maps a normalized ball-center coordinate to canvas pixel coordinates.
  ///
  /// [normalized] — ball center in [0.0, 1.0] x [0.0, 1.0] relative to the
  /// full camera frame (as reported by YOLOView's normalizedBox).
  ///
  /// [canvasSize] — pixel dimensions of the CustomPaint canvas (matches the
  /// YOLOView widget bounds).
  ///
  /// [cameraAspectRatio] — camera sensor width / height (e.g. 16.0 / 9.0).
  /// Defaults to 16/9, which covers iPhone 12 and Galaxy A32 standard video.
  static Offset toCanvasPixel(
    Offset normalized,
    Size canvasSize,
    double cameraAspectRatio,
  ) {
    final widgetAR = canvasSize.width / canvasSize.height;
    double pixelX, pixelY;

    if (widgetAR > cameraAspectRatio) {
      // Widget wider than camera -> scaled by width, height cropped.
      final scaledHeight = canvasSize.width / cameraAspectRatio;
      final cropY = (scaledHeight - canvasSize.height) / 2.0;
      pixelX = normalized.dx * canvasSize.width;
      pixelY = normalized.dy * scaledHeight - cropY;
    } else {
      // Widget taller than camera -> scaled by height, width cropped.
      final scaledWidth = canvasSize.height * cameraAspectRatio;
      final cropX = (scaledWidth - canvasSize.width) / 2.0;
      pixelX = normalized.dx * scaledWidth - cropX;
      pixelY = normalized.dy * canvasSize.height;
    }

    return Offset(pixelX, pixelY);
  }
}
