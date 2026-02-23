# Pitfalls Research

**Domain:** Flutter on-device ML — frame-to-frame ball tracking with visual trail on dual-pipeline detection app
**Researched:** 2026-02-23
**Confidence:** HIGH (architecture pitfalls derived from existing codebase + verified against official Flutter platform view docs and ultralytics_yolo GitHub issues)

---

## Critical Pitfalls

### Pitfall 1: YOLOView Custom Overlay Blocked by Native Bounding Box Rendering

**What goes wrong:**
`YOLOView` renders its own native bounding boxes by default. When you add a Flutter `CustomPainter` overlay in a `Stack` above `YOLOView`, you end up with duplicate boxes — one from the native layer and one from your Flutter paint code. Disabling the native boxes requires either using `showOverlays: false` (if the version supports it via a controller) or patching native platform code directly. Without this, the trail painter draws _on top of_ native boxes, not _instead of_ them, and the visual result is incoherent.

**Why it happens:**
`YOLOView` is a platform view (Android: `PlatformViewSurface`, iOS: `UiKitView`). Its rendering lives in a native layer below Flutter's widget tree. Flutter widgets placed in a `Stack` above it render in a separate Flutter layer. Both layers render independently — Flutter does not know what the native layer is drawing.

**How to avoid:**
Before writing any trail rendering code, explicitly confirm whether `ultralytics_yolo ^0.2.0` exposes a `showOverlays` parameter or a controller method like `controller.setShowOverlays(false)`. Check the installed version's API by reading the generated `.dart` files in `.pub-cache`. If `showOverlays` is not available in `^0.2.0`, the native overlay must be disabled at the platform layer (modify the Android/iOS plugin source via a local path override). Do not proceed to trail rendering until native boxes are definitively off or confirmed as non-interfering.

**Warning signs:**
Two sets of bounding boxes visible simultaneously on the YOLO camera screen. Or: trail dots visible but mispositioned because they were designed to compensate for a duplicate layer that was later removed.

**Phase to address:**
Phase 1 — first deliverable of the tracking milestone. Establish the overlay architecture (can Flutter CustomPainter overlay YOLOView cleanly?) before committing to any trail logic.

---

### Pitfall 2: Coordinate Space Mismatch Between onResult Data and Overlay Canvas

