# Architecture Research

**Domain:** Flutter on-device ML — dual-pipeline ball tracking with visual trail
**Researched:** 2026-02-23
**Confidence:** HIGH (codebase read directly; ultralytics_yolo source inspected on GitHub; YOLOResult properties confirmed)

---

## Standard Architecture

### System Overview

```
LiveObjectDetectionScreen (StatefulWidget)
│
├── [YOLO path — DetectorBackend.yolo]
│   │
│   ├── YOLOView (camera + inference, internal threads)
│   │     modelPath: Platform.isIOS ? 'yolo11n' : 'yolo11n.tflite'
│   │     showOverlays: false  ← disable native boxes for custom overlay
│   │     onResult: (List<YOLOResult> results) { ... }
│   │
│   ├── BallTracker (new — pure Dart, UI isolate)
│   │     input:  YOLOResult.normalizedBox (Rect, 0.0–1.0)
│   │     output: List<TrackedPosition> (normalized coords + timestamp)
│   │
│   └── TrailOverlay : CustomPainter (new)
│         input:  List<TrackedPosition>
│         draws:  fading dots + connecting polyline
│         coords: maps normalizedBox center → canvas pixels via Size
│
└── [TFLite path — DetectorBackend.tflite]
    │
    ├── CameraController (camera plugin)
    │     startImageStream → onLatestImageAvailable → Detector.processFrame()
    │
    ├── Detector (background Dart Isolate)
    │     _DetectorServer._analyseImageCamera → TensorflowHelper.analyseImage
    │     resultsStream: Stream<List<DetectedObjectDm>>
    │
    ├── DetectedObjectDm (existing model)
    │     renderLocation: Rect (screen pixels via ScreenParams scale)
    │
    ├── BallTracker (new — same class, UI isolate)
    │     input:  DetectedObjectDm.renderLocation center (pixels)
    │     output: List<TrackedPosition> (pixel coords + timestamp)
    │
    └── TrailOverlay : CustomPainter (new — same class, different coord input)
          input:  List<TrackedPosition>
          draws:  fading dots + connecting polyline
          coords: pixel coords directly (no normalization needed)
```

### Component Responsibilities

| Component | Responsibility | New vs Existing |
|-----------|---------------|-----------------|
| `LiveObjectDetectionScreen` | Conditional pipeline routing, widget tree host, tracking state via `setState` | Existing — modified |
| `YOLOView` | Camera + YOLO inference (internal native threads), fires `onResult` per frame | Existing — parameter change only (`showOverlays: false`) |
| `CameraController` + `Detector` isolate | Camera capture + SSD MobileNet inference on background isolate | Existing — unchanged |
| `BallTracker` | Accepts a detection result each frame, maintains position history with timestamps, handles occlusion (no detection = gap, not error) | **New** |
| `TrackedPosition` | Value type: `(Offset position, DateTime timestamp, bool isNormalized)` | **New** |
| `TrailOverlay` (CustomPainter) | Paints fading trail: dots at each TrackedPosition, polyline connecting them. Age-based opacity. | **New** |
| `ScreenParams` | Static size info for coordinate scaling (SSD path already uses this) | Existing — unchanged |

---

## Recommended Project Structure

```
lib/
├── config/
│   └── detector_config.dart          # Existing — unchanged
│
├── models/
│   ├── detected_object/
│   │   └── detected_object_dm.dart   # Existing — unchanged
│   └── tracked_position.dart         # NEW: value type for trail history
│
├── screens/
│   └── live_object_detection/
│       ├── live_object_detection_screen.dart  # Existing — modified
│       └── widgets/
│           ├── rounded_button.dart            # Existing — unchanged
│           └── trail_overlay.dart             # NEW: CustomPainter widget
│
├── services/
│   ├── ball_tracker.dart             # NEW: tracking state machine
│   └── detector.dart                 # Existing — unchanged
│
└── utils/
    └── trail_coord_utils.dart        # NEW (optional): coordinate mapping helpers
```

### Structure Rationale

