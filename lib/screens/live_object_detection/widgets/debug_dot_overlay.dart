import 'package:flutter/material.dart';

/// A [CustomPainter] that renders a single red dot at a normalized position.
///
/// [dotPosition] is a normalized [Offset] in the range [0.0, 1.0] for both
/// axes, representing the center of the detected ball relative to the original
/// camera frame dimensions.
///
/// [cameraAspectRatio] is the camera sensor's width/height ratio (e.g., 16/9).
/// This is needed because YOLOView uses FILL_CENTER scaling (equivalent to
/// BoxFit.cover) — the camera preview is scaled to fill the widget while
/// maintaining aspect ratio, which crops one dimension. The normalized
/// coordinates from the model are relative to the full uncropped camera frame,
/// so we must account for the crop when mapping to widget pixel coordinates.
///
/// Used by the YOLO detection pipeline to render a debug dot centered on the
/// highest-confidence ball detection, proving coordinate extraction and overlay
/// layering are correct before trail accumulation is implemented in Phase 7.
class DebugDotPainter extends CustomPainter {
  final Offset? dotPosition;

  /// Camera sensor aspect ratio (width / height). Defaults to 4:3 because the
  /// `ultralytics_yolo` plugin uses `.photo` session preset on iOS, which
  /// captures at 4032×3024 (4:3). See YOLOView.swift line 382.
  final double cameraAspectRatio;

  const DebugDotPainter({
    required this.dotPosition,
    this.cameraAspectRatio = 4.0 / 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pos = dotPosition;
    if (pos == null || size.isEmpty) return;

    // The CustomPaint canvas matches the YOLOView widget dimensions.
    // YOLOView uses FILL_CENTER (BoxFit.cover): the camera preview is scaled
    // so the entire widget is covered, maintaining camera aspect ratio.
    // One dimension matches exactly; the other is larger and cropped.
    //
    // normalizedBox coordinates are relative to the FULL camera frame.
    // We must compute which portion of the camera frame is visible (after crop)
    // and map the normalized coords into the visible widget area.

    final widgetAR = size.width / size.height;

    double pixelX, pixelY;

    if (widgetAR > cameraAspectRatio) {
      // Widget is wider than camera → scaled by width, height cropped.
      final scaledHeight = size.width / cameraAspectRatio;
      final cropY = (scaledHeight - size.height) / 2.0;
      pixelX = pos.dx * size.width;
      pixelY = pos.dy * scaledHeight - cropY;
    } else {
      // Widget is taller than camera → scaled by height, width cropped.
      final scaledWidth = size.height * cameraAspectRatio;
      final cropX = (scaledWidth - size.width) / 2.0;
      pixelX = pos.dx * scaledWidth - cropX;
      pixelY = pos.dy * size.height;
    }

    final pixelOffset = Offset(pixelX, pixelY);

    // Filled red circle (slightly transparent for visual comfort).
    final fillPaint = Paint()
      ..color = Colors.red.withAlpha(230) // ~0.9 alpha
      ..style = PaintingStyle.fill;

    // White stroke outline for visibility on any background.
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const double radius = 8.0;

    canvas.drawCircle(pixelOffset, radius, fillPaint);
    canvas.drawCircle(pixelOffset, radius, strokePaint);
  }

  @override
  bool shouldRepaint(DebugDotPainter oldDelegate) {
    return oldDelegate.dotPosition != dotPosition ||
        oldDelegate.cameraAspectRatio != cameraAspectRatio;
  }
}
