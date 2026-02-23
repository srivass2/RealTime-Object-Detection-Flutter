# Progress

## What Has Been Built and Works

### Core Infrastructure ✅
- Flutter project scaffolded with multi-platform support (iOS, Android, macOS, Windows, Linux, Web)
- `DETECTOR_BACKEND` environment variable system for build-time backend switching
- Three-screen navigation structure (Home → Live Camera, Home → Photo Analysis)
- Singleton service pattern for navigation, snackbar, and ML services
- MobX state management on Home Screen
- Retrofit + Dio API layer for Unsplash (needs real API key to function)
- Full `build_runner` code generation pipeline (JSON, Retrofit, MobX)
- `.gitignore` correctly excludes model binaries, build artifacts, and generated files
- `CLAUDE.md` added to repo — comprehensive session instructions, build commands, architecture rules
- `/update-memory` slash command added to `.claude/commands/`

### Code Quality ✅
- `flutter analyze` — 0 issues (clean)
- `flutter test` — 3/3 passing (`DetectorConfig` unit tests)
- `withOpacity()` replaced with `withValues(alpha:)` (deprecated API migration)
- `print()` replaced with `log()` from `dart:developer` (avoid_print lint)
- Lint suppression added to `home_screen_store.dart` for standard MobX mixin pattern
- `memory-bank/changelog.md` documents the cleanup steps and verification output

### YOLO11n Integration ✅
- `ultralytics_yolo: ^0.2.0` package integrated as dependency
- `YOLOView` widget correctly placed in `LiveObjectDetectionScreen` for YOLO mode
- Platform-aware model path: `'yolo11n'` (iOS) vs `'yolo11n.tflite'` (Android)
- `YOLOTask.detect` configured correctly for bounding box detection
- `onResult` callback wired with `mounted` guard and `_pickBestBallYolo` helper
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
- `_pickBestBallYolo` helper: filters by ball classes (`Soccer ball` > `ball`, rejects `tennis-ball`), picks highest confidence
- Camera aspect ratio correctly set to 4:3 (was incorrectly defaulting to 16:9)

### Ball Trail (Phase 7) ✅
- **`TrackedPosition`** (`lib/models/tracked_position.dart`) — immutable value type (`normalizedCenter`, `timestamp`, `isOccluded`); uses `dart:ui` only for pure-Dart unit testability
- **`YoloCoordUtils`** (`lib/utils/yolo_coord_utils.dart`) — shared FILL_CENTER crop offset math extracted from `DebugDotPainter`; camera AR = 4:3 by default
- **`BallTracker`** (`lib/services/ball_tracker.dart`) — service with bounded 1.5s `ListQueue`, occlusion sentinels (TRAK-02), 30-frame auto-reset (TRAK-05), min-distance dedup (`_minDistSq = 0.000025`)
- **`TrailOverlay`** (`lib/screens/live_object_detection/widgets/trail_overlay.dart`) — `CustomPainter` with fading orange dots (age-based opacity + radius), connecting lines (strokeWidth 2.5), occlusion gap skipping (RNDR-03), FILL_CENTER crop correction via `YoloCoordUtils` (RNDR-05)
- **Class priority filtering** — `{'Soccer ball': 0, 'ball': 1}`, rejects `tennis-ball` (TRAK-03)
- **Nearest-neighbor tiebreaker** — uses `_tracker.lastKnownPosition` for multi-detection frames (TRAK-04)
- **`IgnorePointer`** wraps trail `CustomPaint` — prevents overlay from consuming touch events
- **Camera AR = 4:3** — `ultralytics_yolo` uses `.photo` session preset on iOS (4032×3024); fixed from 16:9 in Phase 7 Plan 03
- **Device-verified** on iPhone 12 in both left and right landscape orientations (4 test recordings, 42 frames analyzed)
- **Phase 7 verification videos** — `docs/recordings/ios/` now contains 4 "iPhone trail verification - Landscape …" videos (left ×2, right ×2)
- **Phase 7 extracted frames** — `docs/frames/ios/frames_l3` (10 frames), `frames_l4` (9 frames), `frames_r1` (10 frames), `frames_r2` (13 frames); all committed to `docs/`. `result/` directory removed.

### SSD MobileNet / TFLite Path ✅ (Frozen — No New Development)
- `tflite_flutter: 0.11.0` integrated
- `ssd_mobilenet_v1.tflite` (4.0 MB) present in `assets/model/`
- `labels.txt` (91 COCO classes) present in `assets/label/`
- `TensorflowService` singleton loads model and labels
- Background Dart isolate (`Detector`) for non-blocking inference
- `BoxWidget` renders bounding boxes with label and backdrop blur on camera preview
- **Status:** Code remains for reference but no new features will be built for this path