- **`models/tracked_position.dart`:** Keeps the trail's data model separate from detection models. `TrackedPosition` is a simple value type with no Flutter dependencies — easy to unit test.
- **`services/ball_tracker.dart`:** Tracking logic (history management, occlusion handling, trail trimming) belongs in a service class, not embedded in the screen's `setState` block. Keeps `LiveObjectDetectionScreen` as a view coordinator only.
- **`screens/live_object_detection/widgets/trail_overlay.dart`:** CustomPainter is screen-specific UI — co-locate it with the screen rather than in `lib/widgets/` which holds shared widgets.
- **`utils/trail_coord_utils.dart`:** Coordinate normalization math can be extracted here if it grows complex. Initially may not be needed — `TrailOverlay` can do the math inline.

---

## Architectural Patterns

### Pattern 1: Pipeline-Agnostic Tracker, Pipeline-Specific Adapter

**What:** `BallTracker` accepts a normalized `Offset` (always 0.0–1.0) regardless of which pipeline feeds it. Each pipeline has a one-line adapter that converts its native result type to a normalized center offset before calling `tracker.update(offset)`.

**When to use:** Both pipelines must feed the same tracker without the tracker knowing which pipeline is active. This avoids two separate tracker implementations.

**Trade-offs:** Slight indirection for the YOLO path (normalizedBox is already normalized). The SSD path needs a division by screen dimensions. Neither is expensive.

**Example:**

```dart
// YOLO adapter (in onResult callback):
onResult: (results) {
  final ball = _pickBestBall(results); // filter by className
  if (ball != null) {
    final center = Offset(
      ball.normalizedBox.left + ball.normalizedBox.width / 2,
      ball.normalizedBox.top + ball.normalizedBox.height / 2,
    );
    setState(() => _tracker.update(center));
  } else {
    setState(() => _tracker.markOccluded());
  }
},

// SSD adapter (in resultsStream listener):
_objectDetectorStream = detector.resultsStream.listen((objects) {
  final ball = _pickBestBall(objects); // filter by label
  if (ball != null) {
    final previewSize = ScreenParams.screenPreviewSize;
    final center = Offset(
      ball.renderLocation.center.dx / previewSize.width,
      ball.renderLocation.center.dy / previewSize.height,
    );
    if (mounted) setState(() {
      detectedObjectList = objects;
      _tracker.update(center);
    });
  } else {
    if (mounted) setState(() => _tracker.markOccluded());
  }
});
```

### Pattern 2: Time-Windowed Trail History in BallTracker

**What:** `BallTracker` stores `List<TrackedPosition>` capped by age (2–3 seconds), not by count. Every `update()` call appends a new position and prunes entries older than the window. `markOccluded()` appends a sentinel value that tells `TrailOverlay` to break the line at that point.

**When to use:** Fading trail must show only recent movement. Time-based pruning is more correct than count-based pruning because frame rate varies between pipelines and devices.

**Trade-offs:** Requires storing `DateTime.now()` per position. Negligible memory overhead (30 fps × 3 sec = 90 positions maximum at float64 × 2 = ~1.4 KB).

**Example:**

```dart
// lib/models/tracked_position.dart
class TrackedPosition {
  final Offset normalizedCenter; // 0.0–1.0 on both axes
  final DateTime timestamp;
  final bool isOccluded; // true = break the trail line here

  const TrackedPosition({
    required this.normalizedCenter,
    required this.timestamp,
    this.isOccluded = false,
  });
}

// lib/services/ball_tracker.dart
class BallTracker {
  final Duration trailWindow;
  final _history = <TrackedPosition>[];

  BallTracker({this.trailWindow = const Duration(seconds: 3)});

  List<TrackedPosition> get trail => List.unmodifiable(_history);

  void update(Offset normalizedCenter) {
    _history.add(TrackedPosition(
      normalizedCenter: normalizedCenter,
      timestamp: DateTime.now(),
    ));
    _prune();
  }

  void markOccluded() {
    // Only add a gap sentinel if the previous position was not already a gap
    if (_history.isNotEmpty && !_history.last.isOccluded) {
      _history.add(TrackedPosition(
        normalizedCenter: _history.last.normalizedCenter,
        timestamp: DateTime.now(),
        isOccluded: true,
      ));
    }
    _prune();
  }

  void _prune() {
    final cutoff = DateTime.now().subtract(trailWindow);
    _history.removeWhere((p) => p.timestamp.isBefore(cutoff));
  }

  void reset() => _history.clear();
}
```

