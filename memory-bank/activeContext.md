# Active Context

## Current Focus
The **v1.1 Ball Tracking milestone is fully complete and archived.** All three phases executed and device-verified: Phase 6 (debug dot overlay), Phase 7 (ball trail), Phase 8 (Polish — "Ball lost" badge). The live detection screen now shows a red "Ball lost" badge within 3 frames of losing the ball, disappearing on re-detection. Code quality is clean (0 lint issues, 3/3 tests). The milestone was archived with commit `26445b0`. **No next milestone has been defined yet.**

In the same session, 6 specialist Claude agents were created in `.claude/agents/` to accelerate future development.

## Working State Right Now

### What Is Fully Working
- **YOLO live camera detection** — `YOLOView` renders on both Android and iOS when the correct model files are placed in their platform directories
- **Backend switching** — `DETECTOR_BACKEND` env var correctly routes to either pipeline at build time
- **Landscape orientation** — YOLO mode forces landscape in `initState`, restores portrait+landscape on `dispose`
- **Home screen** — Unsplash grid loads (with a valid API key), gallery picker works, tap-to-analyze works
- **Navigation** — all three routes work correctly
- **Build pipeline** — `build_runner` generates all required `.g.dart` files
- **Debug dot overlay (Phase 6)** — `DebugDotPainter` created, `showOverlays: false` confirmed working (no native bounding boxes), `mounted` guard on `onResult`
- **Ball trail (Phase 7)** — `BallTracker` service with bounded 1.5s ListQueue, occlusion sentinels, 30-frame auto-reset, min-distance dedup. `TrailOverlay` CustomPainter with fading orange dots, connecting lines, occlusion gap skipping, FILL_CENTER crop correction via `YoloCoordUtils`. Class priority filtering (`Soccer ball` > `ball`, rejects `tennis-ball`). Nearest-neighbor tiebreaker for multi-detection frames.
- **Camera aspect ratio (4:3)** — Corrected from 16:9 to 4:3. `ultralytics_yolo` uses `.photo` session preset on iOS (4032×3024). Trail dots accurately centered on ball.
- **"Ball lost" badge (Phase 8)** — `BallTracker.isBallLost` getter (threshold: 3 consecutive missed frames). Red badge (`Colors.red.withValues(alpha: 0.85)`) rendered as `Positioned(top: 12, right: 12)` in the Stack, wrapped in `IgnorePointer`. Disappears on re-detection. Device-verified on iPhone 12.
- **iOS diagnostic probe removed** — `main.dart` no longer imports `tflite_flutter` or `dart:io` in the YOLO path
- **Widget test replaced** — stale counter test replaced with 3 `DetectorConfig` unit tests
- **Code quality clean** — `flutter analyze` passes with 0 issues; `flutter test` passes 3/3
- **Evaluation documentation** — `docs/screenshots/`, `docs/recordings/`, `docs/frames/` contain captured evidence from both platforms
- **Evaluation report** — `report/report.html` generated (840 lines)
- **Specialist agents** — `.claude/agents/` contains 6 agents: `orchestrator`, `yolo-detection-specialist`, `flutter-overlay-specialist`, `ml-evaluation-specialist`, `architecture-guardian`, `platform-build-specialist`

### What Is Partially Done / In Progress
- Nothing — v1.1 milestone is complete and archived. No next milestone started.

### Known Gaps
- **Unsplash API key** — `'Client-ID YOUR_API_KEY'` placeholder in `api_service_type.dart`. Does not affect detection.
- **iOS camera description** — `Info.plist` has placeholder camera usage string: `"your usage description here"`. Must update before any external demo build.
- **`mlkit` backend stub** — `DetectorBackend.mlkit` declared in enum but no implementation. Falls through silently. Should be cleaned up in a future pass.
- **Galaxy A32 testing** — Android device testing blocked; Android SDK not configured on current Mac. Trail coordinate accuracy on Android must be verified empirically.
- **`.claude/agents/` not committed** — The agents directory is untracked in git. Commit if you want to preserve them in VCS.

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
26445b0  chore: archive v1.1 Ball Tracking milestone
79950c4  docs(08-01): complete Ball lost badge plan — device verified, Phase 8 complete
b7d7ed7  fix(08-01): swap IgnorePointer/Positioned nesting order in Ball lost badge
17fb1f8  docs(08-01): complete Ball lost badge plan — checkpoint pending device verification
b6a68fb  feat(08-01): add conditional Ball lost badge to YOLO live detection screen
8d061c5  feat(08-01): add isBallLost getter and ballLostThreshold to BallTracker
9a575f2  docs(08-polish): create phase plan
```

## Immediate Next Steps
1. **Define next milestone** — v1.1 is archived; decide what v1.2 (or any future milestone) should address. Candidates: Android verification, model accuracy improvements, performance profiling, or preparing a demo build.
2. **Test on Galaxy A32** — When Android device is available, verify YOLO path trail coordinates with 4:3 AR assumption; may need empirical correction.
3. **Commit `.claude/agents/`** — The 6 specialist agents are untracked; commit them if they should persist in the repo.
4. **Update `Info.plist`** camera usage description before any external demo or TestFlight build.
5. **Replace Unsplash API key** if the home photo grid is needed for any demo.
