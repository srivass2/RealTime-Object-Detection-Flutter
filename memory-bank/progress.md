# Progress

## What Has Been Built and Works

### Core Infrastructure ✅
- Flutter project scaffolded with multi-platform support (iOS, Android, macOS, Windows, Linux, Web)
- `DETECTOR_BACKEND` environment variable system for build-time backend switching
- Three-screen navigation structure (Home -> Live Camera, Home -> Photo Analysis)
- Singleton service pattern for navigation, snackbar, and ML services
- MobX state management on Home Screen
- Retrofit + Dio API layer for Unsplash (needs real API key to function)
- Full `build_runner` code generation pipeline (JSON, Retrofit, MobX)
- `.gitignore` correctly excludes model binaries, build artifacts, and generated files
- `CLAUDE.md` added to repo — comprehensive session instructions, build commands, architecture rules
- `/update-memory` slash command added to `.claude/commands/`
- 6 specialist Claude agents in `.claude/agents/` (untracked in git)
- GSD planning infrastructure: `.planning/` with `ROADMAP.md`, `REQUIREMENTS.md`, `MILESTONES.md`, `STATE.md`, `PROJECT.md`

### Code Quality ✅
- `flutter analyze` — 0 issues (clean)
- `flutter test` — 3/3 passing (`DetectorConfig` unit tests)
- `withOpacity()` replaced with `withValues(alpha:)` (deprecated API migration)
- `print()` replaced with `log()` from `dart:developer` (avoid_print lint) — **except for DIAG-02/03/04/05 temporary diagnostics**
- Lint suppression added to `home_screen_store.dart` for standard MobX mixin pattern

### YOLO11n Integration ✅
- `ultralytics_yolo: ^0.2.0` package integrated as dependency
- `YOLOView` widget correctly placed in `LiveObjectDetectionScreen` for YOLO mode
- Platform-aware model path: `'yolo11n'` (iOS) vs `'yolo11n.tflite'` (Android)
- `YOLOTask.detect` configured correctly for bounding box detection
- `onResult` callback wired with `mounted` guard and `_pickBestBallYolo` helper
- **`onResult` confirmed firing on BOTH platforms** — iOS (iPhone 12) and Android (Galaxy A32)
- `showOverlays: false` confirmed working — suppresses native bounding boxes
- Xcode project file updated with `yolo11n.mlpackage` resource reference
- Landscape-only orientation enforced for YOLO mode in `initState`
- Orientation properly restored on screen `dispose` (with `_tracker.reset()` call added)
- Backend label indicator overlay shown in YOLO mode ("YOLO" text badge top-left)

### Debug Dot Overlay (Phase 6) ✅
- `DebugDotPainter` (`CustomPainter`) in `lib/screens/live_object_detection/widgets/debug_dot_overlay.dart`
- Red filled circle (radius 8, ~0.9 alpha) with white stroke outline
- Renders at normalized [0.0, 1.0] position mapped to canvas pixel coords with FILL_CENTER crop correction
- Wrapped in `RepaintBoundary` for rendering isolation
- `_pickBestBallYolo` helper: filters by ball classes (`Soccer ball` > `ball` > `tennis-ball`), picks highest confidence
- Camera aspect ratio correctly set to 4:3 (was incorrectly defaulting to 16:9)

### Ball Trail (Phase 7) ✅
- **`TrackedPosition`** (`lib/models/tracked_position.dart`) — immutable value type
- **`YoloCoordUtils`** (`lib/utils/yolo_coord_utils.dart`) — shared FILL_CENTER crop offset math; camera AR = 4:3
- **`BallTracker`** (`lib/services/ball_tracker.dart`) — bounded 1.5s `ListQueue`, occlusion sentinels, 30-frame auto-reset, min-distance dedup
- **`TrailOverlay`** (`lib/screens/live_object_detection/widgets/trail_overlay.dart`) — fading orange dots, connecting lines, occlusion gap skipping
- **Class priority filtering** — `{'Soccer ball': 0, 'ball': 1, 'tennis-ball': 2}`, accepts all three ball classes
- **Nearest-neighbor tiebreaker** — uses `_tracker.lastKnownPosition` for multi-detection frames
- **Device-verified** on iPhone 12 (4 test recordings, 42 frames). **Visually confirmed** on Galaxy A32 (2 recordings, 39 frames).

### "Ball lost" Badge (Phase 8) ✅
- **`BallTracker.isBallLost`** — threshold: 3 consecutive missed frames (approx 100 ms at 30 fps)
- **Badge widget** — `Positioned(top: 12, right: 12)`, red background, white bold "Ball lost" text
- **Device-verified** on iPhone 12 and **visually confirmed** on Galaxy A32 — appears when ball exits frame, clears on re-detection

