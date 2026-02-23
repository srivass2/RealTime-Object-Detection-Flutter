# GSD State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-23)

**Core value:** Real-time soccer ball detection and tracking must run on-device with acceptable speed and accuracy on both iOS and Android
**Current focus:** Phase 7 — Trail Accumulation and Rendering (next up)

## Current Position

Phase: 7 of 8 (Trail Accumulation and Rendering)
Plan: Not yet planned
Status: Phase 6 complete, Phase 7 needs planning
Last activity: 2026-02-23 — Phase 6 verified: dot centered on ball on iPhone 12

Progress: [███░░░░░░░] 33%

## Performance Metrics

**Velocity:**
- Total plans completed: 2
- Average duration: ~3 min
- Total execution time: ~6 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 06-overlay-foundation | 2/2 | ~6 min | ~3 min |

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

### Pending Todos

None — Phase 6 complete.

### Blockers/Concerns

- [General]: Galaxy A32 testing deferred — Android SDK not configured on current Mac
- [General]: Tracking quality described as "very poor" on iPhone 12 — may be a YOLO model limitation rather than code issue. Does not block trail implementation.

## Session Continuity

Last session: 2026-02-23
Stopped at: Phase 6 complete — ready for Phase 7 planning
Resume file: None
