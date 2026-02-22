# CLAUDE.md — Flare Football Object Detection POC

## Session Start Instructions

When beginning a new session on this project, do the following **before touching any code**:

1. Read `memory-bank/activeContext.md` — this is the ground truth for what is currently in progress, what is known to be broken, and what decisions are pending.
2. Read `memory-bank/progress.md` — understand what is complete, what is incomplete, and the open evaluation checklist.
3. Confirm the model files are in place before doing anything YOLO-related:
   - Android: `android/app/src/main/assets/yolo11n.tflite` (gitignored — must be manually placed)
   - iOS: `ios/yolo11n.mlpackage` (gitignored — must be manually placed and confirmed in Xcode)
4. Run `flutter pub get` if packages appear out of date.
5. Re-generate code if any `*_dm.dart`, `api_service_type.dart`, or `home_screen_store.dart` files were modified since last session:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

---

## Session End Instructions

Before ending a session, update the memory-bank to preserve state:

1. **`memory-bank/activeContext.md`** — update "Working State Right Now", "What Is Partially Done", and "Immediate Next Steps".
2. **`memory-bank/progress.md`** — tick off anything completed; add new incomplete items.
3. **`memory-bank/systemPatterns.md`** — update if any new architectural patterns were introduced.
4. **Do not commit generated `*.g.dart` files** — they are gitignored and must be regenerated locally.
5. Commit meaningful code changes with descriptive messages. Do not commit model binary files (`.tflite`, `.mlpackage`).

---

## Project Overview

**Name:** Flare Football — On-Device Object Detection (Feasibility POC)

**Purpose:** This is an internal engineering feasibility study, not a production app. It evaluates whether YOLO11n can run real-time, on-device soccer ball detection on mobile devices at acceptable speed and accuracy. The output of this POC determines whether to invest in building this feature into the real Flare Football product.

**Core Research Questions:**
- Can YOLO11n (nano) run in real-time on mobile without unacceptable latency or battery impact?
- Is the custom-trained model accurate enough to reliably detect soccer balls in pitch/game conditions?
- Does the Flutter + `ultralytics_yolo` integration work on both Android (TFLite) and iOS (Core ML) with acceptable performance parity?
- Is landscape-mode camera orientation suitable for the detection use case?

**Target Test Devices:**
- iOS: iPhone 12 (A14 Bionic, iOS 17.1.2)
- Android: Samsung Galaxy A32 4G (SM-A325F, Android 12, API 31)

**Dev Environment:**
- MacBook Pro (Apple M5, 16GB RAM, macOS Tahoe 26.0)
- Flutter 3.38.9 / Dart 3.10.8
- Xcode 26.2 / CocoaPods 1.16.2
- VS Code 1.109.1 / Android SDK 36.1.0

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) — SDK `>=3.2.3 <4.0.0` |
| Primary ML | YOLO11n via `ultralytics_yolo: ^0.2.0` |
| Fallback ML | SSD MobileNet v1 via `tflite_flutter: 0.11.0` |
| Android model format | TensorFlow Lite (`.tflite`) |
| iOS model format | Apple Core ML (`.mlpackage`) |
| State management | MobX (`mobx: ^2.3.3+2`, `flutter_mobx: ^2.2.1+1`) |
| HTTP client | Dio `^5.4.3+1` + Retrofit `^4.1.0` (declarative) |
| JSON serialization | `json_serializable: ^6.7.1` |
| Camera (TFLite path) | `camera: ^0.11.3+1` |
| Image processing | `image: ^4.5.2` |
| DI / service locator | `provider: ^6.1.2` |
| Code generation | `build_runner`, `mobx_codegen`, `retrofit_generator`, `json_serializable` |
| SVG rendering | `flutter_svg: ^2.0.17` |

---

## Architecture Rules

### 1. Two Independent Detection Pipelines — Never Mix Them

The app has two completely independent ML pipelines selected **at build time** via `DETECTOR_BACKEND`. They share only the shell (routing, home screen). Code that belongs to one pipeline must not reference the other pipeline's types, services, or widgets.

```
DETECTOR_BACKEND=yolo   → YOLOView widget (ultralytics_yolo) — primary evaluation target
DETECTOR_BACKEND=tflite → TensorflowService + Detector isolate (SSD MobileNet) — fallback
```