### Pattern 3: TrailOverlay as Stateless CustomPainter in a Stack

**What:** `TrailOverlay` is a `CustomPainter` wrapped in a `CustomPaint` widget, placed in a `Stack` on top of `YOLOView` (YOLO path) or `CameraPreview` (SSD path). It receives a `List<TrackedPosition>` and the `Size` of the canvas. It maps normalized coords to canvas pixels internally and paints dots with age-based opacity.

**When to use:** Trail visualization is pure draw-on-every-frame with no widget subtree. `CustomPainter` is the correct tool — zero widget allocation overhead per frame.

**Trade-offs:** `shouldRepaint` must return true whenever trail changes (always during live detection). This is correct and expected — we want to repaint every time new tracking data arrives.

**Example:**

```dart
// lib/screens/live_object_detection/widgets/trail_overlay.dart
class TrailOverlay extends CustomPainter {
  final List<TrackedPosition> trail;
  final Duration trailWindow;

  TrailOverlay({required this.trail, required this.trailWindow});

  @override
  void paint(Canvas canvas, Size size) {
    if (trail.isEmpty) return;

    final now = DateTime.now();
    final windowMs = trailWindow.inMilliseconds.toDouble();

    // Draw connecting line segments
    final linePaint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < trail.length; i++) {
      final prev = trail[i - 1];
      final curr = trail[i];
      if (prev.isOccluded || curr.isOccluded) continue; // gap in path

      final age = now.difference(curr.timestamp).inMilliseconds.toDouble();
      final opacity = (1.0 - age / windowMs).clamp(0.0, 1.0);

      linePaint.color = Colors.orange.withValues(alpha: opacity * 0.7);
      canvas.drawLine(
        _toPixel(prev.normalizedCenter, size),
        _toPixel(curr.normalizedCenter, size),
        linePaint,
      );
    }

    // Draw dot at each non-occluded position
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (final pos in trail) {
      if (pos.isOccluded) continue;
      final age = now.difference(pos.timestamp).inMilliseconds.toDouble();
      final opacity = (1.0 - age / windowMs).clamp(0.0, 1.0);
      final radius = 5.0 * opacity + 2.0; // shrink with age
      dotPaint.color = Colors.orange.withValues(alpha: opacity);
      canvas.drawCircle(_toPixel(pos.normalizedCenter, size), radius, dotPaint);
    }
  }

  Offset _toPixel(Offset normalized, Size size) =>
      Offset(normalized.dx * size.width, normalized.dy * size.height);

  @override
  bool shouldRepaint(TrailOverlay old) => trail != old.trail;
}
```

**Widget tree placement (YOLO path):**

```dart
Stack(
  fit: StackFit.expand,
  children: [
    YOLOView(
      modelPath: ...,
      task: YOLOTask.detect,
      showOverlays: false, // disable native boxes so trail is the only custom rendering
      onResult: _handleYoloResult,
    ),
    CustomPaint(
      painter: TrailOverlay(
        trail: _tracker.trail,
        trailWindow: const Duration(seconds: 3),
      ),
    ),
    // backend label badge (existing)
    Positioned(top: 12, left: 12, child: ...),
  ],
)
```

**Widget tree placement (SSD path):**

```dart
AspectRatio(
  aspectRatio: 1 / controller.value.aspectRatio,
  child: Stack(
    fit: StackFit.expand,
    children: [
      CameraPreview(controller),
      // existing bounding boxes
      ...?detectedObjectList?.map((obj) => Positioned.fromRect(
        rect: obj.renderLocation,
        child: BoxWidget.fromDetectedObject(obj),
      )),
      // trail overlay — same CustomPainter, same normalized coords
      CustomPaint(
        painter: TrailOverlay(
          trail: _tracker.trail,
          trailWindow: const Duration(seconds: 3),
        ),
      ),
      // backend label badge (existing)
      Positioned(top: 12, left: 12, child: ...),
    ],
  ),
)
```

---

## Data Flow

### YOLO Path — Frame to Trail

