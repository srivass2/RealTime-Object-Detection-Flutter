# Project Research Summary

**Project:** Flare Football Object Detection POC — v1.1 Ball Tracking
**Domain:** Flutter on-device ML — frame-to-frame ball tracking with fading visual trail overlay
**Researched:** 2026-02-23
**Confidence:** HIGH

## Executive Summary

This milestone adds real-time ball tracking with a fading visual trail to an existing Flutter POC that already has a working dual-pipeline detection architecture (YOLO11n and SSD MobileNet). The research confirms that everything needed — `CustomPainter`, `AnimationController`, `ListQueue`, `Stack` overlays — is available in the Flutter SDK itself. No new packages are required. The implementation pattern is well-established in both the OpenCV sports-tracking literature (PyImageSearch 32-frame deque, null-sentinel occlusion) and in Flutter-specific real-time overlay work.

The recommended approach is a bottom-up build: `TrackedPosition` value type first, then a pipeline-agnostic `BallTracker` service class, then a `TrailOverlay` CustomPainter, and finally wiring both detection paths into the screen. Both YOLO and SSD pipelines feed the same tracker via a one-line normalization adapter — the YOLO path uses `normalizedBox` directly (already 0–1), the SSD path divides `renderLocation` by `ScreenParams.screenPreviewSize`. Normalized coordinates are stored in the tracker and denormalized to pixels only at paint time inside the CustomPainter, ensuring correctness across device orientations and screen sizes.

