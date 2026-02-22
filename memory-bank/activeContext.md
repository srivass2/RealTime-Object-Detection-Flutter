# Active Context

## Current Focus
Evaluating the YOLO11n integration as the primary detection backend. The app runs in YOLO mode (`DETECTOR_BACKEND=yolo`) for active testing. The SSD MobileNet path is stable but is not the evaluation target.

## Working State Right Now

### What Is Fully Working
- **YOLO live camera detection** — `YOLOView` renders on both Android and iOS when the correct model files are placed in their platform directories
- **Backend switching** — `DETECTOR_BACKEND` env var correctly routes to either pipeline at build time
- **Landscape orientation** — YOLO mode forces landscape in `initState`, restores on `dispose`
- **SSD MobileNet fallback** — loads, runs inference, renders bounding boxes with labels, works for static photo analysis
- **Home screen** — Unsplash grid loads (with a valid API key), gallery picker works, tap-to-analyze works
- **Navigation** — all three routes work correctly
- **Build pipeline** — `build_runner` generates all required `.g.dart` files

### What Is Partially Done / In Progress
- **YOLO `onResult` callback** — the callback fires and logs detection count, but the results are **not yet rendered as custom UI overlays**. It is unknown whether `YOLOView` renders its own bounding boxes internally or if that needs to be built:
  ```dart
  onResult: (results) {
    log('YOLO results: ${results.length}');
    // No custom rendering yet
  },
  ```
- **iOS diagnostic code in main.dart** — there is a temporary `try/catch` block that attempts to load `yolo11n.tflite` from Flutter assets path (`assets/model/yolo11n.tflite`) on iOS as a probe. This is diagnostic scaffolding, not the real YOLO load path, and should be removed once iOS evaluation is confirmed:
  ```dart
  if (Platform.isIOS) {
    try {
      final interpreter = await Interpreter.fromAsset('assets/model/yolo11n.tflite');
      // ...
    } catch (e) {
      print('iOS FAILED to load assets/model/yolo11n.tflite: $e');
    }
  }
  ```

### Known Gaps
- **Unsplash API key** — `'Client-ID YOUR_API_KEY'` is a placeholder in `api_service.dart`. The home photo grid will return 401 errors without a real key. This only affects the demo photo grid; it does not affect detection.
- **iOS camera description** — `Info.plist` has a placeholder camera usage string: `"your usage description here"`. This should be updated before any TestFlight or external demo build.
- **`Trained_labels.txt` is orphaned** — `assets/label/Trained_labels.txt` contains `ball` and `goal` from an earlier dataset iteration. It is not used anywhere in the current codebase and can be deleted without impact.
- **`mlkit` backend stub** — `DetectorBackend.mlkit` is declared in the enum and `DetectorConfig` but has no implementation in `live_object_detection_screen.dart`. Passing `DETECTOR_BACKEND=mlkit` would fall through to the TFLite path silently.
- **Widget test is stale** — `test/widget_test.dart` tests a generic counter app scaffold, not this app. It will likely fail or be meaningless.
- **`assets/model/yolo11n.tflite` does not exist** — The iOS diagnostic probe in `main.dart` looks for `assets/model/yolo11n.tflite` via Flutter's asset system. This file is not in `assets/model/` and is not declared in `pubspec.yaml`. This probe will always log a failure on iOS — that is expected, and the real model loads via Xcode bundle separately.

## Model Files: Developer Machine Setup Required
The YOLO model files are gitignored and must be manually placed when setting up a new dev environment:

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
For running the YOLO evaluation:
```bash
flutter run --dart-define=DETECTOR_BACKEND=yolo
```

For running against SSD (legacy/fallback):
```bash
flutter run --dart-define=DETECTOR_BACKEND=tflite
# or simply:
flutter run
```

## Recent Changes (from git log)
```
d399198  code updated for landscape mode orientation
5ab9a63  Preferred orientation added as landscape
6420f2c  Update README with project and environment details
b337c48  Update README with project and environment details
320e00b  Update README with project and environment details
5c54adf  Update README with environment specifications
46a3f0b  Update README with POC Environment Specification
```
The most recent code changes were adding landscape orientation support for the YOLO screen. Before that, the work was README documentation updates.

## Immediate Next Steps (To Decide / Action)
1. **Clarify YOLOView rendering** — does `ultralytics_yolo`'s `YOLOView` render bounding boxes natively in the camera preview? If yes, no further UI work needed for the POC. If no, a custom overlay using `onResult` data needs to be built.
2. **Replace Unsplash API key** if the home screen photo grid is needed for demos
3. **Remove iOS diagnostic probe** from `main.dart` once iOS testing is complete
4. **Update Info.plist** camera usage description before any external demo
5. **Decide fate of SSD path** — keep as a fallback or remove to simplify the codebase
