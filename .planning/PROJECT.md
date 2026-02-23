# Flare Football — On-Device Object Detection

## What This Is

A mobile feasibility POC evaluating whether YOLO11n can run real-time, on-device soccer ball detection and tracking on Flutter for both iOS and Android. The app detects soccer balls via camera, tracks their movement across frames, and draws a visual trail showing the ball's path. Built as an internal engineering study to determine whether to invest in this feature for the real Flare Football product.

## Core Value

Real-time soccer ball detection and tracking must run on-device with acceptable speed and accuracy on both iOS and Android — no cloud inference, no perceptible lag.

## Requirements

### Validated

<!-- Shipped and confirmed working from POC Phase 1 -->

- ✓ YOLO11n runs real-time on Android (TFLite) and iOS (Core ML) — v1.0
- ✓ SSD MobileNet fallback runs inference in background isolate — v1.0
- ✓ Backend switching via `DETECTOR_BACKEND` env var at build time — v1.0
- ✓ Landscape orientation for YOLO detection screen — v1.0
- ✓ Bounding box rendering on SSD MobileNet path — v1.0
- ✓ Three-screen navigation (Home → Live Camera, Home → Photo Analysis) — v1.0
- ✓ Evaluation evidence captured (screenshots + recordings, both platforms) — v1.0

### Active

<!-- Current milestone: v1.1 Ball Tracking -->

- [ ] Ball position tracking across consecutive frames (YOLO pipeline)
- [ ] Ball position tracking across consecutive frames (SSD MobileNet pipeline)
- [ ] Visual trail rendering: dots at each tracked position with connecting line
- [ ] Trail fades after ~2-3 seconds (recent movement only)
- [ ] Occlusion handling: trail pauses when ball lost, resumes on re-detection (gap in path)

### Out of Scope

- Production UI polish or design system — POC only
- User authentication, accounts, or sessions — not needed for evaluation
- Uploading or persisting detection/tracking results — POC only
- Server-side / cloud inference — on-device is the core constraint
- Video recording or playback — not evaluating this
- Predictive tracking (estimating ball position when occluded) — happy path first
- Multi-ball tracking — single ball is the target use case
- Speed/velocity metrics or analytics — just the visual trail for now

## Context

- **Flutter app** with two independent ML pipelines selected at build time: `DETECTOR_BACKEND=yolo` (primary) and `DETECTOR_BACKEND=tflite` (SSD MobileNet fallback)
- **YOLO path** uses `ultralytics_yolo: ^0.2.0` with `YOLOView` widget. `onResult` callback fires per frame with detection results. Bounding boxes may be rendered natively by `YOLOView`
- **SSD MobileNet path** uses `tflite_flutter: 0.11.0` with background Dart isolate for inference. Custom `BoxWidget` renders bounding boxes on camera overlay
- **Custom YOLO11n model** trained on 3 classes: `Soccer ball`, `ball`, `tennis-ball`. Labels embedded in model
- **Target devices:** iPhone 12 (A14 Bionic, iOS 17.1.2), Samsung Galaxy A32 (SM-A325F, Android 12)
- **Dev environment:** MacBook Pro (M5, 16GB), Flutter 3.38.9, Dart 3.10.8, Xcode 26.2
- **Known: `onResult` callback** fires with detection data on YOLO path but only logs count currently — no custom overlay rendering yet. Need to confirm whether `YOLOView` renders boxes natively or if we need a custom overlay
- **Existing technical debt:** iOS diagnostic probe in `main.dart`, placeholder API key, placeholder camera description, stale widget test

## Constraints

- **Framework**: Flutter/Dart — existing codebase, cannot change
- **ML packages**: `ultralytics_yolo ^0.2.0` and `tflite_flutter 0.11.0` (pinned) — do not upgrade without testing
- **On-device only**: No network calls for inference or tracking
- **Two pipelines**: Tracking must work on both YOLO and SSD paths independently
- **Performance**: Tracking logic must not cause visible jank — inference already runs on separate thread/isolate, tracking overhead must be minimal
- **Landscape lock**: YOLO screen is landscape-only, tracking UI must respect this

## Current Milestone: v1.1 Ball Tracking

**Goal:** Prove that frame-to-frame ball tracking with a fading visual trail is technically feasible on-device at acceptable performance on both detection pipelines.

**Target features:**
- Ball position tracking across frames
- Fading dot + line trail visualization
- Occlusion-aware pause/resume

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| YOLO11n nano over larger variants | Prioritise speed and on-device compatibility for POC | ✓ Good |
| Platform-native model formats (TFLite / Core ML) | Best performance per platform | ✓ Good |
| Model files gitignored | Large binaries managed outside VCS | ✓ Good |
| Landscape-only for YOLO screen | Matches realistic phone orientation for filming a pitch | ✓ Good |
| Background isolate for TFLite inference | Prevents UI jank during CPU-intensive work | ✓ Good |
| SSD MobileNet kept as fallback | Working baseline for comparison | ✓ Good |
| Both pipelines get tracking | Evaluate tracking feasibility on both backends | — Pending |

---
*Last updated: 2026-02-23 after milestone v1.1 initialization*
