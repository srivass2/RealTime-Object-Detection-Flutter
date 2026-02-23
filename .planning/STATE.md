# GSD State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-23)

**Core value:** Real-time soccer ball detection and tracking must run on-device with acceptable speed and accuracy on both iOS and Android
**Current focus:** Phase 8 — Evaluation (Phase 7 complete)

## Current Position

Phase: 7 of 8 (Trail Accumulation and Rendering)
Plan: 2 of 2 complete (Phase 7 fully complete — Phase 8 evaluation next)
Status: Phase 7 complete; trail overlay and screen integration done
Last activity: 2026-02-23 — Phase 7 Plan 02: TrailOverlay, upgraded _pickBestBallYolo, YOLO screen integration

Progress: [█████░░░░░] 50%

## Performance Metrics

**Velocity:**
- Total plans completed: 3
- Average duration: ~2.7 min
- Total execution time: ~8 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 06-overlay-foundation | 2/2 | ~6 min | ~3 min |
| 07-trail-accumulation-and-rendering | 2/2 | ~5 min | ~2.5 min |

## Accumulated Context

### Decisions

- [v1.0]: YOLO path uses YOLOView (ultralytics_yolo); SSD path uses TFLite isolate — never mix pipelines
- [v1.0]: Landscape lock on YOLO screen is a matched initState/dispose pair — do not break
- [v1.1]: **SSD/TFLite path dropped from scope — YOLO only going forward on both iOS and Android** (model is old)
- [v1.1]: `showOverlays: false` confirmed working in ultralytics_yolo ^0.2.0
- [06-01]: DebugDotPainter is public (not file-private) since it lives in a separate file from the screen
- [06-01]: RepaintBoundary wraps CustomPaint for correct repaint isolation — not the other way around
- [06-02]: normalizedBox coordinates are relative to FULL camera frame; FILL_CENTER scaling (BoxFit.cover) crops one dimension. Must account for crop offset when mapping to widget pixels.
- [06-02]: Camera aspect ratio defaults to 16:9 (standard for iPhone 12 and Galaxy A32 video capture). DebugDotPainter accepts cameraAspectRatio param for adjustment.
- [06-02]: Galaxy A32 testing deferred — Android SDK not configured on current Mac. Does not block Phase 7 (can verify later).
- [07-01]: YoloCoordUtils crop math extracted verbatim from DebugDotPainter — do not modify without re-validating on iPhone 12
- [07-01]: BallTracker._prune() must NOT reset _consecutiveMissedFrames — resetting it inside _prune() would suppress the 30-frame auto-reset (research Pitfall 3)
- [07-01]: TrackedPosition uses dart:ui Offset only (not flutter/painting.dart) — keeps the model free of Flutter widget framework for pure-Dart unit testability
- [Phase 07]: TrailOverlay shouldRepaint always returns true — BallTracker.trail List.unmodifiable() creates new wrapper each call; RepaintBoundary is the real performance guard
- [Phase 07]: tracked_position.dart import removed from screen — TrackedPosition consumed inside BallTracker/TrailOverlay only; direct screen import produces unused_import warning
- [Phase 07]: IgnorePointer wraps trail CustomPaint — prevents overlay from consuming touch events intended for YOLOView camera layer

### Pending Todos

None — Phase 7 complete. Phase 8 (evaluation on iPhone 12) is next.

### Blockers/Concerns

- [General]: Galaxy A32 testing deferred — Android SDK not configured on current Mac
- [General]: Tracking quality described as "very poor" on iPhone 12 — may be a YOLO model limitation rather than code issue. Does not block trail implementation.

## Session Continuity

Last session: 2026-02-23
Stopped at: Phase 7 Plan 02 complete — TrailOverlay and YOLO screen integration done; Phase 8 evaluation next
Resume file: None
