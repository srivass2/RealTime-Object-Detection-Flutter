# GSD State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-23)

**Core value:** Real-time soccer ball detection and tracking must run on-device with acceptable speed and accuracy on both iOS and Android
**Current focus:** Phase 6 — Overlay Foundation (fixing coordinate offset)

## Current Position

Phase: 6 of 8 (Overlay Foundation)
Plan: 2 of 2 in current phase
Status: In progress — dot Y-axis offset needs fix before checkpoint passes
Last activity: 2026-02-23 — Device testing revealed dot offset; SSD path dropped from scope

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
- [v1.1]: **SSD/TFLite path dropped from scope — YOLO only going forward on both iOS and Android** (model is old)
- [06-01]: DebugDotPainter is public (not file-private) since it lives in a separate file from the screen
- [06-01]: RepaintBoundary wraps CustomPaint for correct repaint isolation — not the other way around
- [06-01]: showOverlays: false confirmed available in ultralytics_yolo ^0.2.0 (verified from pub-cache source) — blocker resolved
- [06-01]: _debugDotPosition is shared between YOLO and SSD — only one pipeline runs at a time, no conflict
- [06-02]: iPhone 12 YOLO test: dot consistently slightly above ball (Y-axis offset). No native bounding boxes. Tracking quality described as "very poor" (may be model limitation).

### Pending Todos

- Fix debug dot Y-axis coordinate offset on YOLO path
- Remove SSD-specific code from Phase 6 implementation (optional cleanup)

### Blockers/Concerns

- [Phase 6]: Debug dot Y-axis offset on iPhone 12 — dot appears above ball, needs coordinate mapping fix
- [Phase 6]: Galaxy A32 testing blocked — Android SDK not configured on current Mac
- [General]: Tracking quality described as "very poor" — may be a YOLO model limitation rather than code issue

## Session Continuity

Last session: 2026-02-23
Stopped at: Phase 6 checkpoint — dot offset fix needed before approval
Resume file: .planning/phases/06-overlay-foundation/06-02-PLAN.md
