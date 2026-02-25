# Requirements: Flare Football — Android Verification

**Defined:** 2026-02-25
**Core Value:** Real-time soccer ball detection and tracking must run on-device with acceptable speed and accuracy on both iOS and Android

## v1.2 Requirements

Requirements for Android verification milestone. Each maps to roadmap phases.

### Diagnosis & Pipeline Fix

- [x] **DIAG-01**: Pre-flight checks pass — `aaptOptions { noCompress 'tflite' }` confirmed in `build.gradle`, plugin version confirmed `0.2.0` via `flutter pub deps`, model file confirmed present in `android/app/src/main/assets/`
- [x] **DIAG-02**: YOLO `onResult` callback delivers detection results to Flutter on Galaxy A32, confirmed via `log()` output showing detection data
- [x] **DIAG-03**: Android TFLite model returns correct class name strings (`Soccer ball`, `ball`) matching iOS Core ML model, confirmed via logged `className` values
- [x] **DIAG-04**: Root cause of `onResult` silence identified with logcat/log evidence, fix applied, and finding documented

### Feature Parity Verification

- [ ] **PRTY-01**: Orange trail dots and connecting lines appear on Android when ball is in frame, positioned accurately on the ball with no systematic X/Y offset
- [ ] **PRTY-02**: Red "Ball lost" badge appears at top-right when ball exits frame for 3+ consecutive frames, disappears on re-detection — matching iOS behavior
- [ ] **PRTY-03**: Android camera aspect ratio empirically confirmed by logging actual camera resolution on first frame; coordinate mapping in `YoloCoordUtils` verified correct
- [ ] **PRTY-04**: Android inference FPS measured and documented — expected 5-20fps on Galaxy A32 Helio G80 (this is a finding to record, not a bug to fix)

## Future Requirements

Deferred beyond v1.2. Tracked but not in current roadmap.

### Performance Optimization

- **PERF-01**: EMA smoothing or Kalman filter for trail jitter reduction
- **PERF-02**: Confidence threshold tuning for Android TFLite (lower scores expected)
- **PERF-03**: Automatic runtime camera AR detection (replace hardcoded constant)
- **PERF-04**: Android-specific `ballLostThreshold` if FPS difference makes 3-frame threshold feel too slow

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| EMA smoothing / Kalman filter | Masks raw performance data the POC needs to capture |
| Confidence threshold tuning for Android | Lower TFLite scores (0.8-0.9) are expected; class priority filter already handles this |
| Automatic runtime camera AR detection | One-time empirical measurement plus constant is sufficient for POC |
| Changing `ballLostThreshold` for Android | Document the timing difference at lower FPS; don't change the value |
| Production UI polish | POC only — not evaluating UI quality |
| New screens or navigation changes | Existing 3-screen structure is sufficient |
| SSD MobileNet / TFLite path work | Frozen since v1.1 — YOLO only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DIAG-01 | Phase 9 | Complete |
| DIAG-02 | Phase 9 | Complete |
| DIAG-03 | Phase 9 | Complete |
| DIAG-04 | Phase 9 | Complete |
| PRTY-01 | Phase 10 | Pending |
| PRTY-02 | Phase 10 | Pending |
| PRTY-03 | Phase 10 | Pending |
| PRTY-04 | Phase 10 | Pending |

**Coverage:**
- v1.2 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0

---
*Requirements defined: 2026-02-25*
*Last updated: 2026-02-25 — traceability confirmed during roadmap creation*
