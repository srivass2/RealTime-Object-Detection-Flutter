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

### YOLO11n Integration ✅
- `ultralytics_yolo: ^0.2.0` package integrated as dependency
- `YOLOView` widget correctly placed in `LiveObjectDetectionScreen` for YOLO mode
- Platform-aware model path: `'yolo11n'` (iOS) vs `'yolo11n.tflite'` (Android)
- `YOLOTask.detect` configured correctly for bounding box detection
- `onResult` callback wired up (currently logging only)
- Xcode project file updated with `yolo11n.mlpackage` resource reference
- Landscape-only orientation enforced for YOLO mode in `initState`
- Orientation properly restored on screen `dispose`
- Backend label indicator overlay shown in YOLO mode ("YOLO" text badge top-left)

### SSD MobileNet / TFLite Path ✅
- `tflite_flutter: 0.11.0` integrated
- `ssd_mobilenet_v1.tflite` (4.0 MB) present in `assets/model/`
- `labels.txt` (91 COCO classes) present in `assets/label/`
- `TensorflowService` singleton loads model and labels
- Metal Delegate (iOS) / XNNPack Delegate (Android/other) hardware acceleration
- Background Dart isolate (`Detector`) for non-blocking inference
- YUV420, BGRA8888, JPEG, NV21 camera format conversion in `ImageUtils`
- `TensorflowHelper` handles 300×300 resize, tensor I/O, output parsing, confidence filtering (>0.5)
- `BoxWidget` renders bounding boxes with label and backdrop blur on camera preview
- `DetectedObjectDm` model with `renderLocation` getter for screen-scaled bbox coordinates

### Photo Analysis Flow ✅
- `PhotoAnalyzeScreen` receives image bytes and runs SSD inference
- Bounding boxes drawn onto image using `TensorflowHelper.drawBoxes`
- `DetectedObjectTile` widget lists all detections with label + confidence score
- Snackbar "Finding Objects..." shown during processing
- Animated transitions (600ms)

### Home Screen ✅
- Unsplash photo grid with infinite scroll (10-page pagination)
- Tap any photo → download bytes → navigate to `PhotoAnalyzeScreen`
- Gallery image picker → navigate to `PhotoAnalyzeScreen`
- FAB → navigate to `LiveObjectDetectionScreen`

---

## What Is Incomplete or Needs Decisions

### YOLO `onResult` Rendering ⚠️ (Needs Clarification)
**Status:** Unknown
The `onResult` callback fires and logs the detection count, but no custom bounding box UI is rendered from the results in YOLO mode. The open question is whether `YOLOView` draws its own bounding boxes internally:
- If **yes** → the live camera POC is visually complete for YOLO
- If **no** → a custom overlay needs to be built using the `results` list from `onResult`

### iOS Diagnostic Probe in main.dart ⚠️ (Technical Debt)
**Status:** Should be removed
A temporary `try/catch` block in `main.dart` attempts to load `yolo11n.tflite` from `assets/model/` via Flutter's asset bundle on iOS. This will always fail (the file is not there and not declared in pubspec.yaml) and produces a noisy error log. It was added to probe whether the TFLite interpreter could load a YOLO model on iOS via Flutter assets. This diagnostic code should be removed once iOS evaluation via the mlpackage path is confirmed working.

### Unsplash API Key 🔑 (Configuration Gap)
**Status:** Placeholder
`lib/apibase/api_service.dart` contains `'Client-ID YOUR_API_KEY'`. The Unsplash photo grid will return HTTP 401 until this is replaced with a real Unsplash developer API key. Does not affect detection functionality.

### iOS Camera Usage Description 📝 (Minor)
**Status:** Placeholder
`ios/Runner/Info.plist` has `"your usage description here"` for `NSCameraUsageDescription`. Must be updated before any external TestFlight or demo build to avoid App Store Review rejection.

### `Trained_labels.txt` 🗑️ (Orphaned)
**Status:** Dead file
`assets/label/Trained_labels.txt` contains two lines: `ball` and `goal`. These reflect an earlier dataset. The file is not referenced anywhere in the codebase and has no effect. Can be deleted.

### `mlkit` Backend Stub ⚙️ (Unimplemented)
**Status:** Stub only
`DetectorBackend.mlkit` is declared in the enum and handled in `DetectorConfig` but produces no distinct behaviour in `LiveObjectDetectionScreen`. It silently falls through to no initialisation. Either implement it or remove it from the enum to avoid confusion.

### Widget Tests 🧪 (Stale)
**Status:** Wrong test
`test/widget_test.dart` contains a boilerplate counter app test. It does not test anything in this project. Will likely fail or pass vacuously.

---

## Decisions Made

| Decision | Rationale |
|---|---|
| YOLO11n (nano) chosen over larger variants | Prioritise speed and on-device compatibility over maximum accuracy for the POC |
| Platform-native model formats (TFLite / Core ML) | Best performance per platform; avoids cross-platform format compromise |
| Model files gitignored | Binary model files are large and change independently of code; managed outside version control |
| Labels embedded in model, no external file | YOLO11n training embedded class names directly; no label file maintenance needed |
| Landscape-only for YOLO screen | Matches realistic phone orientation for filming a pitch |
| Background isolate for TFLite inference | Flutter best practice; prevents UI jank during CPU-intensive inference |
| SSD MobileNet kept as fallback path | Provides a working baseline and allows comparison; does not interfere with YOLO evaluation |
| Unsplash API for demo image grid | Provides realistic, varied images for testing static photo analysis without needing a local image dataset |

---

## POC Evaluation Checklist

| Item | Status |
|---|---|
| YOLO11n runs on Android (TFLite) | ✅ Implemented — needs device testing confirmation |
| YOLO11n runs on iOS (Core ML) | ✅ Implemented — needs device testing confirmation |
| Real-time detection is smooth enough | ⏳ To be evaluated on target devices |
| Soccer ball detection accuracy acceptable | ⏳ To be evaluated with real footage |
| `ball` vs `Soccer ball` class behaviour understood | ⏳ To be evaluated |
| `tennis-ball` false positive rate acceptable | ⏳ To be evaluated |
| Battery/thermal impact acceptable | ⏳ To be evaluated |
| YOLOView renders bounding boxes natively | ❓ Unknown — needs confirmation |
| Architecture suitable to carry forward | ✅ Yes — clean separation, standard patterns |