Backend selection flows through `lib/config/detector_config.dart`. All conditional branching in the app (in `initState`, `build`, etc.) must check `DetectorConfig.backend` against the `DetectorBackend` enum — never hardcode strings.

### 2. Singleton Pattern for Services

`TensorflowService`, `NavigationService`, and `SnackBarService` are singletons. Do not add `new` instantiations. The TFLite interpreter is loaded exactly once through this pattern. New services should follow the same private named constructor pattern.

### 3. Background Isolate for TFLite Inference

The SSD path runs inference in a separate Dart isolate (`lib/services/detector.dart`). This is non-negotiable — inference on the UI thread causes jank. The YOLO path handles its own threading internally via `YOLOView`. Do not attempt to run TFLite inference synchronously on the main isolate.

### 4. MobX for Home Screen State Only

MobX (`@observable`, `@action`, `Observer`) is used only on the Home Screen via `HomeScreenStore`. Other screens use `setState` directly. Do not introduce MobX into new screens unless there is a clear need for reactive state across multiple observers.

### 5. Platform-Aware Model Path for YOLO

The YOLO model path is always resolved as:
```dart
modelPath: Platform.isIOS ? 'yolo11n' : 'yolo11n.tflite'
```
iOS loads from the Xcode bundle (Core ML). Android loads from `android/app/src/main/assets/`. Do not change this pattern without understanding the platform constraints.

### 6. Landscape Orientation Lock for YOLO Screen

The `LiveObjectDetectionScreen` in YOLO mode forces landscape orientation in `initState` and must restore portrait+landscape in `dispose`. Never remove the restore call — it will lock the whole app to landscape permanently.

### 7. Code Generation is Required

The following files are auto-generated and must **not** be edited by hand:
- All `*.g.dart` files (JSON serialization, Retrofit client, MobX store wiring)

After modifying any annotated model (`*_dm.dart`), `api_service_type.dart`, or `home_screen_store.dart`, regenerate:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Code Generation Rules

- `*_dm.dart` model files must use `@JsonSerializable(fieldRename: FieldRename.snake)` for automatic camelCase ↔ snake_case mapping.
- API endpoints are declared in `lib/apibase/api_service_type.dart` using Retrofit annotations. The implementation in `api_service.g.dart` is generated — do not edit it.
- MobX observables and actions live in `home_screen_store.dart`. The wired version in `home_screen_store.g.dart` is generated — do not edit it.
- Never commit `*.g.dart` files — they are gitignored.

---

## Key File Map

| Concern | File |
|---|---|
| Entry point + backend init | `lib/main.dart` |
| Backend enum + config | `lib/config/detector_config.dart` |
| Route definitions | `lib/values/app_routes.dart`, `lib/routes.dart` |
| App root | `lib/app.dart` |
| YOLO live screen | `lib/screens/live_object_detection/live_object_detection_screen.dart` |
| TFLite isolate | `lib/services/detector.dart` |
| TFLite model service | `lib/services/tensorflow_service.dart` |
| TFLite inference helpers | `lib/utils/tensorflow_helper.dart` |
| Image format conversion | `lib/utils/image_utils.dart` |
| Detection result model | `lib/models/detected_object/detected_object_dm.dart` |
| Home screen + MobX store | `lib/screens/home/home_screen.dart`, `home_screen_store.dart` |
| Static photo analysis | `lib/screens/photo_analyzed/photo_analyze_screen.dart` |
| API client | `lib/apibase/api_service.dart`, `api_service_type.dart` |
| Constants | `lib/values/app_constants.dart` |
| Navigation | `lib/services/navigation_service.dart` |
| Bounding box widget | `lib/widgets/box_widget.dart` |

---

## Build Commands

### Run (YOLO mode — primary evaluation target)
```bash
flutter run --dart-define=DETECTOR_BACKEND=yolo
```

### Run (TFLite/SSD mode — fallback)
```bash
flutter run --dart-define=DETECTOR_BACKEND=tflite
# or simply (tflite is the default):
flutter run
```

### Regenerate all code-gen files
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Watch mode (code gen, during active model development)
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Get dependencies
```bash
flutter pub get
```

### Run linter
```bash
flutter analyze
```

### Build iOS (release)
```bash
flutter build ios --dart-define=DETECTOR_BACKEND=yolo
```

