# Active Context

## Current Focus
**v1.2 Android Verification milestone is in progress. Phase 9 (Android Inference Diagnosis) is COMPLETE — PASS.** The aaptOptions fix resolved the `onResult` silence on Android. Physical Galaxy A32 device run confirmed: `className=Soccer ball, conf=0.868`. Screen recordings from both landscape orientations show trail dots, connecting lines, and "Ball lost" badge all working. **Phase 10 (Android Feature Parity Verification) is now unblocked and ready to start.** It requires precise measurement of trail coordinate accuracy, badge state transitions, camera AR confirmation, and FPS.

## What Is Fully Working
- **YOLO live camera detection (iOS)** — `YOLOView` renders correctly on iPhone 12 with ball trail, "Ball lost" badge, and all overlays
- **YOLO live camera detection (Android)** — `YOLOView` renders on Galaxy A32 with `onResult` confirmed firing. `className=Soccer ball` at 0.868 confidence. Trail dots, connecting lines, and "Ball lost" badge all visually confirmed working in both landscape-left and landscape-right orientations.
- **Backend switching** — `DETECTOR_BACKEND` env var correctly routes to either pipeline at build time
- **Landscape orientation** — YOLO mode forces landscape in `initState`, restores portrait+landscape on `dispose`
- **Home screen** — Unsplash grid loads (with a valid API key), gallery picker works, tap-to-analyze works
- **Navigation** — all three routes work correctly
- **Build pipeline** — `build_runner` generates all required `.g.dart` files
- **Debug dot overlay (Phase 6)** — `DebugDotPainter` created, `showOverlays: false` confirmed working, `mounted` guard on `onResult`
- **Ball trail (Phase 7)** — `BallTracker` service with bounded 1.5s ListQueue, occlusion sentinels, 30-frame auto-reset, min-distance dedup. `TrailOverlay` CustomPainter with fading orange dots, connecting lines, occlusion gap skipping, FILL_CENTER crop correction via `YoloCoordUtils`. Class priority filtering (`Soccer ball` > `ball` > `tennis-ball`). Nearest-neighbor tiebreaker for multi-detection frames.
- **Camera aspect ratio (4:3)** — Corrected from 16:9 to 4:3. Visually appears correct on both platforms. Not precisely measured on Android.
- **"Ball lost" badge (Phase 8)** — Device-verified on iPhone 12 and visually confirmed on Galaxy A32 in both orientations.
- **Android coordinate correction** — MethodChannel rotation polling + `(1-x, 1-y)` flip for rotation=3. Visually confirmed working on Galaxy A32.
- **aaptOptions fix** — `aaptOptions { noCompress 'tflite' }` in `build.gradle` resolved Android `onResult` silence.
- **iOS diagnostic probe removed** — `main.dart` clean for YOLO path
- **Widget test replaced** — 3 `DetectorConfig` unit tests passing
- **Code quality clean** — `flutter analyze` 0 issues; `flutter test` 3/3
- **Evaluation documentation** — `docs/` and `result/android/` contain evidence from both platforms (39 Android frames + 2 recordings)
- **Specialist agents** — `.claude/agents/` contains 6 agents
- **GSD planning infrastructure** — `.planning/` with full phase documentation including Phase 9 findings

## What Is Partially Done / In Progress
- **Phase 10: Android Feature Parity Verification** — Ready to start, unblocked by Phase 9 PASS.
  - PRTY-01: Trail coordinate precision (visual evidence positive, not pixel-precise)
  - PRTY-02: Badge state transition timing (systematic in/out test needed)
  - PRTY-03: Log actual Android camera resolution to confirm 4:3 AR
  - PRTY-04: Measure FPS (count `[DIAG-02]` lines per second)
- **`tennis-ball` accepted at priority 2** — Diagnostic concession; turned out unnecessary (`Soccer ball` detected correctly). Remains in code.
- **DIAG print statements** — Still in code; useful for Phase 10 FPS measurement.

