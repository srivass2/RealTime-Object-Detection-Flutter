# Stack Research

**Domain:** Real-time ball tracking with fading visual trail — Flutter on-device ML overlay
**Researched:** 2026-02-23
**Confidence:** HIGH

---

## Scope

This document covers ONLY the NEW stack additions required for milestone v1.1 (Ball Tracking). It does not re-research the existing validated stack (Flutter 3.38.9, `ultralytics_yolo ^0.2.0`, `tflite_flutter 0.11.0`, MobX, camera, etc.).

---

## Recommended Stack

### Core Technologies (New Additions)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `dart:collection` `ListQueue` | SDK built-in | Fixed-history position buffer for trail points | Zero dependencies, O(1) add/remove from both ends, ships with every Flutter SDK. No package needed. |
| Flutter `CustomPainter` + `CustomPaint` | SDK built-in | Trail dot and line rendering on top of camera | The canonical Flutter approach for 2D canvas drawing. No external package provides better control or performance for this use case. |
| Flutter `AnimationController` | SDK built-in | Drive per-frame trail repaint at display refresh rate | Built into Flutter's animation system. Gives 60/120 Hz ticks via `TickerProviderStateMixin` — exactly what's needed to age trail points and repaint. |
| Flutter `Stack` + `IgnorePointer` | SDK built-in | Layer trail overlay over `YOLOView` / `CameraPreview` | Existing pattern in `live_object_detection_screen.dart` — the TFLite path already uses `Stack` for bounding box overlays. Same pattern applies to the trail. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `dart:ui` `Rect`, `Offset`, `Canvas`, `Paint` | SDK built-in | Primitive types for ball centre computation and trail paint ops | Always — no imports needed beyond what Flutter already provides. |
| `RepaintBoundary` widget | SDK built-in | Isolate the `CustomPaint` trail layer so camera frames don't trigger full-tree repaints | Wrap the `CustomPaint` trail overlay in `RepaintBoundary` to scope repaints to just the trail layer. Critical for real-time performance on Galaxy A32. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `flutter analyze` | Lint during trail layer development | Already configured; run after adding new Dart files |
| Flutter DevTools — Performance overlay | Verify trail repaints are isolated and not causing jank | Use "Highlight repaints" mode to confirm `RepaintBoundary` is working correctly |

---

## Installation

No new `pubspec.yaml` entries are required. All technologies are part of the Flutter SDK.

