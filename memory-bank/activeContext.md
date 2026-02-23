# Active Context

## Current Focus
Phase 6 (Overlay Foundation) of v1.1 Ball Tracking milestone. Debug dot overlay implemented for YOLO path. On-device testing on iPhone 12 revealed the red dot is consistently slightly above the ball — coordinate offset needs fixing. **SSD/TFLite path has been dropped from scope — YOLO only going forward on both iOS and Android.**

## Working State Right Now

### What Is Fully Working
- **YOLO live camera detection** — `YOLOView` renders on both Android and iOS when the correct model files are placed in their platform directories
- **Backend switching** — `DETECTOR_BACKEND` env var correctly routes to either pipeline at build time
- **Landscape orientation** — YOLO mode forces landscape in `initState`, restores portrait+landscape on `dispose`
- **Home screen** — Unsplash grid loads (with a valid API key), gallery picker works, tap-to-analyze works
- **Navigation** — all three routes work correctly
- **Build pipeline** — `build_runner` generates all required `.g.dart` files
- **Evaluation documentation** — `docs/screenshots/` and `docs/recordings/` contain captured evidence from both platforms
- **Debug dot overlay (Phase 6)** — `DebugDotPainter` created, `showOverlays: false` confirmed working (no native bounding boxes), `mounted` guard added to `onResult`, `_pickBestBallYolo` helper selects highest-confidence ball detection
- **iOS diagnostic probe removed** — cleaned up in Plan 06-01 execution
- **Widget test replaced** — stale counter test replaced with project-relevant test

### What Is Partially Done / In Progress
- **Debug dot Y-axis offset** — On iPhone 12, the red dot is consistently slightly above the ball's visual position. Likely caused by aspect ratio mismatch between camera image (normalizedBox coordinates) and the CustomPaint overlay area. Needs coordinate adjustment.

### Known Gaps
- **Unsplash API key** — `'Client-ID YOUR_API_KEY'` placeholder in `api_service_type.dart`. Does not affect detection.
- **iOS camera description** — `Info.plist` has placeholder camera usage string.
- **`mlkit` backend stub** — Declared in enum, no implementation. Should be removed along with SSD cleanup.

### Resolved Since Last Update
- ~~iOS diagnostic probe in main.dart~~ — **removed** in Plan 06-01 execution
- ~~Widget test is stale~~ — **replaced** in Plan 06-02 execution
- ~~YOLOView renders bounding boxes natively?~~ — **Yes**, confirmed. `showOverlays: false` disables them.
- ~~`Trained_labels.txt` is orphaned~~ — **deleted** previously

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

## Active Environment Variable
```bash
flutter run --dart-define=DETECTOR_BACKEND=yolo
```

## Immediate Next Steps
1. **Fix dot Y-axis offset** — Investigate whether `normalizedBox` coordinates account for aspect ratio differences between the camera image and the display area. Adjust coordinate mapping in `DebugDotPainter` or in `_pickBestBallYolo`.
2. **Update requirements/roadmap** — Remove all SSD-specific requirements (OVLY-02, RNDR-06, SSD-related tasks in Phase 7)
3. **Re-test on iPhone 12** — Confirm dot centers correctly after fix
4. **Test on Galaxy A32** — When Android device is available, verify YOLO path coordinates
5. **Complete Phase 6** — Once dot is accurate, proceed to Phase 7 (Trail Accumulation)
