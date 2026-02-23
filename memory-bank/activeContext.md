# Active Context

## Current Focus
Phase 7 (Trail Accumulation and Rendering) of v1.1 Ball Tracking milestone is **COMPLETE AND DEVICE-VERIFIED**. All 3 plans executed, verified on iPhone 12 in both landscape orientations (4 recordings, 42 frames analyzed). Code quality cleanup has been run — `flutter analyze` reports 0 issues, `flutter test` passes (3/3). Phase 8 (Polish — "Ball lost" badge) is next. **SSD/TFLite path has been dropped from v1.1 scope — YOLO only going forward on both iOS and Android.**

## Working State Right Now

### What Is Fully Working
- **YOLO live camera detection** — `YOLOView` renders on both Android and iOS when the correct model files are placed in their platform directories
- **Backend switching** — `DETECTOR_BACKEND` env var correctly routes to either pipeline at build time
- **Landscape orientation** — YOLO mode forces landscape in `initState`, restores portrait+landscape on `dispose`
- **Home screen** — Unsplash grid loads (with a valid API key), gallery picker works, tap-to-analyze works
- **Navigation** — all three routes work correctly
- **Build pipeline** — `build_runner` generates all required `.g.dart` files
- **Debug dot overlay (Phase 6)** — `DebugDotPainter` created, `showOverlays: false` confirmed working (no native bounding boxes), `mounted` guard added to `onResult`
- **Ball trail (Phase 7)** — `BallTracker` service with bounded 1.5s ListQueue, occlusion sentinels, 30-frame auto-reset, min-distance dedup. `TrailOverlay` CustomPainter with fading orange dots, connecting lines, occlusion gap skipping, FILL_CENTER crop correction via `YoloCoordUtils`. Class priority filtering (`Soccer ball` > `ball`, rejects `tennis-ball`). Nearest-neighbor tiebreaker for multi-detection frames.
- **Camera aspect ratio (4:3)** — Corrected from 16:9 to 4:3. `ultralytics_yolo` uses `.photo` session preset on iOS (4032×3024). Trail dots now accurately centered on ball.
- **iOS diagnostic probe removed** — cleaned up; `main.dart` no longer imports `tflite_flutter` or `dart:io` in the YOLO path
- **Widget test replaced** — stale counter test replaced with 3 `DetectorConfig` unit tests that verify default backend, label, and enum values
- **Code quality clean** — `flutter analyze` passes with 0 issues; `flutter test` passes 3/3. `withOpacity()` replaced with `withValues(alpha:)`, `print()` replaced with `log()`, lint suppression added to home_screen_store.dart
- **Evaluation documentation** — `docs/screenshots/` and `docs/recordings/` contain captured evidence from both platforms
- **Phase 7 verification artifacts** — `docs/recordings/ios/` contains 4 "iPhone trail verification - Landscape …" videos; `docs/frames/ios/` contains 4 frame-extraction folders (`frames_l3`, `frames_l4`, `frames_r1`, `frames_r2`, totalling 42 frames) used during Phase 7 device verification. `result/` directory has been removed.
- **Evaluation report** — `report/report.html` generated (840 lines)

### What Is Partially Done / In Progress
- Nothing — Phase 7 is fully complete and code quality is clean. Phase 8 not yet started.

### Known Gaps
- **Unsplash API key** — `'Client-ID YOUR_API_KEY'` placeholder in `api_service_type.dart`. Does not affect detection.
- **iOS camera description** — `Info.plist` has placeholder camera usage string: `"your usage description here"`. Must update before any external demo build.
- **`mlkit` backend stub** — `DetectorBackend.mlkit` declared in enum but no implementation. Falls through silently. Should be cleaned up along with any eventual SSD code removal.
- **Galaxy A32 testing** — Android device testing blocked; Android SDK not configured on current Mac. Trail coordinate accuracy on Android must be verified empirically.

## Key Decision: Camera Aspect Ratio is 4:3
**Decision date:** 2026-02-23
**Rationale:** `ultralytics_yolo` plugin uses `.photo` session preset on iOS → camera captures at 4032×3024 (4:3 aspect ratio). The previous assumption of 16:9 caused a ~10% Y-axis upward offset in the FILL_CENTER crop calculation. Confirmed by reading plugin source (`YOLOView.swift` line 382). Default changed in both `TrailOverlay` and `DebugDotPainter`.

## Key Decision: SSD/TFLite Path Dropped
**Decision date:** 2026-02-23
**Rationale:** The SSD MobileNet model is old and not worth further investment. All tracking work (Phases 6-8) proceeds with YOLO only, on both iOS and Android. The SSD code remains in the codebase for reference but no new features will be built for it.

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
3. Confirm `yolo11n.mlpackage` is listed under Runner → Build Phases → Copy Bundle Resources
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
b9f3530  config file added
9d79da6  report file generated
562c018  labels updated
e68756d  fix(07): correct camera aspect ratio from 16:9 to 4:3 and add trail dedup
3abdc4d  docs(07-02): complete trail painter and screen integration plan
b1266cc  feat(07-02): wire BallTracker and TrailOverlay into YOLO screen
de68901  feat(07-02): create TrailOverlay CustomPainter with fading dots and connecting lines
```
The most recent changes are a GSD config file, the evaluation report, labels update, and the Phase 7 camera AR + dedup bug fix. Core trail features were wired in the `feat(07-02)` commits.

## Immediate Next Steps
1. **Phase 8 (Polish)** — Plan and implement "Ball lost" badge overlay: appears when `BallTracker._consecutiveMissedFrames > 0` (or after a configurable threshold), disappears on re-detection
2. **Test on Galaxy A32** — When Android device is available, verify YOLO path trail coordinates with 4:3 AR assumption; may need empirical correction
3. **Update `Info.plist`** camera usage description before any external demo or TestFlight build
