# GSD State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-25)

**Core value:** Real-time soccer ball detection and tracking must run on-device with acceptable speed and accuracy on both iOS and Android
**Current focus:** Phase 10 — Android Feature Parity Verification

## Current Position

Phase: 10 of 10 (Android Feature Parity Verification)
Plan: 0 of 2 in current phase
Status: Ready to start — Phase 9 PASSED, Phase 10 unblocked
Last activity: 2026-02-25 — Phase 9 complete (onResult confirmed firing on Galaxy A32)

Progress: [█████████░] ~80% (phases 1-9 complete, phase 10 pending)

## Performance Metrics

**v1.1 Velocity:**
- Total plans completed: 6
- Phases: 3 (06, 07, 08)
- Timeline: 2026-02-23 → 2026-02-24

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 06-overlay-foundation | 2/2 | ~6 min | ~3 min |
| 07-trail-accumulation-and-rendering | 3/3 | ~53 min | ~18 min |
| 08-polish | 1/1 | ~10 min | ~10 min |
| 09-android-inference-diagnosis-and-fix | 2/2 | ~15 min | ~7.5 min |

## Accumulated Context

### Decisions

Archived to PROJECT.md Key Decisions table. Key carry-forward items:

- Camera AR is 4:3 (ultralytics_yolo `.photo` preset on iOS) — **UNTESTED on Android**
- Positioned must be a direct Stack child — IgnorePointer goes inside
- `onResult` callback confirmed NOT firing on Android (v1.2 recording analysis)
- aaptOptions block must be inside android {} closure (not top-level) — Gradle scoping
- DIAG log calls placed before if (!mounted) guard so they fire even during unmount
- DIAG-03 logs raw detections before _pickBestBallYolo filter to confirm className values from custom model

### Pending Todos

- [DONE — 09-01] Apply aaptOptions noCompress fix + DIAG log calls
- [DONE — 09-02] Physical Galaxy A32 device run — onResult confirmed firing, className=Soccer ball at 0.868 confidence
- [DONE — 09-02] 09-FINDINGS.md written with root cause, evidence, and open question resolution
- Verify camera AR assumption on Android — precise measurement (Phase 10 PRTY-03)
- Document Android FPS as an evaluation finding (Phase 10 PRTY-04)

### Blockers/Concerns

- [RESOLVED] `onResult` not firing on Android — fixed by aaptOptions noCompress. Confirmed firing with `Soccer ball` at 0.868 confidence.
- [RESOLVED] Phase 10 dependency — Phase 9 PASSED. Phase 10 unblocked.
- [Carry-forward]: Camera AR may differ on Android (4:3 assumption visually confirmed but not precisely measured on Galaxy A32)

## Session Continuity

Last session: 2026-02-25
Stopped at: Phase 9 COMPLETE. 09-FINDINGS.md written. Phase 10 ready to start.
Resume file: None