```
Camera (hardware) → YOLOView (native iOS/Android thread)
    ↓ onResult callback fires on UI thread
List<YOLOResult> (one per frame)
    ↓ _pickBestBall() — filter to "Soccer ball", "ball"
YOLOResult.normalizedBox → center Offset (0.0–1.0)
    ↓ setState(() => _tracker.update(normalizedCenter))
BallTracker._history updated, old entries pruned
    ↓ setState triggers build()
TrailOverlay.paint() called with updated trail list
    ↓ canvas maps normalizedCenter → pixel Offset via Size
Fading trail drawn on screen
```

### SSD Path — Frame to Trail

```
Camera (hardware) → CameraController.imageStream
    ↓ onLatestImageAvailable → Detector.processFrame()
Detector isolate: CameraImage → TensorflowHelper → List<DetectedObjectDm>
    ↓ resultsStream emits on UI isolate
List<DetectedObjectDm>
    ↓ _pickBestBall() — filter by label containing "ball"
DetectedObjectDm.renderLocation.center → normalize by ScreenParams.screenPreviewSize
    ↓ setState(() { detectedObjectList = objects; _tracker.update(normalized); })
BallTracker._history updated, old entries pruned
    ↓ setState triggers build()
TrailOverlay.paint() called — same painter, same normalized coords
    ↓ canvas maps normalizedCenter → pixel Offset via Size
Fading trail drawn on screen
```

### Occlusion Flow (both pipelines)

```
Frame arrives → no ball detection found
    ↓ _pickBestBall() returns null
setState(() => _tracker.markOccluded())
    ↓ BallTracker appends isOccluded=true sentinel (if last was not already occluded)
TrailOverlay.paint() skips drawLine for segments crossing an occluded point
    ↓ visible gap appears in trail path
Next frame with detection → _tracker.update() resumes normally
    ↓ trail continues from new position (no line connecting the gap)
```

### State Ownership

State lives in `_LiveObjectDetectionScreenState` via `setState`. No new MobX is introduced — the existing architecture rule (MobX only on Home Screen) is respected. `BallTracker` is instantiated as a field of the screen state and is not a singleton.

```dart
class _LiveObjectDetectionScreenState extends State<LiveObjectDetectionScreen> {
  // existing fields ...
  final _tracker = BallTracker(trailWindow: const Duration(seconds: 3));
  // ...
}
```

---

## Coordinate Systems — Critical Details

| Pipeline | Detection Output | Coordinate System | Trail Input Format |
|----------|-----------------|-------------------|--------------------|
| YOLO | `YOLOResult.normalizedBox` (Rect) | 0.0–1.0 per axis | Center: `Offset((l + r) / 2, (t + b) / 2)` — already normalized |
| SSD | `DetectedObjectDm.renderLocation` (Rect) | Screen pixels (scaled by `ScreenParams`) | Center: `Offset(cx / previewSize.width, cy / previewSize.height)` — must normalize |
| Trail painter | `TrackedPosition.normalizedCenter` (Offset) | 0.0–1.0 | Mapped to canvas pixels: `Offset(nx * size.width, ny * size.height)` |

Both pipelines feed `BallTracker` in normalized form. `TrailOverlay` works in normalized form and maps to pixels internally using the `Size` that Flutter passes to `paint()`. This means the trail painter is correct regardless of device screen size, aspect ratio, or landscape/portrait.

**YOLO landscape consideration:** In landscape mode, the `YOLOView` fills `StackFit.expand`. The `Size` passed to `TrailOverlay.paint()` is the landscape screen size. Since `normalizedBox` is relative to the camera frame as rendered by `YOLOView`, the mapping is correct without additional rotation transforms — `YOLOView` handles orientation internally.

**SSD path note:** `ScreenParams.screenPreviewSize` reflects the portrait AspectRatio widget's dimensions (not the full screen). The `CustomPaint` widget wrapping `TrailOverlay` in the SSD Stack is inside the same AspectRatio, so `size` in `paint()` matches the denominator used for normalization. Coordinates are consistent.

---

## Integration Points

### What Changes in `LiveObjectDetectionScreen`