### Build Android (release)
```bash
flutter build apk --dart-define=DETECTOR_BACKEND=yolo
```

---

## Model File Setup (Required — Gitignored)

These binary files must be placed manually on each developer machine. They are intentionally excluded from version control.

**Android:**
```bash
mkdir -p android/app/src/main/assets
cp /path/to/yolo11n.tflite android/app/src/main/assets/
```

**iOS:**
1. Copy `yolo11n.mlpackage` into the `ios/` directory.
2. Open `ios/Runner.xcworkspace` in Xcode.
3. Confirm `yolo11n.mlpackage` appears under Runner → Build Phases → Copy Bundle Resources.
   (Xcode reference `9883D8872F43899800AEC4E1` already exists — you are confirming the file is physically present, not re-adding the reference.)

---

## What Never to Touch Without Asking

The following require explicit discussion before changes are made:

1. **`lib/config/detector_config.dart`** — Changes here affect the entire backend-switching system. Altering the enum or environment variable key silently breaks both pipelines.

2. **`ios/Runner.xcodeproj/project.pbxproj`** — The Xcode project file. Manual edits here frequently corrupt the project. Only modify via Xcode UI.

3. **`android/app/src/main/AndroidManifest.xml`** — `hardwareAccelerated="true"` and `launchMode="singleTop"` are set deliberately. Do not remove them.

4. **Orientation logic in `live_object_detection_screen.dart`** — The `SystemChrome.setPreferredOrientations` calls in `initState` and `dispose` are a matched pair. Removing or reordering them locks the whole app to a single orientation permanently.

5. **`pubspec.yaml` dependency versions** — `tflite_flutter` is pinned at exactly `0.11.0` (not `^0.11.0`). `ultralytics_yolo` is at `^0.2.0`. These are not interchangeable — minor version bumps have broken the ML pipeline in this project before. Do not upgrade without testing on both platforms.

6. **`assets/model/ssd_mobilenet_v1.tflite`** — The only model binary committed to the repo. Do not delete or replace without understanding the TFLite fallback path.

7. **`ios/yolo11n.mlpackage` and `android/app/src/main/assets/yolo11n.tflite`** — These are custom-trained models specific to this project (3 classes: `Soccer ball`, `ball`, `tennis-ball`). Do not replace with a generic COCO model without flagging the change — all evaluation data would be invalidated.

8. **`memory-bank/` directory** — These files are the project's institutional memory. Do not delete, rename, or restructure without explicit instruction.

---

## Known Issues and Technical Debt (Do Not "Fix" Without Checking)

| Issue | Status | Notes |
|---|---|---|
| iOS diagnostic probe in `main.dart` | Technical debt | A `try/catch` that attempts to load `assets/model/yolo11n.tflite` on iOS. Always fails by design. Remove once iOS mlpackage path is confirmed. |
| Unsplash API key placeholder | Config gap | `'Client-ID YOUR_API_KEY'` in `api_service.dart`. 401 errors on home photo grid until replaced. Does not affect detection. |
| iOS `NSCameraUsageDescription` placeholder | Minor | `"your usage description here"` in `Info.plist`. Must update before any external build. |
| `Trained_labels.txt` | Orphaned file | `assets/label/Trained_labels.txt` is not referenced anywhere. Safe to delete. |
| `DetectorBackend.mlkit` | Stub only | Declared in enum, no implementation. Falls through silently if used. |
| `test/widget_test.dart` | Stale | Tests a boilerplate counter app. Not valid for this project. |
| YOLO `onResult` bounding box rendering | Unknown | `YOLOView` may render boxes natively. If not, a custom overlay using `results` data needs to be built. |

---

## Detection Classes (Custom YOLO11n Model)

| Class | Notes |
|---|---|
| `Soccer ball` | Primary target |
| `ball` | General ball; also fires on soccer balls |
| `tennis-ball` | Incidental; evaluate false positive rate |

Labels are **embedded in the model** — there is no external label file for the YOLO path. `assets/label/labels.txt` is for the SSD MobileNet path (91 COCO classes).

---

## What Is Out of Scope for This POC

Do not introduce these unless explicitly instructed:

- Production UI polish or design system
- User authentication, accounts, or sessions
- Uploading or persisting detection results
- Server-side / cloud inference
- Video recording or playback
- Any screen beyond the three that exist (Home, Live Camera, Photo Analysis)
