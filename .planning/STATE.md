# GSD State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-23)

**Core value:** Real-time soccer ball detection and tracking must run on-device with acceptable speed and accuracy on both iOS and Android
**Current focus:** Phase 6 — Overlay Foundation

## Current Position

Phase: 6 of 8 (Overlay Foundation)
Plan: 2 of 2 in current phase
Status: In progress
Last activity: 2026-02-23 — Completed 06-01 debug dot overlay implementation

Progress: [█░░░░░░░░░] 10%

## Performance Metrics

**Velocity:**
- Total plans completed: 1
- Average duration: 3 min
- Total execution time: 3 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 06-overlay-foundation | 1/2 | 3 min | 3 min |

## Accumulated Context

### Decisions

- [v1.0]: YOLO path uses YOLOView (ultralytics_yolo); SSD path uses TFLite isolate — never mix pipelines
- [v1.0]: Landscape lock on YOLO screen is a matched initState/dispose pair — do not break
- [v1.1]: Phase 6 is a mandatory correctness gate — do not start trail accumulation (Phase 7) until coordinates are proven accurate on both devices
- [v1.1]: `showOverlays: false` on YOLOView must be verified in pub-cache source before writing any trail code
- [06-01]: DebugDotPainter is public (not file-private) since it lives in a separate file from the screen
- [06-01]: RepaintBoundary wraps CustomPaint for correct repaint isolation — not the other way around
- [06-01]: showOverlays: false confirmed available in ultralytics_yolo ^0.2.0 (verified from pub-cache source) — blocker resolved
- [06-01]: _debugDotPosition is shared between YOLO and SSD — only one pipeline runs at a time, no conflict
- [06-01]: SSD _debugDotPosition update placed inside existing mounted-guarded setState to avoid double rebuild

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 6]: `onResult` coordinate accuracy on Galaxy A32 must be verified empirically (GitHub issue #105 — platform-specific offset) — requires on-device test in 06-02
- [Phase 7]: `ScreenParams.screenPreviewSize` timing on SSD path — must confirm non-null before first resultsStream event

## Session Continuity

Last session: 2026-02-23
Stopped at: Completed 06-01-PLAN.md — debug dot overlay for both YOLO and SSD pipelines
Resume file: None
