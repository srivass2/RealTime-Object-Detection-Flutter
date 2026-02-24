# GSD State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-23)

**Core value:** Real-time soccer ball detection and tracking must run on-device with acceptable speed and accuracy on both iOS and Android
**Current focus:** Phase 8 — Polish (Phase 7 fully verified on device)

## Current Position

Phase: 8 of 8 (Polish) — COMPLETE
Plan: 1 of 1 complete (all tasks executed + device verified on iPhone 12)
Status: All phases complete; v1.1 ball tracking milestone fully delivered and device-verified
Last activity: 2026-02-24 — Phase 8 Plan 01: device verified on iPhone 12, Positioned/IgnorePointer nesting bug fixed, "Ball lost overlay works perfectly"

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**
- Total plans completed: 5
- Average duration: ~13 min (including device testing iterations)
- Total execution time: ~59 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 06-overlay-foundation | 2/2 | ~6 min | ~3 min |
| 07-trail-accumulation-and-rendering | 3/3 | ~53 min | ~18 min (includes device testing + bug fix) |
| 08-polish | 1/1 | ~10 min | ~10 min (includes device testing + nesting bug fix) |

## Accumulated Context

### Decisions

- [v1.0]: YOLO path uses YOLOView (ultralytics_yolo); SSD path uses TFLite isolate — never mix pipelines
- [v1.0]: Landscape lock on YOLO screen is a matched initState/dispose pair — do not break
- [v1.1]: **SSD/TFLite path dropped from scope — YOLO only going forward on both iOS and Android** (model is old)
- [v1.1]: `showOverlays: false` confirmed working in ultralytics_yolo ^0.2.0
- [06-01]: DebugDotPainter is public (not file-private) since it lives in a separate file from the screen
- [06-01]: RepaintBoundary wraps CustomPaint for correct repaint isolation — not the other way around
- [06-02]: normalizedBox coordinates are relative to FULL camera frame; FILL_CENTER scaling (BoxFit.cover) crops one dimension. Must account for crop offset when mapping to widget pixels.
- [~~06-02~~] ~~Camera aspect ratio defaults to 16:9~~ **CORRECTED in 07-03**: Camera aspect ratio is **4:3** — ultralytics_yolo plugin uses `.photo` session preset on iOS (4032×3024). Using 16:9 caused ~10% Y-axis upward offset.
- [06-02]: Galaxy A32 testing deferred — Android SDK not configured on current Mac. Does not block Phase 8 (can verify later).
- [07-01]: YoloCoordUtils crop math extracted verbatim from DebugDotPainter — do not modify without re-validating on iPhone 12
- [07-01]: BallTracker._prune() must NOT reset _consecutiveMissedFrames — resetting it inside _prune() would suppress the 30-frame auto-reset (research Pitfall 3)
- [07-01]: TrackedPosition uses dart:ui Offset only (not flutter/painting.dart) — keeps the model free of Flutter widget framework for pure-Dart unit testability
- [Phase 07]: TrailOverlay shouldRepaint always returns true — BallTracker.trail List.unmodifiable() creates new wrapper each call; RepaintBoundary is the real performance guard
- [Phase 07]: tracked_position.dart import removed from screen — TrackedPosition consumed inside BallTracker/TrailOverlay only; direct screen import produces unused_import warning
- [Phase 07]: IgnorePointer wraps trail CustomPaint — prevents overlay from consuming touch events intended for YOLOView camera layer
- [07-03]: **Camera AR is 4:3** (not 16:9). ultralytics_yolo `.photo` session preset → 4032×3024 on iOS. cameraAspectRatio default changed in TrailOverlay, DebugDotPainter.
- [07-03]: Min-distance dedup threshold `_minDistSq = 0.000025` (0.5% of frame) added to BallTracker.update() — prevents dot clustering at ~30fps
- [Phase 08-polish]: ballLostThreshold = 3 frames (~100ms at 30fps) satisfies PLSH-01; isBallLost exposes boolean only; badge piggybacks on onResult setState; IgnorePointer wraps badge consistent with trail pattern
- [08-01]: **Positioned must be a direct Stack child** — IgnorePointer goes INSIDE Positioned, not outside. Wrapping Positioned in IgnorePointer causes Flutter assertion error at runtime.

### Pending Todos

None — all phases complete. v1.1 ball tracking milestone fully delivered.

### Blockers/Concerns

- [General]: Galaxy A32 testing deferred — Android SDK not configured on current Mac

## Session Continuity

Last session: 2026-02-24
Stopped at: Phase 8 fully complete (1/1 plans, device verified on iPhone 12). All 8 phases complete.
Resume file: None
