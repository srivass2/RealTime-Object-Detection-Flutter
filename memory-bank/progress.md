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

### YOLO11n Integration ✅
- `ultralytics_yolo: ^0.2.0` package integrated as dependency
- `YOLOView` widget correctly placed in `LiveObjectDetectionScreen` for YOLO mode
- Platform-aware model path: `'yolo11n'` (iOS) vs `'yolo11n.tflite'` (Android)
- `YOLOTask.detect` configured correctly for bounding box detection
- `onResult` callback wired with `mounted` guard and `_pickBestBallYolo` helper
- `showOverlays: false` confirmed working — suppresses native bounding boxes
- Xcode project file updated with `yolo11n.mlpackage` resource reference
- Landscape-only orientation enforced for YOLO mode in `initState`
- Orientation properly restored on screen `dispose`
- Backend label indicator overlay shown in YOLO mode ("YOLO" text badge top-left)

### Debug Dot Overlay (Phase 6 — v1.1) ⚠️ In Progress
- `DebugDotPainter` (`CustomPainter`) created in `lib/screens/live_object_detection/widgets/debug_dot_overlay.dart`
- Red filled circle (radius 8, ~0.9 alpha) with white stroke outline
- Renders at normalized [0.0, 1.0] position mapped to canvas pixel coords
- Wrapped in `RepaintBoundary` for rendering isolation
- `_pickBestBallYolo` helper: filters by ball classes, picks highest confidence
- Diagnostic coordinate text overlay for on-device testing
- **Issue:** Dot consistently slightly above ball on iPhone 12 — coordinate Y-axis offset

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
- `docs/screenshots/` and `docs/recordings/` — both platforms, multiple scenarios

---

## What Is Incomplete or Needs Decisions

### Debug Dot Coordinate Offset ⚠️ (Active — Phase 6)
**Status:** Needs fix
On iPhone 12 with YOLO mode, the red dot is consistently slightly above the ball. The `normalizedBox.center` coordinates likely don't map 1:1 to the `CustomPaint` overlay area due to camera aspect ratio vs display area differences.

### Testing on Galaxy A32 📱 (Blocked)
**Status:** Blocked — Android SDK not configured on current Mac
Android build succeeds but needs a machine with Android SDK or device connected via USB for deployment. Galaxy A32 coordinate accuracy (GitHub issue #105) must be verified empirically.

### Unsplash API Key 🔑 (Configuration Gap)
**Status:** Placeholder — does not affect detection

### iOS Camera Usage Description 📝 (Minor)
**Status:** Placeholder in Info.plist

---

## Decisions Made

| Decision | Rationale |
|---|---|
| YOLO11n (nano) chosen over larger variants | Prioritise speed and on-device compatibility over maximum accuracy for the POC |
| Platform-native model formats (TFLite / Core ML) | Best performance per platform |
| Model files gitignored | Large binaries managed outside VCS |
| Labels embedded in model, no external label file | YOLO11n training embedded class names directly |
| Landscape-only for YOLO screen | Matches realistic phone orientation for filming a pitch |
| **SSD/TFLite path dropped from v1.1 scope** | **Model is old; YOLO only going forward on both iOS and Android** |
| `showOverlays: false` on YOLOView | Confirmed working; disables native bounding boxes so custom overlay is the only layer |
| `mounted` guard on all detection callbacks | Prevents setState-after-dispose race condition |
| Evaluation evidence committed to `docs/` | Screenshots and recordings captured from target devices |

---

## POC Evaluation Checklist

| Item | Status |
|---|---|
| YOLO11n runs on Android (TFLite format) | ✅ Implemented + evaluation recordings captured |
| YOLO11n runs on iOS (Core ML) | ✅ Implemented + evaluation recordings captured |
| Real-time detection is smooth enough | ⏳ Tracking quality described as "very poor" on iPhone 12 — may be model limitation |
| Soccer ball detection accuracy acceptable | ⏳ Needs further evaluation |
| `showOverlays: false` disables native boxes | ✅ Confirmed working on iPhone 12 |
| Debug dot overlay renders on YOLO path | ✅ Working (with Y-axis offset issue) |
| Architecture suitable to carry forward | ✅ Yes — clean separation, standard patterns |