### v1.1 Milestone Archived ✅
- All 3 phases complete: Phase 6, Phase 7, Phase 8
- Milestone archived with commit `26445b0`

### Android Inference Diagnosis (Phase 9) ✅ — COMPLETE
- **Root cause identified:** Missing `aaptOptions { noCompress 'tflite' }` caused AAPT compression of model, preventing TFLite memory-mapped loading, leaving interpreter null, silencing `onResult`
- **Fix applied:** `aaptOptions { noCompress 'tflite' }` in `android/app/build.gradle` (commit `9b3ccb7`)
- **DIAG-02 confirmed:** `[DIAG-02] onResult fired — 1 detections` in Flutter debug console on Galaxy A32
- **DIAG-03 confirmed:** `className=Soccer ball, conf=0.868, box=(0.422, 0.672, 0.471, 0.740)` — custom model labels, NOT COCO fallback
- **Android coordinate correction:** `MainActivity.kt` MethodChannel + `_pollDisplayRotation()` + `(1-x, 1-y)` flip for rotation=3. Visually confirmed working.
- **Screen recordings captured:** `result/android/Android Landscape left.MOV` (18 frames), `result/android/Android Landscape right.MOV` (21 frames)
- **Phase 9 findings documented:** `09-FINDINGS.md` with root cause, evidence, open question resolution
- **`gradle.properties` updated:** `org.gradle.jvmargs=-Xmx4G`, JDK 17 path

### SSD MobileNet / TFLite Path ✅ (Frozen — No New Development)
- `tflite_flutter: 0.11.0` integrated
- `ssd_mobilenet_v1.tflite` (4.0 MB) present in `assets/model/`
- `TensorflowService` singleton loads model and labels
- Background Dart isolate (`Detector`) for non-blocking inference
- **Status:** Code remains for reference only

### Photo Analysis Flow ✅
- `PhotoAnalyzeScreen` receives image bytes and runs SSD inference
- Bounding boxes drawn onto image using `TensorflowHelper.drawBoxes`
- `DetectedObjectTile` widget lists all detections with label + confidence score

### Home Screen ✅
- Unsplash photo grid with infinite scroll (10-page pagination)
- Tap any photo -> download bytes -> navigate to `PhotoAnalyzeScreen`
- Gallery image picker -> navigate to `PhotoAnalyzeScreen`
- FAB -> navigate to `LiveObjectDetectionScreen`

### Evaluation Documentation ✅
- `docs/screenshots/ios/` — iPhone detection screenshots (8 images)
- `docs/screenshots/android/` — Android detection screenshots (6 images)
- `docs/recordings/ios/` — iPhone detection videos (8 recordings)
- `docs/recordings/android/` — Android detection video recordings (4 videos)
- `docs/frames/ios/` — Phase 7 extracted verification frames (42 frames total)
- `result/android/` — Phase 9 screen recordings (2 MOV files) + extracted frames (39 frames total)
- `report/report.html` — evaluation report (840 lines)

---

## What Is Incomplete or Needs Decisions

### Phase 10: Android Feature Parity Verification ⏳ (Ready to Start)
**Status:** Unblocked — Phase 9 PASSED
**Requirements:** PRTY-01 (trail accuracy), PRTY-02 (badge behavior), PRTY-03 (camera AR verification), PRTY-04 (FPS measurement)
**Preview:** Phase 9 visual evidence shows trail dots, lines, and badge all functioning. Phase 10 adds precision.
**Resolution:** Plan and execute Phase 10 plans.

### Android Camera Aspect Ratio ⚠️
**Status:** 4:3 assumption visually confirmed on Galaxy A32 (trail dots position near ball), but not precisely measured
**Resolution:** Phase 10 PRTY-03 will log actual camera resolution.

### Android FPS Not Measured ⏳
**Status:** Expected 5-20fps on Helio G80; not quantified yet
**Resolution:** Phase 10 PRTY-04 will count DIAG-02 lines per second.

### `.claude/agents/` Not Committed 🗑️ (Minor)
**Status:** 6 specialist agents created but untracked in git
**Resolution:** `git add .claude/agents/ && git commit` if agents should persist in VCS.

### Unsplash API Key 🔑 (Configuration Gap)
**Status:** Placeholder `'Client-ID YOUR_API_KEY'` — does not affect detection
**Resolution:** Replace with real key if home photo grid needed for demo.

### iOS Camera Usage Description 📝 (Minor)
**Status:** Placeholder in Info.plist (`"your usage description here"`)
**Resolution:** Update before any external TestFlight or demo build.

### `mlkit` Backend Stub ⚙️ (Unimplemented)
**Status:** Stub only — declared in enum, no implementation
**Resolution:** Remove in future cleanup pass.

