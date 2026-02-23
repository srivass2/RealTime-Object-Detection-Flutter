# GSD State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-23)

**Core value:** Real-time soccer ball detection and tracking must run on-device with acceptable speed and accuracy on both iOS and Android
**Current focus:** Milestone v1.1 — Ball Tracking

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-02-23 — Milestone v1.1 started

## Accumulated Context

- POC Phase 1 complete: YOLO11n detection working on both platforms, evaluation evidence captured
- `onResult` callback fires on YOLO path but only logs — no custom overlay rendering yet
- SSD MobileNet path has full bounding box rendering with `BoxWidget`
- iOS diagnostic probe in `main.dart` is technical debt to clean up
- Orientation lock/restore is a matched pair in LiveObjectDetectionScreen — do not break
