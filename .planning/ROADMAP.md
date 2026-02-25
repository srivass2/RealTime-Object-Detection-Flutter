# Roadmap: Flare Football Object Detection POC

## Milestones

- ✅ **v1.0 Detection Feasibility** — Phases 1-5 (shipped 2026-02-23)
- ✅ **v1.1 Ball Tracking** — Phases 6-8 (shipped 2026-02-24)
- 🚧 **v1.2 Android Verification** — Phases 9-10 (in progress)

## Phases

<details>
<summary>✅ v1.0 Detection Feasibility (Phases 1-5) — SHIPPED 2026-02-23</summary>

Phases 1–5 predate the GSD workflow and are archived here for continuity.
Delivered: YOLO11n real-time detection on Android and iOS, SSD MobileNet fallback,
build-time backend switching, landscape orientation lock, bounding box rendering,
three-screen navigation, and evaluation evidence capture.

</details>

<details>
<summary>✅ v1.1 Ball Tracking (Phases 6-8) — SHIPPED 2026-02-24</summary>

Delivered: Debug dot overlay with FILL_CENTER coordinate mapping, BallTracker service
with time-windowed trail and occlusion handling, TrailOverlay CustomPainter with fading
dots and connecting lines, camera AR fix (4:3), "Ball lost" badge overlay.
All features device-verified on iPhone 12. See `.planning/milestones/v1.1-ROADMAP.md`.

</details>

### 🚧 v1.2 Android Verification (In Progress)

**Milestone Goal:** Diagnose and fix the Android YOLO pipeline so detection, ball tracking, trail rendering, and the "Ball lost" badge all work on Galaxy A32 — achieving feature parity with the verified iOS behavior.

## Phase Details

### Phase 9: Android Inference Diagnosis and Fix
**Goal**: The YOLO `onResult` callback delivers detection results to Flutter on the Galaxy A32 with the correct class name strings, and the root cause of its prior silence is identified, fixed, and documented.
**Depends on**: Phase 8 (v1.1 complete)
**Requirements**: DIAG-01, DIAG-02, DIAG-03, DIAG-04
**Success Criteria** (what must be TRUE):
  1. Pre-flight checks pass — `aaptOptions { noCompress 'tflite' }` confirmed in `build.gradle`, plugin version confirmed `0.2.0`, and `yolo11n.tflite` confirmed present in `android/app/src/main/assets/`
  2. `log()` output in the Flutter debug console shows detection data arriving in `onResult` on a live Galaxy A32 run with a ball in frame
  3. Logged `className` values from `onResult` include `Soccer ball` or `ball` — matching the custom model's embedded labels, not COCO 80-class fallback strings
  4. Root cause of `onResult` silence is documented with logcat or debug log evidence identifying which step in the Android callback chain failed
**Plans**: 2 plans

Plans:
- [x] 09-01-PLAN.md — Apply aaptOptions fix to build.gradle and add DIAG-02/03 diagnostic log() calls to onResult callback
- [x] 09-02-PLAN.md — Run app on Galaxy A32, human-verify onResult fires with correct classNames, write 09-FINDINGS.md

### Phase 10: Android Feature Parity Verification
**Goal**: Trail dots, connecting lines, and the "Ball lost" badge all behave on the Galaxy A32 as they do on iPhone 12 — with coordinate accuracy empirically verified — and Android inference FPS is measured and documented.
**Depends on**: Phase 9 (`onResult` must be confirmed firing before any verification is meaningful)
**Requirements**: PRTY-01, PRTY-02, PRTY-03, PRTY-04
**Success Criteria** (what must be TRUE):
  1. Orange trail dots and connecting lines appear on the Android screen when a ball is in frame, with no systematic X/Y position offset relative to the ball's actual screen position
  2. The "Ball lost" badge appears at top-right within a few frames of the ball leaving frame and disappears when the ball re-enters — matching the iOS state transition behavior
  3. Actual camera resolution logged from the first Android frame confirms the aspect ratio used in `YoloCoordUtils` is correct (or a corrected constant is applied if the measured AR differs from 4:3)
  4. Android inference FPS is logged and documented as a quantitative finding (expected 5-20fps on Helio G80; this is a measurement to record, not a performance target to hit)
**Plans**: TBD

Plans:
- [ ] 10-01: Camera AR probe and coordinate accuracy verification
- [ ] 10-02: Badge state verification and FPS measurement

## Progress

**Execution Order:** 9 → 10

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1-5. Detection Feasibility | v1.0 | — | Complete | 2026-02-23 |
| 6. Overlay Foundation | v1.1 | 2/2 | Complete | 2026-02-23 |
| 7. Trail Accumulation and Rendering | v1.1 | 3/3 | Complete | 2026-02-23 |
| 8. Polish | v1.1 | 1/1 | Complete | 2026-02-24 |
| 9. Android Inference Diagnosis and Fix | v1.2 | 2/2 | Complete | 2026-02-25 |
| 10. Android Feature Parity Verification | v1.2 | 0/2 | Ready to start | - |
