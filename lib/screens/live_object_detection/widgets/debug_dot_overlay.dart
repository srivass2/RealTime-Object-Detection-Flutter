import 'package:flutter/material.dart';

/// A [CustomPainter] that renders a single red dot at a normalized position.
///
/// [dotPosition] is a normalized [Offset] in the range [0.0, 1.0] for both
/// axes, representing the center of the detected ball. When null, nothing is
/// drawn (no detection in the current frame).
///
/// Used by both the YOLO and SSD detection pipelines to render a debug dot
/// centered on the highest-confidence ball detection, proving coordinate
/// extraction and overlay layering are correct before trail accumulation is
/// implemented in Phase 7.
class DebugDotPainter extends CustomPainter {
  final Offset? dotPosition;

  const DebugDotPainter({required this.dotPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final pos = dotPosition;
    if (pos == null) return;

    // Map normalized [0.0, 1.0] coords to canvas pixel coords.
    final pixelOffset = Offset(pos.dx * size.width, pos.dy * size.height);

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
    return oldDelegate.dotPosition != dotPosition;
  }
}