```bash
# No new packages. Confirm existing deps are installed:
flutter pub get
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `ListQueue` from `dart:collection` | `circular_buffer` pub.dev package | Only if you need thread-safe concurrent writes, which Dart single-threaded model makes unnecessary here |
| `ListQueue` from `dart:collection` | `Queue` from `dart:collection` | `ListQueue` is preferred — it has better amortized performance for the add-to-back / remove-from-front pattern that the trail uses |
| `AnimationController` driving `CustomPainter` repaint | `Timer.periodic` for trail aging | `AnimationController` is frame-synchronized (vsync), `Timer.periodic` is wall-clock and will drift relative to actual display frames. Use `AnimationController`. |
| `AnimationController` driving `CustomPainter` repaint | Calling `setState` from `onResult` callback | `setState` causes full widget subtree rebuild. `AnimationController` + `CustomPainter.repaint` listenable repaints only the canvas layer. Prefer the latter for performance. |
| Single `CustomPaint` for trail only | Single `CustomPaint` for trail + bounding boxes | Keep them separate. `YOLOView` owns bounding box rendering internally (via `showOverlays: true`). Trail painter is a separate, independent overlay layer. |
| `IgnorePointer` wrapping trail overlay | No pointer interception wrapper | Trail overlay must not consume touch events — `IgnorePointer` is required so users can interact with controls behind the overlay. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Any third-party trail/particle packages (e.g. `particle_field`, `flame`) | Adds a game-engine-level dependency for a 30-line `CustomPainter`. Overkill, adds binary size, and constrains upgrade path of existing packages. | `CustomPainter` + `AnimationController` — sufficient for dots and a polyline |
| `Ticker` directly | Lower-level than needed; `AnimationController` wraps `Ticker` with cleaner lifecycle management and `dispose()` safety | `AnimationController` with `TickerProviderStateMixin` |
| `Timer.periodic` for trail aging | Not vsync-aware; will accumulate drift at 60 Hz, causing visual stutter on Galaxy A32 | `AnimationController` with `addListener` |
| MobX for trail state | Trail state (position history, timestamps) lives inside one `StatefulWidget`'s `State`. MobX is scoped to Home Screen by architecture rule. Introducing it here violates the architecture rule with no benefit. | `setState` inside the screen's `State` class, with trail logic in a dedicated `TrailController` plain Dart class |
| Predictive interpolation libraries | Out of scope per `PROJECT.md` — "Predictive tracking (estimating ball position when occluded) — happy path first" | Simple gap-in-path approach on occlusion |

---

## Stack Patterns by Pipeline

**YOLO path (`DETECTOR_BACKEND=yolo`):**
- `YOLOView.onResult` fires `List<YOLOResult>` per frame (confirmed from `yolo_result.dart`)
- Extract ball centre from `YOLOResult.normalizedBox` (preferred over `boundingBox` — resolution-independent, no coordinate scaling needed)
- Centre formula: `Offset(normalizedBox.left + normalizedBox.width / 2, normalizedBox.top + normalizedBox.height / 2)`
- Overlay trail `CustomPaint` on top of `YOLOView` inside the existing `Stack`
- Filter results by `className` matching `'Soccer ball'`, `'ball'`, or `'tennis-ball'`; take highest-confidence match when multiple present

**SSD MobileNet / TFLite path (`DETECTOR_BACKEND=tflite`):**
- `detector.resultsStream` fires `List<DetectedObjectDm>` per frame (existing stream in `live_object_detection_screen.dart`)
- Extract ball centre from `DetectedObjectDm.location` (raw inference coordinates) — compute centre before `renderLocation` scaling, or compute from `renderLocation` for screen-space coordinates
- Same `CustomPaint` overlay pattern on top of `CameraPreview` inside the existing `Stack`
- Filter by `label` matching ball classes; note SSD uses COCO 91 labels, `'sports ball'` is COCO class index 37

---

## Architecture Integration Points

### Overlay Slot (both pipelines)

The trail `CustomPaint` slots into the existing `Stack` in `LiveObjectDetectionScreen.build()`:

```
Stack(
  fit: StackFit.expand,
  children: [
    YOLOView(...)                              // existing — camera + native overlays
    RepaintBoundary(                           // NEW — isolates trail repaints
      child: CustomPaint(
        painter: BallTrailPainter(trail: _trail),
      ),
    ),
    IgnorePointer(child: ...),                 // existing backend label badge, unchanged
  ],
)
```

### Trail State

Trail state belongs in `_LiveObjectDetectionScreenState`. A dedicated plain Dart class (`BallTrailController`) should own the `ListQueue<_TrailPoint>` and timestamp logic to keep the screen's `State` class clean — no MobX, no separate widget.

```dart
class _TrailPoint {
  final Offset normalizedPosition; // 0.0–1.0 on both axes
  final DateTime timestamp;
}
```

### Trail Painter Repaint Trigger

`BallTrailPainter` should extend `CustomPainter` and accept `Listenable repaint` (the `AnimationController`). The `AnimationController` runs continuously while the screen is active (using `repeat()`), calling `notifyListeners()` each frame. The painter reads trail point ages from `DateTime.now()` within `paint()` — no additional state management needed.

---

## Version Compatibility

| Component | Compatible With | Notes |
|-----------|-----------------|-------|
| `AnimationController` / `TickerProviderStateMixin` | Flutter SDK 3.38.9 (Dart 3.10.8) | Built-in, no version concern |
| `ListQueue` from `dart:collection` | Dart 3.x | Built-in, no version concern |
| `CustomPainter` with `repaint: Listenable` | Flutter SDK 3.x | Built-in, stable API since Flutter 1.x |
| `RepaintBoundary` | Flutter SDK 3.x | Built-in, no version concern |
| Trail overlay `Stack` slot in `YOLOView` build | `ultralytics_yolo ^0.2.0` | Confirmed: `YOLOView` renders inside a `Stack` internally; wrapping it in another `Stack` in the parent is safe |

---

## Sources

- `~/.pub-cache/hosted/pub.dev/ultralytics_yolo-0.2.0/lib/models/yolo_result.dart` — confirmed `YOLOResult.normalizedBox: Rect` and `YOLOResult.className: String` fields (HIGH confidence, direct source inspection)
- `~/.pub-cache/hosted/pub.dev/ultralytics_yolo-0.2.0/lib/yolo_view.dart` — confirmed `onResult: Function(List<YOLOResult>)?` signature; confirmed `showOverlays: true` renders native bounding boxes; confirmed `Stack`-based build (HIGH confidence, direct source inspection)
- [Flutter API — AnimationController](https://api.flutter.dev/flutter/animation/AnimationController-class.html) — vsync-aware ticker lifecycle (HIGH confidence, official docs)
- [Flutter API — RepaintBoundary](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html) — isolating canvas repaints from camera subtree (HIGH confidence, official docs)
- [Flutter API — ListQueue](https://api.flutter.dev/flutter/dart-collection/ListQueue-class.html) — O(1) add/remove for position history buffer (HIGH confidence, official docs)
- [Approached 60 FPS Object Detection without any frame dropout on Mobile devices with Flutter (Feb 2026)](https://medium.com/@cia1099/approached-60-fps-object-detection-without-any-frame-dropout-on-mobile-devices-with-flutter-6ab3c9dc5c4b) — real-world validation that `RepaintBoundary` + `CustomPaint` two-layer pattern is viable at real-time detection frame rates (MEDIUM confidence, community source)
- [Flutter Animations Overview](https://docs.flutter.dev/ui/animations/overview) — AnimationController / Ticker pattern (HIGH confidence, official docs)

---

*Stack research for: Ball tracking with fading visual trail — Flare Football Object Detection POC v1.1*
*Researched: 2026-02-23*