## Known Gaps
- **Unsplash API key** — `'Client-ID YOUR_API_KEY'` placeholder. Does not affect detection.
- **iOS camera description** — `Info.plist` placeholder. Must update before external demo.
- **`mlkit` backend stub** — Declared in enum, no implementation. Falls through silently.
- **Galaxy A32 camera AR not precisely measured** — 4:3 visually correct; Phase 10 PRTY-03 will confirm.
- **`.claude/agents/` not committed** — Untracked in git.
- **`print()` statements in onResult** — DIAG-02/03/04/05 temporary diagnostics.
- **Uncommitted files** — Many modified/untracked files from Phase 9 work.
- **Android FPS not measured** — Expected 5-20fps on Helio G80; Phase 10 PRTY-04 will quantify.

## Key Decision: Camera Aspect Ratio is 4:3
**Decision date:** 2026-02-23
**Rationale:** `ultralytics_yolo` uses `.photo` session preset on iOS (4032x3024). 16:9 caused ~10% Y-offset. Visually correct on Android but not precisely measured.

## Key Decision: SSD/TFLite Path Dropped
**Decision date:** 2026-02-23
**Rationale:** SSD MobileNet is old. YOLO only going forward. SSD code remains for reference.

## Key Decision: Android Coordinate Correction via MethodChannel
**Decision date:** 2026-02-25
**Rationale:** Plugin doesn't distinguish landscape-left/right on Android. MethodChannel polls `Surface.ROTATION_*`. When rotation=3, coords flipped `(1-x, 1-y)`. **Device-verified on Galaxy A32.**

## Key Decision: aaptOptions Root Cause Fix
**Decision date:** 2026-02-25
**Rationale:** AAPT compression corrupts TFLite memory-mapping. Fix: `aaptOptions { noCompress 'tflite' }`. **Verified: restores `onResult` on Galaxy A32.**

## Model Files: Developer Machine Setup Required
The YOLO model files are gitignored and must be manually placed:

**Android setup:**
```bash
mkdir -p android/app/src/main/assets
cp /path/to/yolo11n.tflite android/app/src/main/assets/
```

**iOS setup:**
1. Copy `yolo11n.mlpackage` into the `ios/` directory
2. Open `ios/Runner.xcworkspace` in Xcode
3. Confirm `yolo11n.mlpackage` is listed under Runner -> Build Phases -> Copy Bundle Resources
   (Xcode reference already exists: `9883D8872F43899800AEC4E1`)

## Active Environment Variable
```bash
flutter run --dart-define=DETECTOR_BACKEND=yolo
```

For running against SSD (legacy/frozen):
```bash
flutter run --dart-define=DETECTOR_BACKEND=tflite
# or simply:
flutter run
```

## Recent Changes (from git log)
```
4577440  docs(09-01): complete android inference diagnosis plan 01
61380bf  feat(09-01): add DIAG-02 and DIAG-03 log calls in YOLO onResult callback
9b3ccb7  chore(09-01): add aaptOptions noCompress tflite to build.gradle
afedbce  docs(09): create phase plan
ed61396  docs(09): research phase — Android inference diagnosis and fix
5763ed6  .
28422bb  model file uploaded back to Xcode
```

## Immediate Next Steps
1. **Start Phase 10** — Plan 10-01: camera AR probe and coordinate accuracy verification on Galaxy A32. Log actual camera resolution to confirm/correct 4:3 assumption.
2. **Measure Android FPS** — Plan 10-02: count `[DIAG-02]` lines per second during a sustained device run to quantify inference rate on Helio G80.
3. **Verify badge state transitions systematically** — Move ball in/out of frame repeatedly on Galaxy A32 to confirm badge timing (PRTY-02).
4. **Clean up DIAG print statements** — After Phase 10 measurements, convert `print()` to `log()` or remove.
5. **Commit accumulated changes** — Developer handles git commits; many files modified since Phase 9 work began.