**What goes wrong:**
The `onResult` callback from `YOLOView` returns detection results. The bounding box values in those results exist in a specific coordinate space (historically pixel-relative to the native camera preview, but with documented platform-specific offset bugs — see GitHub issue #105 in the yolo-flutter-app repo). If you extract the ball center from `result.boundingBox` and pass it directly to a `CustomPainter`, trail dots appear offset from the ball's actual position. On iOS, Core ML coordinate transformation adds an additional platform-specific scale factor.

For the **SSD/TFLite path**, the existing `renderLocation` getter in `DetectedObjectDm` uses `ScreenParams.screenPreviewSize` scaled against `AppConstants.ssdCompatibleImageWidth/Height` (both 300). This scaling was designed for portrait `CameraPreview`. It is not validated for landscape mode and may produce incorrect coordinates if the tracking overlay is added to a landscape-oriented YOLO screen variant of the TFLite path.

**Why it happens:**
Model inference runs on image data with fixed input dimensions (300x300 for SSD, scaled to network input for YOLO). The screen/preview dimensions differ. The coordinate mapping formula must account for the ratio between model input size, camera preview capture size, and rendered widget size — and these three values are rarely identical. In landscape mode, width and height swap relative to portrait, breaking any formula that treats them as fixed.

**How to avoid:**
Write a coordinate normalizer before any trail state management. Take the raw bounding box from `onResult`, compute the center point, and verify it matches the ball's visual position on screen by temporarily drawing a single dot at that point (no trail yet). Do this on both iOS and Android. Only proceed to trail accumulation once the dot reliably tracks the ball. For the TFLite path, audit `ScreenParams.screenPreviewSize` under landscape conditions — the current formula `Size(screenSize.width, screenSize.width * previewRatio)` assumes portrait layout.

**Warning signs:**
Trail dots appear consistently offset in one direction. Dots drift when the phone rotates. Dots appear correct on one platform but wrong on the other. The bounding box appears correct but the center point extraction produces a different position.

**Phase to address:**
Phase 1 — coordinate correctness must be proven before trail accumulation is built on top of it.

---

### Pitfall 3: Unbounded Trail Position History Causes Memory Growth and Paint Jank

**What goes wrong:**
Tracking is implemented as a `List<Offset>` that appends the ball center on every frame. At 15-30 fps, this list grows by 15-30 entries per second with no bound. After 60 seconds of tracking: 900-1800 entries. The `CustomPainter.paint` method iterates the entire list to draw dots and lines on every frame. On a Galaxy A32 (already near its CPU limit from inference), the paint call latency grows linearly with the list, eventually exceeding one frame budget and causing dropped frames.

**Why it happens:**
The natural implementation is `trailPoints.add(center)`. There is no natural stopping point, and the growth is slow enough to be invisible during short manual tests but present in real-use sessions where a player films for several minutes.

**How to avoid:**
Use `dart:collection Queue<Offset>` with a fixed capacity (e.g., 90 entries = ~3 seconds at 30fps). On each new detection: `trailPoints.addLast(center); if (trailPoints.length > maxTrailLength) trailPoints.removeFirst()`. Never use a `List` with unbounded `add`. Additionally, in `CustomPainter.paint`, avoid allocating new `Path` objects on every call — declare them as fields and call `reset()`.

**Warning signs:**
Smooth performance for the first 30 seconds, then progressively worsening jank. Flutter DevTools Memory tab shows `Queue<Offset>` or `List<Offset>` instance count growing without plateau. Performance Overlay shows UI thread times increasing linearly over the session.

**Phase to address:**
Phase 2 — when trail accumulation logic is first implemented. The cap must be in place from the first commit of trail state management.

---

### Pitfall 4: CustomPainter Repaints Every Frame Even When Detection Has Not Changed

**What goes wrong:**
`CustomPainter.shouldRepaint` returns `true` unconditionally (the default when overriding carelessly), or the parent `setState` call triggers a full widget tree rebuild on every detection result, which forces `CustomPainter.paint` to run even when the trail has not changed. On mid-range devices, this doubles the rendering work: once from the incoming detection frame, once from a spurious repaint triggered by an unrelated widget rebuilding.

**Why it happens:**
`setState` anywhere in `_LiveObjectDetectionScreenState` invalidates the entire widget subtree below the `State`. If trail state and UI state (e.g., a frame counter badge, backend label) share the same `State`, any detection result triggers a full rebuild of everything including the `CustomPainter`. Developers typically call `setState(() => trailPoints.add(center))` which correctly invalidates the painter, but also invalidates the `AppBar`, backend label badge, and all other children.

**How to avoid:**
Isolate the trail painter in a dedicated `StatefulWidget` with its own `State`. Pass trail updates via a `ValueNotifier<Queue<Offset>>` and use `ValueListenableBuilder` to rebuild only the painter widget. Implement `shouldRepaint` to compare the previous and current trail length (or a version counter) — return `false` when the trail has not changed. Wrap the painter in `RepaintBoundary`.

**Warning signs:**
Flutter DevTools Widget Rebuild Inspector shows the backend label badge or AppBar rebuilding 15-30 times per second. `shouldRepaint` is never called (means it always returns `true` via the base implementation). GPU thread frame times are lower than expected but UI thread times are higher than expected.

**Phase to address:**
Phase 2 — during trail rendering implementation. Must be addressed before performance testing on target devices.

---

### Pitfall 5: Race Condition Between Isolate Detection Results and Widget Disposal

**What goes wrong:**
The TFLite path uses a `StreamSubscription` on `detector.resultsStream`. If the user navigates away from `LiveObjectDetectionScreen` while a detection result is in-flight from the isolate, the stream delivers results after `dispose()` has been called. If the callback calls `setState()` on a disposed `State`, Flutter throws: `setState() called after dispose()`. With tracking state added, the risk is elevated because trail updates happen on every frame, maximizing the window for disposal race conditions.

This risk exists today in the codebase. The `_objectDetectorStream` subscription is cancelled in `dispose()`, but there is a window between the isolate sending a result and the main isolate processing the cancel. The current code guards with `if (mounted) setState(...)` inside the listener — this must be preserved and extended to any new tracking-related callbacks.

**Why it happens:**
Dart isolates communicate via message passing. There is no synchronous cancellation — a `cancel()` call stops future deliveries but does not purge messages already queued in the receive port. The detection result message can arrive between the `cancel()` call and the actual disposal completing.

**How to avoid:**
Every callback that calls `setState` or modifies any state derived from detection results must begin with `if (!mounted) return;`. This pattern is already in `_initializeDetector`'s stream listener — it must be replicated verbatim in any new tracking callback. For the YOLO path's `onResult`, the same guard applies: `onResult: (results) { if (!mounted) return; ... }`.

**Warning signs:**
`setState() called after dispose()` exception in crash logs or debug console when rapidly navigating in/out of the detection screen. The issue is intermittent and harder to reproduce on fast devices — always test on target devices (Galaxy A32) at low battery where frame processing is slower.

**Phase to address:**
Phase 1 — the `mounted` guard must be added to `onResult` when wiring the YOLO overlay. Must not be deferred.

---

### Pitfall 6: Class Label Ambiguity — Tracking the Wrong Detection Across Frames

**What goes wrong:**
The custom YOLO11n model has three classes: `Soccer ball`, `ball`, and `tennis-ball`. In any given frame, the model may fire multiple detections across these classes. A naive tracking implementation picks the first result from the `results` list, which may be a `tennis-ball` false positive rather than the soccer ball. This causes the trail to jump erratically between different detections, producing a nonsensical path.

Additionally, in frames with multiple detections (e.g., two `ball` detections), no association logic exists to determine which detection corresponds to the ball tracked in the previous frame. Picking highest confidence alone is insufficient — a stationary `tennis-ball` at high confidence can outrank the moving soccer ball at lower confidence.

**Why it happens:**
The natural implementation iterates `results` and picks `results.first` or `results.maxBy(confidence)`. Neither accounts for spatial continuity (which detection is closest to the last known position) or class priority (soccer ball > ball > tennis-ball).

**How to avoid:**
Define a class priority filter: accept `Soccer ball` and `ball`, reject `tennis-ball`. Among accepted detections, use nearest-to-last-known-position as the tiebreaker, not highest confidence. Cap "nearest" with a maximum distance threshold — if no detection is within a radius of the last known position, treat the frame as an occlusion (no trail point added) rather than a jump.

**Warning signs:**
Trail path makes sudden large jumps between frames. Trail tracks a tennis ball in the corner while ignoring a moving soccer ball in the center. Trail appears correct during controlled tests but breaks during actual gameplay footage with multiple objects.

**Phase to address:**
Phase 2 — implement class filtering and nearest-neighbor selection before any evaluation of tracking quality.

---

### Pitfall 7: Landscape Orientation Breaks SSD Path Coordinate Scaling

**What goes wrong:**
`ScreenParams.screenPreviewSize` returns `Size(screenSize.width, screenSize.width * previewRatio)`. `screenSize` is set from `MediaQuery.of(context).size`, which in portrait returns `(width=short, height=long)`. In landscape, `MediaQuery` returns `(width=long, height=short)`. If the SSD tracking screen is ever forced to landscape (to match the YOLO evaluation mode for comparison), or if device orientation naturally affects `MediaQuery` during the session, `screenPreviewSize` will compute a physically incorrect size and all overlay coordinates will be wrong.

The YOLO path locks to landscape explicitly. The SSD path does not lock orientation but runs in whatever the device default is. This asymmetry means the two pipelines operate in different coordinate systems — making a direct performance comparison unreliable.

**Why it happens:**
`ScreenParams` was designed for portrait TFLite mode and was never tested in landscape. The formulas assume portrait-first orientation.

**How to avoid:**
For tracking milestone: keep the SSD path in portrait mode and explicitly document the asymmetry. Do not attempt landscape on the SSD path without auditing `ScreenParams.screenPreviewSize` first. If landscape comparison is needed, update `screenPreviewSize` to swap width/height based on `MediaQuery.of(context).orientation`.

**Warning signs:**
Trail dots appear in the wrong quadrant on the SSD path. Bounding boxes that were previously correct on SSD now appear offset after any orientation change event.

**Phase to address:**
Phase 1 — document this constraint and lock SSD orientation explicitly before any tracking code is added.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Using `List.add` for trail with no cap | Simple first implementation | Memory growth over multi-minute sessions, linear paint cost | Never — cap must be in first commit |
| `shouldRepaint` returns `true` always | Simplest correct implementation | Extra paint calls every frame on mid-range device | Only during initial proof-of-concept; fix before device testing |
| Single `State` holding both UI and tracking state | Less code, fewer files | `setState` cascades through full widget tree on every detection frame | Never for the trail painter — isolate it |
| Picking `results.first` for tracked ball | No filtering logic required | Erratic trail when non-ball classes are detected | Never beyond first smoke test |
| Skipping `mounted` check in `onResult` | Shorter callback | Silent crash risk on navigation away during active detection | Never — always include |
| Not testing coordinate mapping on both platforms before trail accumulation | Faster to code | Trail built on wrong coordinate space; refactor required | Never — verify coordinates first |
| Leaving native YOLOView bounding boxes active while adding Flutter trail | No native code changes needed | Duplicate visual clutter; incorrect depth layering | POC only if evaluation only needs trail, not clean UI |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `YOLOView` + `Stack` overlay | Assume Flutter widgets render above YOLOView transparently | Verify that `Stack` children above `YOLOView` actually appear visually — platform view rendering order is not guaranteed to behave like Flutter widget Z-order in all Android rendering modes |
| `YOLOView.onResult` coordinate extraction | Use raw `boundingBox` values as pixel-accurate screen positions | Verify on both platforms with a single debug dot before building trail; apply platform-specific correction if coordinates are offset (documented in issue #105) |
| TFLite isolate stream + tracking state | Add trail update directly inside `resultsStream.listen` with `setState` | Guard with `if (!mounted) return;`; consider a `ValueNotifier` to decouple stream delivery from widget rebuild |
| SSD `renderLocation` + landscape | Use `renderLocation` getter as-is in landscape mode | Audit `ScreenParams.screenPreviewSize` — it was calibrated for portrait; landscape swaps width/height in `MediaQuery` |
| `CustomPainter` + detection frames | Call `setState` on every detection to trigger repaint | Use `CustomPainter(repaint: trailNotifier)` pattern with `ValueListenableBuilder` to limit rebuild scope |
| `Queue<Offset>` + `CustomPainter` | Pass `Queue` by reference to painter; mutate it externally | Pass an immutable snapshot (`.toList()`) to the painter on each repaint, or use a `ValueNotifier` and ensure the painter reads a stable copy during `paint` |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Unbounded trail `List<Offset>` | Smooth start, progressive jank after 30-60 seconds | `Queue` with fixed max length (e.g., 90 points) | After ~2 minutes continuous tracking at 30fps |
| `CustomPainter.paint` allocating `Path()` on every call | High CPU utilization visible in DevTools, increasing over time | Declare `Path` as instance field, call `.reset()` at the start of `paint` | Immediately, at high frame rates |
| `setState` on the full detection screen State | Widget rebuild count = fps in Flutter DevTools inspector | Isolate painter in its own widget; use `ValueNotifier` | At first frame — always inefficient but only visible on constrained devices |
| Drawing full trail with `canvas.drawPath` + anti-aliasing at 30fps | GPU thread frames exceed budget, dropped frames | Use `Paint` with `isAntiAlias: false` for trail dots; reduce max trail length | On Galaxy A32 at sustained inference load |
| Animating trail fade with `AnimationController` ticking at 60fps | Animation controller adds 60fps repaint pressure on top of ~15-30fps detection | Use timestamp-based opacity calculation in `paint` method rather than a separate ticker; compute opacity from `(DateTime.now() - timestamp).inMilliseconds / fadeMs` | Constant overhead on every frame regardless of detection activity |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Trail jumps to new position on occlusion re-detection | Trail shows a misleading line across the frame where the ball was never present | On re-detection after gap: start a new trail segment (do not connect to previous end point); leave a visible break in the path |
| Trail visible at app startup before ball is detected | Stale trail from previous session or default `Offset.zero` appears at top-left corner | Initialize trail as empty; only add points after first valid detection in the current session |
| Trail persists after navigating away and returning | Historical trail from previous session misleads evaluation | Clear trail state on screen `initState` and on `dispose` |
| Tennis-ball being tracked shown with same trail style as soccer ball | Evaluator cannot distinguish false positives from true detections | Add class label to each trail point; render `tennis-ball` trail in a different color (or suppress entirely) for evaluation clarity |

---

## "Looks Done But Isn't" Checklist

- [ ] **Trail coordinate mapping:** Visually verified on both iOS (iPhone 12) and Android (Galaxy A32) that trail dots center on the ball — not just that they appear somewhere on screen
- [ ] **Occlusion handling:** Trail pauses with a visible gap when ball is lost, resumes correctly — not just "no crash when no detection"
- [ ] **Disposal guard:** `mounted` check present in every callback that calls `setState` or modifies tracking state — not just in the stream listener
- [ ] **Trail length cap:** `Queue` max length is enforced from the first commit — not added later after memory complaints
- [ ] **Native overlay disabled or intentionally left on:** A deliberate decision is recorded about whether `YOLOView`'s native bounding boxes are suppressed — not assumed to be off
- [ ] **SSD path orientation locked:** Confirmed that `ScreenParams` coordinates are valid in the orientation used for SSD tracking tests — not assumed to be identical to YOLO path
- [ ] **Class filter applied:** Trail only tracks `Soccer ball` and `ball` results — `tennis-ball` filtered out or given separate treatment, not silently included
- [ ] **Pipeline independence preserved:** YOLO tracking code imports nothing from TFLite path and vice versa — no cross-imports

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Coordinate space mismatch discovered after trail logic built | MEDIUM | Write a coordinate normalizer function; pass all existing trail accumulation through it; requires re-testing on both platforms |
| Unbounded list discovered after memory reports | LOW | Swap `List` for `Queue` with cap; no API change needed; one-hour fix |
| Native overlay conflict discovered late | MEDIUM-HIGH | Investigate `showOverlays` parameter or local plugin override; may require native iOS/Android changes if parameter not exposed in ^0.2.0 |
| `setState()` after dispose crash | LOW | Add `if (!mounted) return;` guards; test coverage requires navigation stress test |
| Trail jumps on occlusion | LOW | Add frame gap detection (null detection → no trail point); start new segment on resume |
| Class ambiguity producing erratic trail | LOW-MEDIUM | Add priority filter + nearest-neighbor selection; requires evaluation data to tune distance threshold |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-----------------|--------------|
| YOLOView overlay layering (Pitfall 1) | Phase 1: Overlay Architecture | Single debug widget visible above YOLOView on both platforms |
| Coordinate space mismatch (Pitfall 2) | Phase 1: Overlay Architecture | Single dot tracks ball center accurately on both platforms and orientations |
| Unbounded trail memory (Pitfall 3) | Phase 2: Trail Accumulation | `Queue` with cap confirmed in code review; no memory growth in 5-minute session |
| CustomPainter rebuild frequency (Pitfall 4) | Phase 2: Trail Rendering | Widget rebuild count in DevTools stays bounded; `shouldRepaint` implemented |
| Isolate disposal race condition (Pitfall 5) | Phase 1: Overlay Architecture | `mounted` guard present in `onResult` and stream listener; navigation stress test passes |
| Class label ambiguity (Pitfall 6) | Phase 2: Trail Accumulation | Trail follows soccer ball through `tennis-ball`-present scenes; no erratic jumps |
| Landscape orientation coordinate break (Pitfall 7) | Phase 1: Overlay Architecture | SSD orientation locked and documented; YOLO landscape confirmed |

---

## Sources

- ultralytics/yolo-flutter-app GitHub Issue #255 — "Add option to disable bounding box overlay": [https://github.com/ultralytics/yolo-flutter-app/issues/255](https://github.com/ultralytics/yolo-flutter-app/issues/255)
- ultralytics/yolo-flutter-app GitHub Issue #46 — "Drawing the bounding boxes on detection" (coordinate space evidence): [https://github.com/ultralytics/yolo-flutter-app/issues/46](https://github.com/ultralytics/yolo-flutter-app/issues/46)
- ultralytics/yolo-flutter-app GitHub Issue #105 — "The result box of image recognition may have offset" (platform-specific coordinate bugs): [https://github.com/ultralytics/yolo-flutter-app/issues/105](https://github.com/ultralytics/yolo-flutter-app/issues/105)
- Flutter Official Docs — "Hosting native Android views in your Flutter app with Platform Views": [https://docs.flutter.dev/platform-integration/android/platform-views](https://docs.flutter.dev/platform-integration/android/platform-views)
- Flutter Official Docs — `RepaintBoundary` class: [https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)
- Flutter Official Docs — `CustomPainter` class: [https://api.flutter.dev/flutter/rendering/CustomPainter-class.html](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
- Dart Official Docs — `Queue` / `ListQueue` class: [https://api.flutter.dev/flutter/dart-collection/ListQueue-class.html](https://api.flutter.dev/flutter/dart-collection/ListQueue-class.html)
- DCM Blog — "The Hidden Cost of Async Misuse in Flutter": [https://dcm.dev/blog/2025/05/28/hidden-cost-async-misuse-flutter-fix](https://dcm.dev/blog/2025/05/28/hidden-cost-async-misuse-flutter-fix)
- Flutter Official Docs — `setState` mounted pattern: [https://docs.flutter.dev/perf/isolates](https://docs.flutter.dev/perf/isolates)
- Existing codebase: `lib/models/screen_params.dart`, `lib/models/detected_object/detected_object_dm.dart`, `lib/services/detector.dart`, `lib/screens/live_object_detection/live_object_detection_screen.dart`

---
*Pitfalls research for: Flutter dual-pipeline ML app — ball tracking with visual trail (v1.1 milestone)*
*Researched: 2026-02-23*