### Photo Analysis Flow ✅
- `PhotoAnalyzeScreen` receives image bytes and runs SSD inference
- Bounding boxes drawn onto image using `TensorflowHelper.drawBoxes`
- `DetectedObjectTile` widget lists all detections with label + confidence score

### Home Screen ✅
- Unsplash photo grid with infinite scroll (10-page pagination)
- Tap any photo → download bytes → navigate to `PhotoAnalyzeScreen`
- Gallery image picker → navigate to `PhotoAnalyzeScreen`
- FAB → navigate to `LiveObjectDetectionScreen`

### Evaluation Documentation ✅
- `docs/screenshots/ios/` — iPhone detection screenshots: David free kick (4 images), kids soccerball (4 images)
- `docs/screenshots/android/` — Android detection screenshots: David scenarios (3 images), kids soccerball (3 images)
- `docs/recordings/ios/` — iPhone detection videos (4 Phase 1-5 recordings + 4 Phase 7 trail verification recordings — "iPhone trail verification - Landscape …")
- `docs/recordings/android/` — Android detection video recordings (4 videos)
- `docs/frames/ios/` — Phase 7 extracted verification frames: `frames_l3` (10), `frames_l4` (9), `frames_r1` (10), `frames_r2` (13) = 42 frames total
- `report/report.html` — evaluation report (840 lines, generated 2026-02-23)

---

## What Is Incomplete or Needs Decisions

### Phase 8: Polish 📋 (Not Started)
**Status:** Next phase
**Blocker:** Not yet planned
"Ball lost" badge overlay — communicates tracking state to evaluator. Badge appears within a few frames of the ball leaving view or becoming occluded; disappears on re-detection.
**Resolution:** Plan Phase 8 with `/gsd:plan-phase`, then execute.

### Testing on Galaxy A32 📱 (Blocked)
**Status:** Blocked — Android SDK not configured on current Mac
Android build succeeds but needs a machine with Android SDK or device connected via USB for deployment. Galaxy A32 coordinate accuracy with 4:3 AR must be verified empirically — the 4:3 fix was verified on iPhone 12 only.
**Resolution:** Connect Android device when available; run YOLO path and observe trail accuracy.

### Unsplash API Key 🔑 (Configuration Gap)
**Status:** Placeholder — does not affect detection
`lib/apibase/api_service_type.dart` has `'Client-ID YOUR_API_KEY'`. Returns HTTP 401 until replaced.

### iOS Camera Usage Description 📝 (Minor)
**Status:** Placeholder in Info.plist (`"your usage description here"`)
Must update before any external TestFlight or demo build.

### `mlkit` Backend Stub ⚙️ (Unimplemented)
**Status:** Stub only — declared in enum, no implementation
Falls through silently if `DETECTOR_BACKEND=mlkit` is passed. Should be removed in any future cleanup pass.

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
| **Camera aspect ratio = 4:3 (not 16:9)** | **ultralytics_yolo uses `.photo` session preset on iOS (4032×3024). 16:9 caused ~10% Y-offset.** |
| **Min-distance dedup in BallTracker** | **Prevents dot clustering at ~30fps. Threshold: `_minDistSq = 0.000025` (0.5% of frame).** |
| `IgnorePointer` wraps trail overlay | Prevents CustomPaint from consuming touch events intended for YOLOView |
| `shouldRepaint` always true in TrailOverlay | `List.unmodifiable()` creates new wrapper each call; RepaintBoundary is the real performance guard |
| `TrackedPosition` uses `dart:ui` Offset only | Keeps model free of Flutter widget framework for pure-Dart unit testability |

---

## POC Evaluation Checklist

| Item | Status |
|---|---|
| YOLO11n runs on Android (TFLite format) | ✅ Implemented + evaluation recordings captured |
| YOLO11n runs on iOS (Core ML) | ✅ Implemented + evaluation recordings captured |
| Real-time detection is smooth enough | ⏳ Tracking quality described as "very poor" on iPhone 12 — may be model limitation |
| Soccer ball detection accuracy acceptable | ⏳ Needs further evaluation |
| `showOverlays: false` disables native boxes | ✅ Confirmed working on iPhone 12 |
| Debug dot overlay renders on YOLO path | ✅ Working (Y-axis offset fixed — camera AR = 4:3) |
| Ball trail renders correctly | ✅ Verified on iPhone 12 — fading dots, connecting lines, occlusion gaps, auto-clear |
| Trail coordinates accurate (no offset) | ✅ Confirmed with 4:3 camera AR fix (Phase 7 Plan 03) |
| `flutter analyze` passes (0 issues) | ✅ Confirmed |
| `flutter test` passes (3/3) | ✅ Confirmed |
| Architecture suitable to carry forward | ✅ Yes — clean separation, standard patterns |
