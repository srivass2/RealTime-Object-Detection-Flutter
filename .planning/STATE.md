# GSD State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-23)

**Core value:** Real-time soccer ball detection and tracking must run on-device with acceptable speed and accuracy on both iOS and Android
**Current focus:** Phase 7 — Trail Accumulation and Rendering (in progress — Plan 01 complete)

## Current Position

Phase: 7 of 8 (Trail Accumulation and Rendering)
Plan: 1 of 2 complete (Plan 02 — trail painter and screen integration — next)
Status: Phase 7 Plan 01 complete; data/service layer done
Last activity: 2026-02-23 — Phase 7 Plan 01: TrackedPosition, YoloCoordUtils, BallTracker created

Progress: [████░░░░░░] 40%

## Performance Metrics

**Velocity:**
- Total plans completed: 3
- Average duration: ~2.7 min
- Total execution time: ~8 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 06-overlay-foundation | 2/2 | ~6 min | ~3 min |
| 07-trail-accumulation-and-rendering | 1/2 | ~2 min | ~2 min |

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

### Pending Todos

None — Phase 7 Plan 01 complete. Plan 02 (trail painter + screen integration) is next.

### Blockers/Concerns

- [General]: Galaxy A32 testing deferred — Android SDK not configured on current Mac
- [General]: Tracking quality described as "very poor" on iPhone 12 — may be a YOLO model limitation rather than code issue. Does not block trail implementation.

## Session Continuity

Last session: 2026-02-23
Stopped at: Phase 7 Plan 01 complete — data/service layer (TrackedPosition, YoloCoordUtils, BallTracker) ready for Plan 02
Resume file: None
