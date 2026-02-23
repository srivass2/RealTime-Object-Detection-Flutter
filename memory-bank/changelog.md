# Changelog — Code Quality Cleanup (2026-02-23)

## Summary

Resolved all 7 `flutter analyze` issues (0 remaining) and 1 failing test (now 3 passing).

## Changes by File

### lib/main.dart
- **Removed iOS diagnostic probe** (lines 23–34) — temporary `try/catch` block that attempted to load `yolo11n.tflite` from Flutter assets on iOS. This was documented technical debt in `activeContext.md`; it always failed by design and produced noisy logs. The real iOS model loads via the Xcode bundle separately.
- **Replaced `print()` with `log()`** (line 21) — `print('DETECTOR_BACKEND = $backend')` changed to `log(...)` from `dart:developer` to satisfy `avoid_print` lint.
- **Removed unused imports** — `dart:io` and `package:tflite_flutter/tflite_flutter.dart` were only used by the diagnostic probe.

### lib/screens/home/home_screen_store.dart
- **Added lint suppression** — `// ignore_for_file: library_private_types_in_public_api` at file top. This is the standard MobX code-gen pattern (`class HomeScreenStore = _HomeScreenStore with _$HomeScreenStore`) and cannot be restructured without breaking the MobX mixin.

### lib/screens/live_object_detection/live_object_detection_screen.dart
- **Replaced deprecated `withOpacity()`** (lines 187, 210) — `Colors.white.withOpacity(0.3)` changed to `Colors.white.withValues(alpha: 0.3)` on both the gallery and flip-camera buttons. The `withOpacity` API was deprecated in favour of `withValues` to avoid precision loss.
- **Replaced `print()` with `log()`** (line 291) — camera preview size debug output changed from `print` to `dart:developer` `log()` to satisfy `avoid_print` lint.

### test/widget_test.dart
- **Replaced stale counter app test** with meaningful `DetectorConfig` unit tests:
  1. Verifies default backend is `tflite` when no `DETECTOR_BACKEND` env var is set
  2. Verifies label returns `'TFLite'` for the default backend
  3. Verifies the `DetectorBackend` enum contains all expected values (`tflite`, `yolo`, `mlkit`)
- The previous test pumped `MyApp` and asserted counter widget text that doesn't exist in this app. The new tests verify actual project logic without triggering HTTP calls or native plugin dependencies.

## Verification

```
$ flutter analyze
Analyzing object_detection...
No issues found! (ran in 2.2s)

$ flutter test
00:02 +3: All tests passed!
```