### DIAG Print Statements 🧪 (Temporary)
**Status:** Active — useful for Phase 10 FPS measurement. Uses `print()` not `log()`.
**Resolution:** Remove or convert to `log()` after Phase 10 documented.

---

## Decisions Made

| Decision | Rationale |
|---|---|
| YOLO11n (nano) chosen over larger variants | Prioritise speed and on-device compatibility over maximum accuracy for the POC |
| Platform-native model formats (TFLite / Core ML) | Best performance per platform |
| Model files gitignored | Large binaries managed outside VCS |
| Labels embedded in model, no external label file | YOLO11n training embedded class names directly |
| Landscape-only for YOLO screen | Matches realistic phone orientation for filming a pitch |
| Background isolate for TFLite inference | Flutter best practice; prevents UI jank |
| SSD MobileNet kept as frozen fallback | Code reference only; no new features for this path |
| Unsplash API for demo image grid | Realistic varied images for static photo analysis testing |
| `Trained_labels.txt` deleted | Orphaned file from earlier dataset iteration |
| Evaluation evidence committed to `docs/` | Screenshots and recordings from target devices |
| **SSD/TFLite path dropped from v1.1 scope** | **Model is old; YOLO only going forward on both iOS and Android** |
| `showOverlays: false` on YOLOView | Confirmed working; disables native bounding boxes |
| `mounted` guard on all detection callbacks | Prevents setState-after-dispose race condition |
| **Camera aspect ratio = 4:3 (not 16:9)** | **ultralytics_yolo uses `.photo` session preset on iOS (4032x3024). 16:9 caused ~10% Y-offset.** |
| **Min-distance dedup in BallTracker** | **Prevents dot clustering at ~30fps. Threshold: `_minDistSq = 0.000025` (0.5% of frame).** |
| `IgnorePointer` wraps trail overlay | Prevents CustomPaint from consuming touch events intended for YOLOView |
| `shouldRepaint` always true in TrailOverlay | `List.unmodifiable()` creates new wrapper each call; RepaintBoundary is the real performance guard |
| `TrackedPosition` uses `dart:ui` Offset only | Keeps model free of Flutter widget framework for pure-Dart unit testability |
| **`ballLostThreshold = 3` frames** | **approx 100 ms at 30 fps — satisfies PLSH-01 without false positives from momentary occlusion** |
| **`Positioned` is direct Stack child; `IgnorePointer` inside** | **Flutter constraint: `Positioned` must be a direct child of `Stack`. Fixed in commit `b7d7ed7`.** |
| **`tennis-ball` accepted at priority 2** | **Android TFLite may misclassify due to image orientation; diagnostic concession for Phase 9 (turned out unnecessary)** |
| **Android coordinate correction via MethodChannel** | **Plugin does not distinguish landscape-left from landscape-right on Android; poll `Surface.ROTATION_*` to flip coords. Device-verified on Galaxy A32.** |
| **`aaptOptions { noCompress 'tflite' }` required** | **Gradle compression corrupts TFLite model loading; fix verified — restores `onResult` on Galaxy A32** |
| **DIAG logs placed before `mounted` guard** | **Ensures diagnostic output fires even during widget unmount** |

---

## POC Evaluation Checklist

| Item | Status |
|---|---|
| YOLO11n runs on Android (TFLite format) | ✅ Confirmed — `onResult` fires, `className=Soccer ball`, conf=0.868 on Galaxy A32 |
| YOLO11n runs on iOS (Core ML) | ✅ Implemented + evaluation recordings captured |
| Real-time detection is smooth enough | ⏳ iOS tracking quality described as "very poor" — may be model limitation. Android FPS not measured (Phase 10). |
| Soccer ball detection accuracy acceptable | ✅ `Soccer ball` class detected at 0.868 confidence on Android; comparable to iOS |
| `showOverlays: false` disables native boxes | ✅ Confirmed working on iPhone 12 |
| Debug dot overlay renders on YOLO path | ✅ Working on both platforms |
| Ball trail renders correctly | ✅ Verified on iPhone 12, visually confirmed on Galaxy A32 — fading dots, connecting lines, occlusion gaps |
| Trail coordinates accurate (no offset) | ✅ iOS confirmed. ⏳ Android visually correct, precise measurement pending (Phase 10 PRTY-03). |
| "Ball lost" badge communicates tracking state | ✅ Verified on iPhone 12, visually confirmed on Galaxy A32 — appears/disappears correctly |
| `flutter analyze` passes (0 issues) | ✅ Confirmed (excluding temporary DIAG prints) |
| `flutter test` passes (3/3) | ✅ Confirmed |
| Architecture suitable to carry forward | ✅ Yes — clean separation, standard patterns |
| Android feature parity with iOS | ⏳ Visual parity confirmed; precise measurements pending (Phase 10) |