The dominant risks are not algorithmic — they are integration gotchas specific to this codebase. Four issues must be resolved before any trail logic is built: (1) confirming that a Flutter `Stack` child renders visibly above `YOLOView` (platform view Z-order is not guaranteed on all Android rendering modes), (2) verifying that `YOLOView.onResult` coordinate values map correctly to screen position on both iOS and Android (known per-platform offset bug in issue #105), (3) ensuring all detection callbacks guard against `setState()` after `dispose()` with `if (!mounted) return`, and (4) explicitly locking the SSD path to portrait to avoid the `ScreenParams` landscape coordinate break. None of these are blockers — all have documented solutions — but they must be addressed in Phase 1 before trail accumulation begins.

---

## Key Findings

### Recommended Stack

The entire implementation uses Flutter SDK built-ins. No new `pubspec.yaml` entries are needed. The key additions are: `dart:collection ListQueue` for the bounded position history buffer (O(1) add/remove), `CustomPainter` + `CustomPaint` for trail rendering on a transparent canvas layer above the camera view, `AnimationController` with `TickerProviderStateMixin` to drive per-frame repaints at vsync-synchronized 60/120 Hz, and `RepaintBoundary` to scope repaints to the trail layer only — critical for performance on Galaxy A32.

**Core technologies:**
- `dart:collection ListQueue`: position history buffer — O(1) amortized add/remove, no external package needed
- `CustomPainter` + `CustomPaint`: trail rendering — canonical Flutter 2D canvas; zero widget allocation per frame
- `AnimationController` (vsync): repaint driver — frame-synchronized ticks; `Timer.periodic` would drift at 60 Hz and must NOT be used
- `RepaintBoundary`: repaint isolation — wraps the trail layer so camera frames do not cascade a full-tree repaint
- `Stack` + `IgnorePointer`: overlay placement — existing pattern in the codebase; trail must not consume touch events
- `dart:ui Offset`, `Rect`, `Canvas`, `Paint`: coordinate and drawing primitives — already available

See `.planning/research/STACK.md` for full alternatives analysis and version compatibility table.

### Expected Features

The v1.1 milestone must deliver enough to answer the research question: "Is frame-to-frame tracking with a fading trail feasible on-device at acceptable performance?" Research identifies a clear MVP boundary and a set of post-validation additions.

**Must have (v1.1 table stakes):**
- Center-point extraction from `YOLOResult.normalizedBox` (YOLO path) — prerequisite for everything else
- Center-point extraction from `DetectedObjectDm.renderLocation` normalized by `ScreenParams` (SSD path)
- `BallTracker` service: normalized `Offset?` input, bounded position queue (max 45 entries, ~1.5s at 30fps), occlusion sentinel (`null`/`isOccluded` flag), auto-clear after 30 consecutive missed frames
- `TrailPainter` (`CustomPainter`): dots with fading opacity + tapering radius, polyline skipping null/occluded segments
- Trail overlay on both YOLO and SSD paths independently (no cross-pipeline shared state)
- Normalized coordinate storage throughout; denormalize only at paint time
- Landscape layout respected for YOLO path; SSD path locked to portrait

**Should have (add after table stakes are stable, within v1.1 if time allows):**
- "Ball lost" badge overlay — communicates model loss vs. genuine off-camera
- Bounding box center dot (current-frame marker) — aids trail readability in evaluation recordings
- EMA smoothing — only if evaluation recordings show excessive jitter; not a pre-optimization

**Defer (v2+, real product scope):**
- Kalman filter predictive tracking — significant complexity, needs per-device tuning
- Trail color by speed — requires calibrated pixel-to-world mapping to be meaningful
- Multi-ball tracking with stable IDs — separate research problem
- Configurable trail length UI control — POC does not need runtime tuning

See `.planning/research/FEATURES.md` for full feature dependency graph and prioritization matrix.

### Architecture Approach

The architecture is a clean three-layer addition on top of the existing screen: a `TrackedPosition` value type (no Flutter dependencies), a `BallTracker` service class (plain Dart, no ML dependencies, held as a field of `_LiveObjectDetectionScreenState`), and a `TrailOverlay` CustomPainter widget (screen-specific, co-located with the screen in `lib/screens/live_object_detection/widgets/`). Each detection pipeline has a one-line adapter that converts its native result format to a normalized `Offset` before calling `tracker.update()`. Both pipelines then feed the same `BallTracker` and the same `TrailOverlay` painter, with zero cross-pipeline dependencies.

**Major components:**
1. `TrackedPosition` (`lib/models/tracked_position.dart`) — value type: `normalizedCenter: Offset`, `timestamp: DateTime`, `isOccluded: bool`; no dependencies; fully unit-testable
2. `BallTracker` (`lib/services/ball_tracker.dart`) — accepts normalized `Offset?` per frame; maintains time-windowed history (3-second trail window); handles occlusion via sentinel values; `reset()` on dispose
3. `TrailOverlay` (`lib/screens/live_object_detection/widgets/trail_overlay.dart`) — `CustomPainter`; age-based opacity via `DateTime.now()` in `paint()`; skips line segments crossing occluded points; maps normalized coords to canvas pixels via `Size`
4. `_pickBestBall()` helper (private method in screen state) — filters by class name priority (`Soccer ball` > `ball`; rejects `tennis-ball`), then picks nearest-to-last-known-position as tiebreaker
5. `LiveObjectDetectionScreen` modifications — wires `_tracker` into both pipeline callbacks; adds `CustomPaint` to both Stack trees; sets `showOverlays: false` on `YOLOView`

**Build order (bottom-up, each layer testable before the next):**
1. `TrackedPosition` — no dependencies
2. `BallTracker` — depends on `TrackedPosition` only; unit-testable without Flutter
3. `TrailOverlay` — can be developed with a hardcoded trail before live data is wired
4. `LiveObjectDetectionScreen` changes — YOLO path first (zero coordinate math), then SSD path

See `.planning/research/ARCHITECTURE.md` for full data flow diagrams, coordinate system table, and complete code stubs for all components.

### Critical Pitfalls

7 pitfalls were identified. The top 5 by risk and phase impact:

1. **YOLOView native overlay not disabled** — Flutter `CustomPaint` and native bounding boxes both render simultaneously, producing visual incoherence. Prevention: set `showOverlays: false` on `YOLOView`; confirm the parameter exists in `ultralytics_yolo ^0.2.0` by reading the pub-cache source before writing any trail code. Phase 1 gate.

2. **Coordinate space mismatch between `onResult` data and overlay canvas** — Known platform-specific offset bugs (GitHub issue #105) cause trail dots to appear offset from the actual ball. `ScreenParams` was designed for portrait and breaks under landscape. Prevention: verify coordinate mapping with a single debug dot on both iOS and Android before building trail accumulation. Phase 1 gate.

3. **`setState()` called after dispose** — YOLO `onResult` and SSD `resultsStream` callbacks can deliver results after the screen is disposed when navigating away. Prevention: `if (!mounted) return;` must be the first line of every detection callback. Already present in the SSD stream listener; must be added to `onResult`. Phase 1 gate.

4. **Unbounded trail `List` causes memory growth and paint jank** — At 30fps, an uncapped `List.add` produces 900–1800 entries per minute. Paint time grows linearly; jank appears after ~60 seconds on Galaxy A32. Prevention: use `Queue` or `ListQueue` with a hard cap from the first commit. Never add an unbounded trail list. Phase 2 must-have.

5. **Class label ambiguity — tracking the wrong detection** — `results.first` or `results.maxBy(confidence)` can pick a stationary `tennis-ball` over the moving soccer ball. Prevention: filter to `Soccer ball` and `ball` only; use nearest-to-last-known-position as tiebreaker with a maximum-distance threshold for occlusion detection. Phase 2 requirement.

See `.planning/research/PITFALLS.md` for full pitfall descriptions, warning signs, recovery costs, and the complete "looks done but isn't" checklist.

---

## Implications for Roadmap

Based on combined research, the dependency structure mandates a two-phase build with a clear Phase 1 guard before any trail state is accumulated.

### Phase 1: Overlay Architecture and Coordinate Validation

**Rationale:** Three Phase 1 pitfalls (native overlay conflict, coordinate mismatch, disposal race) are prerequisite correctness gates. Building trail accumulation on top of broken coordinates produces work that must be entirely discarded. Architecture research explicitly documents this build order. These are quick to validate but catastrophically expensive to fix after trail logic is built on top.

**Delivers:** A confirmed, correct foundation — a Flutter overlay visibly renders above `YOLOView` on both platforms; a single debug dot reliably centers on the ball in real-time on both iOS (iPhone 12) and Android (Galaxy A32); all detection callbacks include `mounted` guards; SSD path orientation is locked and documented; `showOverlays: false` is confirmed available and applied.

**Addresses (from FEATURES.md):** Center-point extraction (YOLO), center-point extraction (SSD), normalized coordinate storage. These table stakes features are proven correct here before trail accumulation is added.

**Avoids (from PITFALLS.md):** Pitfall 1 (native overlay conflict), Pitfall 2 (coordinate mismatch), Pitfall 5 (disposal race condition), Pitfall 7 (SSD landscape coordinate break).

**Research flag:** Standard patterns, no additional research needed. Flutter platform view overlay and coordinate normalization are well-documented.

---

### Phase 2: Trail Accumulation and Rendering

**Rationale:** Trail logic depends entirely on Phase 1 correctness. Once coordinates are proven valid, the `BallTracker` → `TrailOverlay` implementation follows a well-documented pattern (PyImageSearch deque + null-sentinel + CustomPainter opacity gradient). The architecture research provides complete code stubs for all three new components. Build order is dictated by dependencies: `TrackedPosition` first, then `BallTracker`, then `TrailOverlay`, then wire into screen.

**Delivers:** Full v1.1 MVP — bounded position queue, occlusion gap handling (null sentinels), fading dot trail with radius taper, auto-clear on 30+ consecutive missed frames, trail overlay on both YOLO and SSD paths independently.

**Uses (from STACK.md):** `ListQueue` for bounded history, `CustomPainter` + `RepaintBoundary` for isolated trail rendering, `shouldRepaint` implementation to avoid spurious repaints.

**Implements (from ARCHITECTURE.md):** `TrackedPosition`, `BallTracker`, `TrailOverlay`, `_pickBestBall()` helper with class priority filter and nearest-neighbor tiebreaker.

**Avoids (from PITFALLS.md):** Pitfall 3 (unbounded list — `Queue` cap mandatory from first commit), Pitfall 4 (full-tree repaint — `shouldRepaint` and `RepaintBoundary` required), Pitfall 6 (class label ambiguity — `_pickBestBall()` filter built in).

**Research flag:** Standard patterns, no additional research needed. All implementation patterns are documented in ARCHITECTURE.md with complete code stubs.

---

### Phase 3: Polish and Post-Validation Enhancements (if POC continues)

**Rationale:** These features add evaluator-facing value but do not affect the core research question. Build only after Phase 2 trail is validated in evaluation recordings on both target devices.

**Delivers:** "Ball lost" badge overlay, bounding box center dot (current-frame marker), optional EMA smoothing if jitter is observed in recordings.

**Addresses (from FEATURES.md):** P2 priority features — all verified as low complexity, additive to existing trail without architectural changes.

**Avoids:** Performance trap of `AnimationController` ticking at 60fps (use timestamp-based opacity in `paint()` instead of a separate ticker).

**Research flag:** Standard patterns, skip research-phase. These are straightforward Flutter UI additions with no new architectural concerns.

---

### Phase Ordering Rationale

- **Phase 1 before Phase 2 is non-negotiable.** Coordinate validation is a correctness prerequisite. The PITFALLS.md research is explicit: "Write a coordinate normalizer before any trail state management." Building `BallTracker` on wrong coordinates requires discarding all trail logic and starting over.
- **YOLO path before SSD path within Phase 2.** `YOLOResult.normalizedBox` is already in 0–1 space — zero coordinate math, fastest path to a visible trail. SSD path requires the `ScreenParams` normalization division and depends on `_init()` having completed before `screenPreviewSize` is valid.
- **`TrackedPosition` before `BallTracker` before `TrailOverlay`.** Dependencies flow in one direction. Each layer is independently testable before the next is wired.
- **No Phase 3 features before Phase 2 is evaluated.** EMA smoothing in particular must not be added pre-emptively — it adds lag and should only be introduced if evaluation recordings show actual jitter.

### Research Flags

Phases likely needing deeper research during planning:
- **None identified.** All phases use well-documented Flutter SDK patterns and architecture decisions supported by direct source code inspection of `ultralytics_yolo ^0.2.0`.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Flutter platform view overlay and coordinate normalization — documented in official Flutter platform integration docs and ultralytics_yolo GitHub source.
- **Phase 2:** `CustomPainter` trail rendering with `ListQueue` — PyImageSearch canonical pattern directly applicable; complete code stubs in ARCHITECTURE.md.
- **Phase 3:** UI badge and center dot — trivial Flutter widgets; no research needed.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All technologies are Flutter SDK built-ins; no version compatibility concerns. `YOLOResult.normalizedBox` confirmed by direct pub-cache source inspection. No new packages = no supply chain risk. |
| Features | MEDIUM-HIGH | MVP boundary is clear and well-justified. Table stakes features are confirmed against official YOLO Flutter API docs and PyImageSearch canonical implementations. P2 features are additive and low-risk. |
| Architecture | HIGH | Codebase read directly; `ultralytics_yolo` source inspected; `YOLOResult` field names confirmed. Complete code stubs provided for all 3 new components. Two anti-patterns (separate tracker per pipeline, pixel coord storage) have documented counter-examples. |
| Pitfalls | HIGH | 5 of 7 pitfalls sourced from official Flutter docs + GitHub issues in the exact packages used. `showOverlays: false` availability confirmed via GitHub issue #255. Coordinate offset bug confirmed via issue #105. |

**Overall confidence:** HIGH

### Gaps to Address

- **`showOverlays: false` exact API:** Research confirms the parameter was requested (issue #255) and architecture assumes it exists in `^0.2.0`. The very first step of Phase 1 must verify this by reading the installed pub-cache source for `YOLOView` constructor. If the parameter is not present, Phase 1 pivots to a platform plugin patch (medium complexity, documented recovery path in PITFALLS.md).

- **`onResult` coordinate accuracy on Galaxy A32:** Issue #105 documents platform-specific coordinate offsets but does not provide an exact correction formula for Android. Phase 1 must empirically verify coordinates with the debug dot on the actual A32 device. If offset correction is needed, it can be applied as a one-time calibration multiplier in `_pickBestBall()`.

- **`ScreenParams.screenPreviewSize` timing:** The SSD path wires `ScreenParams` in `_init()`. Phase 2 SSD trail wiring must confirm `screenPreviewSize` is valid (non-null, non-zero) before the first `resultsStream` event arrives. If events can arrive before `_init()` completes, a null-guard is needed in the SSD adapter.

---

## Sources

### Primary (HIGH confidence)
- `~/.pub-cache/hosted/pub.dev/ultralytics_yolo-0.2.0/lib/models/yolo_result.dart` — confirmed `YOLOResult.normalizedBox: Rect`, `YOLOResult.className: String`, `YOLOResult.confidence: double` fields
- `~/.pub-cache/hosted/pub.dev/ultralytics_yolo-0.2.0/lib/yolo_view.dart` — confirmed `onResult: Function(List<YOLOResult>)?`, `showOverlays` parameter, `Stack`-based build
- [Flutter API — CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html) — `repaint`, `shouldRepaint`, `paint(Canvas, Size)` lifecycle
- [Flutter API — AnimationController](https://api.flutter.dev/flutter/animation/AnimationController-class.html) — vsync-aware ticker lifecycle
- [Flutter API — RepaintBoundary](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html) — repaint scoping for overlays
- [Flutter API — ListQueue](https://api.flutter.dev/flutter/dart-collection/ListQueue-class.html) — O(1) add/remove, bounded ring-buffer behavior
- [Flutter Docs — Platform Views (Android)](https://docs.flutter.dev/platform-integration/android/platform-views) — Z-order behavior of Flutter widgets above PlatformViewSurface
- Existing codebase: `lib/screens/live_object_detection/live_object_detection_screen.dart`, `lib/services/detector.dart`, `lib/models/detected_object/detected_object_dm.dart`, `lib/models/screen_params.dart`, `lib/config/detector_config.dart`

### Secondary (MEDIUM confidence)
- [ultralytics/yolo-flutter-app issue #255](https://github.com/ultralytics/yolo-flutter-app/issues/255) — `showOverlays` parameter availability confirmation
- [ultralytics/yolo-flutter-app issue #105](https://github.com/ultralytics/yolo-flutter-app/issues/105) — coordinate offset bug on Android (platform-specific correction needed)
- [OpenCV Track Object Movement — PyImageSearch](https://pyimagesearch.com/2015/09/21/opencv-track-object-movement/) — canonical 32-frame deque, `None` sentinel, thickness taper formula
- [Ball Tracking in Sports — Roboflow](https://blog.roboflow.com/tracking-ball-sports-computer-vision/) — buffer-of-positions trail pattern, color interpolation
- [Approached 60 FPS Object Detection on Mobile — Medium](https://medium.com/@cia1099/approached-60-fps-object-detection-without-any-frame-dropout-on-mobile-devices-with-flutter-6ab3c9dc5c4b) — `RepaintBoundary` + `CustomPaint` viability at detection frame rates
- [Flutter CustomPainter Animation — Codemagic Blog](https://blog.codemagic.io/flutter-custom-painter/) — `withOpacity`, `canvas.drawCircle`, `canvas.drawLine`, `repaint` parameter

### Tertiary (LOW confidence)
- [Label Your Data — Object Tracking Overview](https://labelyourdata.com/articles/machine-learning/object-tracking) — ByteTrack, Kalman filter patterns (out of scope but useful for understanding the gap between POC and production)

---
*Research completed: 2026-02-23*
*Ready for roadmap: yes*