| Location | Change | Type |
|----------|--------|------|
| Field declarations | Add `final _tracker = BallTracker(...)` | New field |
| YOLO `onResult` callback | Replace `log()` with `_pickBestBall()` + `_tracker.update/markOccluded` + `setState` | Replace body |
| YOLO `build()` Stack | Add `CustomPaint(painter: TrailOverlay(...))` above `YOLOView` | New widget in tree |
| YOLO `YOLOView` | Add `showOverlays: false` parameter | New parameter |
| SSD `resultsStream` listener | Add `_pickBestBall()` + `_tracker.update/markOccluded` alongside existing `detectedObjectList` | Extend listener |
| SSD `build()` Stack | Add `CustomPaint(painter: TrailOverlay(...))` above bounding boxes | New widget in tree |
| `dispose()` | Add `_tracker.reset()` (optional, GC handles it) | Minor cleanup |

### New Components Required

| Component | File | Depends On |
|-----------|------|------------|
| `TrackedPosition` | `lib/models/tracked_position.dart` | `dart:ui` (Offset, DateTime) only |
| `BallTracker` | `lib/services/ball_tracker.dart` | `TrackedPosition` only |
| `TrailOverlay` | `lib/screens/live_object_detection/widgets/trail_overlay.dart` | `TrackedPosition`, `BallTracker.trail` |
| `_pickBestBall()` helper | private method in `_LiveObjectDetectionScreenState` | `YOLOResult` (YOLO path) or `DetectedObjectDm` (SSD path) |

### What Is Explicitly Not Changed

- `lib/config/detector_config.dart` — no backend switching logic changes
- `lib/services/detector.dart` — isolate and inference unchanged
- `lib/services/tensorflow_service.dart` — model loading unchanged
- `lib/models/detected_object/detected_object_dm.dart` — model unchanged
- `lib/widgets/box_widget.dart` — SSD bounding boxes unchanged
- `pubspec.yaml` — no new dependencies needed

---

## Anti-Patterns

### Anti-Pattern 1: Separate Tracker Per Pipeline

**What people do:** Create `YoloBallTracker` and `SsdbBallTracker` as distinct classes because the input types differ.

**Why it's wrong:** Doubles the implementation surface for identical logic (history management, occlusion, pruning). Any change to trail behavior (window length, occlusion rules) must be made in two places.

**Do this instead:** Normalize both inputs to `Offset` (0.0–1.0) before they reach `BallTracker`. The tracker sees one type and one interface. The normalization is a one-liner at each call site.

### Anti-Pattern 2: Storing Screen-Pixel Coords in Trail History

**What people do:** Store `renderLocation.center` (pixels) directly from `DetectedObjectDm` in the trail history, then pass raw pixels to the painter.

**Why it's wrong:** If `ScreenParams.screenPreviewSize` changes (orientation, resize), all historical positions become wrong relative to the current canvas size. The trail drifts visually. Also makes the YOLO path's normalized coords incompatible with the SSD path's pixel coords — can't share one painter.

**Do this instead:** Always normalize to 0.0–1.0 before storing. The painter multiplies by `size` at draw time, so it's always correct relative to the current canvas.

### Anti-Pattern 3: Running Trail Logic in `CustomPainter.paint()`

**What people do:** Put trail pruning, occlusion detection, or history management inside `paint()`.

**Why it's wrong:** `paint()` is called on the raster thread and must be fast. It must be a pure function of its inputs — same inputs always produce same output. Side effects in `paint()` (mutating state, calling `DateTime.now()` for pruning) cause unpredictable rendering.

**Do this instead:** All mutation happens in `BallTracker` during `setState`. `paint()` only reads `trail` and calls `canvas` APIs. The age-based opacity calculation in `paint()` calls `DateTime.now()` for display only (not for mutation) — this is acceptable.

### Anti-Pattern 4: Introducing MobX into TrackingState

**What people do:** Add `@observable List<TrackedPosition> trail` to a new MobX store because "it's reactive state."

**Why it's wrong:** Violates the established project rule (MobX only on Home Screen). Also unnecessary — `setState` in the screen is sufficient. Tracking state doesn't need cross-screen reactivity.

**Do this instead:** `BallTracker` is a plain Dart class held as a field of `_LiveObjectDetectionScreenState`. Trail updates trigger `setState`. No MobX needed.

### Anti-Pattern 5: `showOverlays: true` with a Custom Trail

**What people do:** Leave `showOverlays: true` on `YOLOView` and add the trail painter on top, resulting in native bounding boxes + trail overlay both rendering simultaneously.

