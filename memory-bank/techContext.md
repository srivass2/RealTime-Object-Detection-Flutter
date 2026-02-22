# Tech Context

## Framework
- **Flutter** (Dart) — cross-platform mobile framework
- **Dart SDK:** >=3.2.3 <4.0.0
- **Flutter SDK:** stable channel (exact version pinned in `.flutter-plugins`)
- **Target platforms:** iOS (primary), Android (primary), macOS/Windows/Linux/Web (scaffolded, not evaluated)

## ML / Inference Stack

### Primary Path: YOLO11n via ultralytics_yolo
| Detail | Value |
|---|---|
| Package | `ultralytics_yolo: ^0.2.0` |
| Android model | `yolo11n.tflite` in `android/app/src/main/assets/` |
| iOS model | `yolo11n.mlpackage` bundled via Xcode Resources (in `ios/` dir) |
| Model format — Android | TensorFlow Lite |
| Model format — iOS | Apple Core ML (mlpackage) |
| Inference location | On-device, fully offline |
| Label source | Embedded in model — no external label file |
| Classes | `Soccer ball`, `ball`, `tennis-ball` (3 classes) |
| Task | `YOLOTask.detect` (bounding box detection) |
| Camera management | Handled internally by `YOLOView` widget |
| Orientation | Landscape only (left + right) |

### Secondary / Fallback Path: SSD MobileNet v1 via tflite_flutter
| Detail | Value |
|---|---|
| Package | `tflite_flutter: 0.11.0` |
| Model file | `assets/model/ssd_mobilenet_v1.tflite` (4.0 MB, committed to repo) |
| Label file | `assets/label/labels.txt` (91 COCO classes) |
| Input size | 300×300 pixels (RGB) |
| Max detections | 10 per frame |
| Confidence threshold | 0.5 |
| Hardware delegate — iOS | Metal Delegate (GPU) |
| Hardware delegate — Android/other | XNNPack Delegate |
| Camera management | Flutter `camera` plugin + background Dart isolate |
| Orientation | Portrait + Landscape |

## Key Dependencies

### Runtime
```yaml
tflite_flutter: 0.11.0          # TFLite inference engine for SSD path
ultralytics_yolo: ^0.2.0        # YOLO11n integration (wraps TFLite/CoreML per platform)
image: ^4.5.2                   # Image encoding, decoding, resizing
camera: ^0.11.3+1               # Live camera feed (used by TFLite path)
image_picker: ^1.1.2            # Gallery/camera photo selection
dio: ^5.4.3+1                   # HTTP client
retrofit: ^4.1.0                # Declarative API client generation
mobx: ^2.3.3+2                  # Reactive state management
flutter_mobx: ^2.2.1+1          # MobX Flutter bindings
provider: ^6.1.2                # Dependency injection
json_annotation: ^4.8.1         # JSON model annotations
flutter_svg: ^2.0.17            # SVG icon rendering
path_provider: ^2.1.0           # Device directory access
```

### Dev / Code Generation
```yaml
build_runner: ^2.11.1           # Code generation runner
json_serializable: ^6.7.1       # fromJson/toJson generation
retrofit_generator: ^10.2.1     # Retrofit HTTP client generation
mobx_codegen: ^2.6.1            # MobX observable/action generation
flutter_lints: ^2.0.0           # Lint rules
```

## Backend Selection: Environment Variable
The active ML backend is selected **at build time** via the `DETECTOR_BACKEND` Dart environment variable:

```bash
# Run with YOLO (the real evaluation target)
flutter run --dart-define=DETECTOR_BACKEND=yolo

# Run with TFLite/SSD (legacy fallback)
flutter run --dart-define=DETECTOR_BACKEND=tflite

# Default if nothing passed → tflite
flutter run
```

This is read in both `main.dart` and `lib/config/detector_config.dart` via:
```dart
const backend = String.fromEnvironment('DETECTOR_BACKEND', defaultValue: 'tflite');
```

## Code Generation
The project uses `build_runner` for three types of generated code. After changes to annotated files, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Generated files (`*.g.dart`) are **gitignored** via `**.g.dart` in `.gitignore`.

Generated file types:
- `*.g.dart` from `json_serializable` — JSON fromJson/toJson for all `*_dm.dart` model files
- `api_service.g.dart` from `retrofit_generator` — HTTP client implementation
- `home_screen_store.g.dart` from `mobx_codegen` — MobX observable wiring

## API Integration
- **Unsplash API** — Used on the Home Screen for a demo photo grid
- Base URL: `https://api.unsplash.com`
- Auth: `Client-ID YOUR_API_KEY` header (placeholder — must be replaced with real key)
- Endpoints used: `GET /photos` (paginated list), `GET /search/photos` (search, default query: `"car "`)
- This is demo scaffolding only; not related to the detection evaluation

## Platform-Specific Configurations

### Android
- `AndroidManifest.xml`: `android:hardwareAccelerated="true"`, `launchMode="singleTop"`
- Model location: `android/app/src/main/assets/yolo11n.tflite` (gitignored)
- Supported orientations: portrait + landscape

### iOS
- `Info.plist`: Camera usage description set (placeholder text), Photo Library usage description set
- Model location: `ios/yolo11n.mlpackage` (gitignored), added to Xcode target → Build Phases → Copy Bundle Resources
- Supported orientations: portrait + landscape (left + right)
- Xcode build reference: `9883D8872F43899800AEC4E1 /* yolo11n.mlpackage in Resources */`

## Asset Structure (Committed to Repo)
```
assets/
├── model/
│   └── ssd_mobilenet_v1.tflite     # SSD fallback model only
├── label/
│   ├── labels.txt                  # 91 COCO classes (used by SSD path)
│   └── Trained_labels.txt          # Orphaned file — NOT used by YOLO path
└── vectors/
    ├── camera.svg
    ├── gallery.svg
    ├── repeate-music.svg
    ├── refresh-circle.svg
    └── repeat.svg
```

## Files That Must Be Placed Manually (Gitignored)
| File | Platform | Where to place |
|---|---|---|
| `yolo11n.tflite` | Android | `android/app/src/main/assets/` (create dir if needed) |
| `yolo11n.mlpackage` | iOS | `ios/` directory, then add to Xcode target resources |

## Linting
- `analysis_options.yaml` extends `package:flutter_lints/flutter.yaml`
- Standard Flutter recommended lint rules