**Why it's wrong:** For this POC the visual result is acceptable but confusing for evaluation — native boxes and custom trail both compete for attention. The native boxes flash per-frame (re-rendered by native code) while the trail is smooth Flutter paint. For the tracking milestone, the custom overlay is the evaluation target.

**Do this instead:** Set `showOverlays: false` on `YOLOView` when the trail overlay is active. This makes the trail painter the sole custom UI. If bounding boxes are also needed, render them in the same Flutter `CustomPainter` alongside the trail.

---

## Build Order for Implementation

Dependencies flow in one direction. Build bottom-up:

```
1. TrackedPosition (lib/models/tracked_position.dart)
   — No dependencies on other new code. Can be built and tested in isolation.

2. BallTracker (lib/services/ball_tracker.dart)
   — Depends on TrackedPosition only.
   — Unit-testable without Flutter: create a tracker, call update/markOccluded, assert trail contents.

3. TrailOverlay (lib/screens/live_object_detection/widgets/trail_overlay.dart)
   — Depends on TrackedPosition.
   — Can be developed and visually tested with a hardcoded trail list before wiring live data.

4. LiveObjectDetectionScreen modifications
   — Wire YOLO path first (simpler: normalizedBox is already the right format).
   — Wire SSD path second (needs normalization step).
   — Replace log() in onResult with real tracking call.
   — Add showOverlays: false to YOLOView.
   — Add CustomPaint to both Stack trees.
```

**Why YOLO first:** The YOLO pipeline's `onResult` fires on the UI thread with `normalizedBox` already in the right format. Zero coordinate math needed. Fastest path to a visible trail. SSD path needs the normalization division and an understanding of when `ScreenParams.screenPreviewSize` is valid (after `_init()` completes).

---

## Scaling Considerations

This is a single-device POC. Scaling in the traditional sense does not apply. The relevant performance ceiling is frame rate on target hardware.

| Concern | At 30 FPS (iPhone 12 target) | At 15 FPS (A32 typical) |
|---------|------------------------------|-------------------------|
| Trail history entries | ~90 entries (3 sec × 30fps) | ~45 entries |
| Memory per trail | ~90 × (16 + 8) bytes = ~2.2 KB | ~1.1 KB |
| `paint()` time per frame | 90 drawCircle + 89 drawLine calls — sub-millisecond on GPU | Same, lower concurrency |
| `BallTracker.update()` time | O(n) pruning on ~90 entries — negligible | Same |
| `setState` cost | Full `build()` of Stack + descendants — acceptable, same as existing SSD path | Same |

No performance mitigations are needed for the POC scope. If jank appears on the A32, the first optimization is reducing trail window to 1.5 seconds (45 entries at 30fps) before any architectural change.

---

## Sources

- ultralytics_yolo pub.dev package page: [https://pub.dev/packages/ultralytics_yolo](https://pub.dev/packages/ultralytics_yolo)
- YOLOResult source on GitHub (confirmed boundingBox + normalizedBox): [https://github.com/ultralytics/yolo-flutter-app/blob/main/lib/models/yolo_result.dart](https://github.com/ultralytics/yolo-flutter-app/blob/main/lib/models/yolo_result.dart)
- YOLOView constructor parameters (confirmed showOverlays parameter): [https://github.com/ultralytics/yolo-flutter-app/blob/main/lib/yolo_view.dart](https://github.com/ultralytics/yolo-flutter-app/blob/main/lib/yolo_view.dart)
- Issue confirming showOverlays feature shipped: [https://github.com/ultralytics/yolo-flutter-app/issues/255](https://github.com/ultralytics/yolo-flutter-app/issues/255)
- Flutter CustomPaint API: [https://api.flutter.dev/flutter/widgets/CustomPaint-class.html](https://api.flutter.dev/flutter/widgets/CustomPaint-class.html)
- Codebase read directly: `lib/screens/live_object_detection/live_object_detection_screen.dart`, `lib/services/detector.dart`, `lib/models/detected_object/detected_object_dm.dart`, `lib/models/screen_params.dart`, `lib/config/detector_config.dart`

---

*Architecture research for: Flutter dual-pipeline ball tracking with fading trail overlay*
*Researched: 2026-02-23*
