# Feature Research

**Domain:** Ball tracking + visual trail overlay — mobile ML app (Flutter, on-device YOLO + SSD)
**Researched:** 2026-02-23
**Confidence:** MEDIUM-HIGH

---

## Context and Scope

This research covers the ball tracking and trail visualization feature being added in milestone v1.1
to an existing Flutter detection POC. "Users" in this context means the Flare Football engineering
team evaluating feasibility — not end-users of a shipped product. Features are judged by whether
they answer the research question, not by consumer-app standards.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features that must exist for the tracking evaluation to be meaningful. Missing any of these means
the POC fails to answer the research questions.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Frame-to-frame center-point extraction | Without a position point per frame there is nothing to track; this is the prerequisite to all other features | LOW | Extract `boundingBox` center from `YOLOResult` (YOLO path) or compute center from `DetectedObjectDm.renderLocation` (SSD path). YOLO: `result.boundingBox.center` (pixel) or `result.normalizedBox.center` (0–1). SSD: center already computable from `renderLocation`. |
| Normalized coordinate storage | Bounding boxes arrive in pixel coordinates relative to a specific preview/render size. Storing raw pixels means trail breaks on device rotation or screen resize | LOW | Store positions as fractional (0.0–1.0) relative to render area. YOLO provides `normalizedBox`; SSD path must divide `renderLocation` by `ScreenParams.screenPreviewSize`. |
| Position history buffer (fixed-length queue) | Trail requires a sequence of past positions; without a bounded buffer memory grows unbounded | LOW | Standard approach: `List<Offset?>` or Dart `Queue` with max length 30–60 entries (roughly 1–2 seconds at 30fps). `null` entries mark frames where ball was not detected. PyImageSearch canonical example uses 32-frame deque. |
| Trail rendering on camera overlay | Users need to see the trail drawn over the live camera feed | MEDIUM | Flutter `CustomPainter` on a transparent `CustomPaint` widget stacked above `YOLOView` (YOLO path) or above `CameraPreview` + `BoxWidget` layer (SSD path). `canvas.drawCircle` for dots, `canvas.drawLine` for connecting segments. |
| Trail fading / opacity decay | Without fading the trail is a permanent smear that obscures the image. "Recent movement only" is the stated requirement | LOW | Per-point opacity = `(index / bufferLength)` where index 0 is oldest. Newest point is fully opaque, oldest is near-transparent. `Paint()..color = Colors.yellow.withOpacity(opacity)`. Combine with radius taper: newest dot largest, oldest smallest. |
| Occlusion gap (null insertion) | Ball is intermittently lost. Connecting points across a gap creates a false straight-line trajectory across the screen | LOW | Insert `null` into position queue when no detection in a frame. During paint, skip `drawLine` when either endpoint is null. Trail dots continue where they exist; gap is visible as a break in the path. This is the PyImageSearch `if pts[i - 1] is None or pts[i] is None: continue` pattern. |
| Trail clears when ball leaves frame or is lost too long | If the ball exits frame and reappears elsewhere, the stale trail misleads the viewer | LOW | Buffer naturally expires stale positions as new frames push them out (ring-buffer behavior). For prolonged loss (>1 second / ~30 frames), explicitly clear the buffer. A frame counter of consecutive missed frames triggers clear. |
| Works independently on both YOLO and SSD paths | PROJECT.md explicitly states: "Tracking must work on both YOLO and SSD paths independently." Evaluating only one pipeline leaves the research question unanswered | MEDIUM | Share a `BallTracker` service class (plain Dart, no ML dependencies) that accepts normalized `Offset?` and returns the position history. Wire into `onResult` callback (YOLO) and `resultsStream` listener (SSD) separately. No cross-pipeline shared state. |
| Coordinate normalization across screen sizes | YOLO screen is landscape-locked; SSD path is portrait. Coordinates must be stable across these orientations | MEDIUM | Store in normalized (0–1) space. Denormalize to pixel coordinates at paint time using the current `Size` passed to `CustomPainter.paint()`. This is the only safe approach — never store pixel coordinates that are orientation-dependent. |

### Differentiators (Higher-value Enhancements)

Features that would make the POC more convincing but are not required to answer the core research
question. Build these only after table stakes are stable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Trail color changes with speed | Visually communicates ball velocity — high value for football analysis where pass speed matters | MEDIUM | Compute delta between current and N-frames-ago position. Map magnitude to color gradient (blue→yellow→red). Requires the position history to already exist (enhances, not replaces, table stakes trail). |
| Bounding box center dot (current-frame marker) | Visually distinguishes "ball right now" from "ball history" | LOW | Draw a distinct larger filled circle at the most-recent non-null position in the trail. Different color from trail (e.g., white dot vs. yellow trail). |
| Trail length configurable at runtime | Allows evaluator to compare short trail (sport-relevant) vs. long trail (debugging) without rebuilding | LOW | Expose a slider or tap-to-cycle button on the detection screen. Adjust `bufferLength` on `BallTracker`. POC-only UI; no design polish needed. |
| "Ball lost" indicator overlay | Clearly signals to evaluator when the model has lost the ball vs. when ball is genuinely off-camera | LOW | Show a subtle screen-edge badge (e.g., "LOST") when consecutive-miss-frame-count exceeds threshold. Remove when ball re-detected. |
| Smoothing / interpolation between detections | Reduces jitter from frame-to-frame bounding box noise without a full Kalman filter | MEDIUM | Exponential moving average: `smoothedPos = prevSmoothed * 0.7 + rawPos * 0.3`. Apply before inserting into position buffer. Tradeoff: adds 1-frame lag, reduces jitter. Research literature (ByteTrack, OC-SORT) uses Kalman for this in production; EMA is the pragmatic POC equivalent. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem natural to request but would hurt the POC.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Predictive tracking during occlusion (Kalman filter) | Sports trackers use it; would eliminate trail gaps | Significant implementation complexity (Kalman filter from scratch in Dart or wrapping a native library). PROJECT.md explicitly calls this out of scope: "Predictive tracking — happy path first." Also requires tuning per-device for acceptable latency | Insert `null` for occlusion frames (gap in trail). Evaluate whether occlusion frequency is acceptable without prediction. That IS the research finding. |
| Multi-ball tracking | Multiple balls might appear in frame | Single-ball focus is the stated use case. Multi-tracking requires object re-identification (assign consistent IDs across frames), which is a separate research problem. Adding it here muddies the results | Track highest-confidence ball-class detection only. Log when multiple are detected. |
| Velocity / speed metrics displayed on screen | Useful for coaching analytics | Requires calibrated camera-to-world coordinate mapping (known pitch dimensions, camera position). Without calibration, pixel-space velocity is meaningless for real-world football analytics. Scope-creep with no validity | Record position history. Velocity can be calculated offline from that data later. |
| Persistent trail across sessions or video recording | Useful to replay what the POC saw | Storing trail data = persistence layer = out of scope for POC per PROJECT.md: "Uploading or persisting detection/tracking results — POC only" | Evaluate in real time. Screen-record from device if a persistent record is needed. |
| Server-side tracking with client visualization | Offloads computation, potentially more accurate | Contradicts the core constraint: "On-device only: No network calls for inference or tracking." Would invalidate the entire POC as an on-device feasibility study | Keep all tracking logic in Dart on device. |

---

## Feature Dependencies

```
[Position History Buffer]
    └──requires──> [Center-Point Extraction]
                       └──requires──> [YOLO onResult or SSD resultsStream]
                                          (both already implemented in v1.0)

[Trail Rendering (CustomPainter)]
    └──requires──> [Position History Buffer]
    └──requires──> [Normalized Coordinate Storage]

[Trail Fading]
    └──requires──> [Position History Buffer]
    └──enhances──> [Trail Rendering]

[Occlusion Gap (null insertion)]
    └──requires──> [Position History Buffer]
    └──enhances──> [Trail Rendering]

[Trail Color by Speed]
    └──requires──> [Position History Buffer]
    └──enhances──> [Trail Rendering]
    (differentiator — build after table stakes)

[Both Pipelines Supported]
    └──requires──> [Center-Point Extraction] (wired into both onResult AND resultsStream)
    └──requires──> [Shared BallTracker class] (pipeline-agnostic Dart class)
```

### Dependency Notes

- **Trail Rendering requires Position History Buffer:** You cannot draw a trail without past positions. The buffer must exist and be populated before any painter is wired up.
- **Normalized Coordinate Storage is required before Trail Rendering:** If positions are stored in pixel space and the painter runs at a different size (orientation change, aspect ratio difference between YOLO and SSD paths), the trail will be wrong. Normalize on ingestion, denormalize on paint.
- **Occlusion Gap enhances Trail Rendering:** It does not change the buffer or painter interface — it only adds `null` guard logic inside the painter loop. No extra dependencies.
- **Both Pipelines support requires a shared BallTracker:** The tracker must be a pure Dart class with no dependency on `ultralytics_yolo` or `tflite_flutter` types. Both pipelines feed it normalized `Offset?` values independently.

---

## MVP Definition

### Launch With (v1.1 — what this milestone must deliver)

These are the minimum features to answer the research question: "Is frame-to-frame tracking with a
fading trail feasible on-device at acceptable performance?"

- [ ] Center-point extraction from YOLO `onResult` results (highest-confidence ball-class only)
- [ ] Center-point extraction from SSD `resultsStream` results (highest-confidence ball-class only)
- [ ] `BallTracker` class: accepts `Offset?`, maintains normalized position queue (max 45 entries ~1.5s at 30fps)
- [ ] `null` insertion for frames with no ball detection
- [ ] `TrailPainter` (`CustomPainter`): draws dots with fading opacity and tapering radius; skips segments adjacent to `null` entries
- [ ] Trail overlay stacked above `YOLOView` (YOLO path)
- [ ] Trail overlay stacked above `CameraPreview` (SSD path)
- [ ] Trail auto-clears after 30+ consecutive missed frames
- [ ] Landscape layout respected (YOLO path is landscape-locked; painter must use correct render size)

### Add After Validation (v1.x — if POC continues)

Add these if the v1.1 trail is working and the team decides to continue refining the POC.

- [ ] "Ball lost" badge overlay — add after evaluating whether raw gap visibility is sufficient for evaluators
- [ ] Bounding box center dot (current-frame marker) — quick win, add if trail readability is poor in recordings
- [ ] EMA smoothing — add if evaluation recordings show excessive jitter, not as a pre-optimization

### Future Consideration (v2+ — real product, not POC)

Defer until a production tracking feature is formally scoped.

- [ ] Kalman filter predictive tracking — significant complexity; requires per-platform tuning
- [ ] Trail color by speed — requires validated pixel-to-world coordinate calibration to be meaningful
- [ ] Multi-ball tracking with stable IDs — separate research problem
- [ ] Configurable trail length UI control — only valuable in a product used by coaches, not for internal evaluation

---

## Feature Prioritization Matrix

| Feature | Evaluator Value | Implementation Cost | Priority |
|---------|-----------------|---------------------|----------|
| Center-point extraction (YOLO) | HIGH | LOW | P1 |
| Center-point extraction (SSD) | HIGH | LOW | P1 |
| BallTracker position buffer | HIGH | LOW | P1 |
| Null insertion for occlusion | HIGH | LOW | P1 |
| TrailPainter (dots + fading) | HIGH | MEDIUM | P1 |
| Trail overlay on YOLO path | HIGH | MEDIUM | P1 |
| Trail overlay on SSD path | HIGH | MEDIUM | P1 |
| Normalized coordinate storage | HIGH | LOW | P1 |
| Trail auto-clear on long loss | MEDIUM | LOW | P1 |
| "Ball lost" indicator badge | MEDIUM | LOW | P2 |
| Center-frame marker dot | MEDIUM | LOW | P2 |
| EMA smoothing | MEDIUM | LOW | P2 |
| Trail color by speed | LOW | MEDIUM | P3 |
| Configurable trail length | LOW | LOW | P3 |
| Kalman filter prediction | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for v1.1 milestone
- P2: Should have, add if table stakes are stable within milestone
- P3: Future consideration only

---

## Standard Behaviors (Implementation Reference)

These are the behaviors users of sports tracking tools expect, verified from literature and
established implementations.

### Frame-to-Frame Position Tracking

**Standard:** Extract the bounding box center (centroid) of the highest-confidence target-class
detection per frame. This is the universal approach across OpenCV trackers, YOLO tracking mode, and
sports-specific trackers (ByteTrack, BotSORT).

For this POC, "highest-confidence ball-class detection" means:
1. Filter `results` to classes `Soccer ball`, `ball`, `tennis-ball`
2. Take the result with highest `confidence`
3. Compute center: `Offset(box.left + box.width / 2, box.top + box.height / 2)`
4. Normalize: divide by render area width and height

**Confidence: HIGH** — confirmed by multiple sources including ultralytics_yolo API docs, PyImageSearch
tutorials, and sports tracking research.

### Visual Trail Rendering

**Standard:** Maintain a fixed-length ring buffer of past positions. Draw circles at each position
with opacity and radius decaying from newest (fully opaque, largest) to oldest (nearly transparent,
smallest). Connect adjacent non-null positions with lines of matching opacity.

**Buffer size:** 30–60 entries is the practical range. 32 is the PyImageSearch canonical example.
45 entries is a good starting point for this POC (approximately 1.5 seconds at 30fps).

**Fading formula:** `opacity = (index + 1) / bufferLength` where index 0 is oldest. Clamp to
`[0.1, 1.0]` so oldest points are faintly visible rather than invisible (aids debugging during
evaluation).

**Radius taper:** `radius = maxRadius * ((index + 1) / bufferLength)` where `maxRadius` is 6–10
logical pixels. Newest point is largest.

**Confidence: HIGH** — pattern confirmed by OpenCV tracking tutorials, Roboflow sports ball
tracking article, and general Flutter CustomPainter animation documentation.

### Trail Fading / Decay

**Standard:** Two mechanisms, use both:
1. **Time-based via buffer eviction:** Oldest positions are evicted as new ones are added (ring
   buffer). Positions older than ~1.5 seconds are automatically gone.
2. **Opacity gradient within current buffer:** Older entries within the current buffer are more
   transparent.

Do NOT use a time-based alpha that decays independently of the buffer — it adds complexity without
benefit in a frame-driven context.

**Confidence: HIGH** — standard graphics technique, well-documented in OpenGL, Flutter, and
OpenCV contexts.

### Occlusion Handling (Ball Lost / Regained)

**Standard behavior (without prediction):**
- Insert `null` into position buffer for every frame where no target-class detection occurs
- When drawing trail, skip any line segment where either endpoint is `null`
- Trail dots still render for non-null positions around the gap
- Result: visible break in the connecting lines; dots persist on both sides of gap

**Standard behavior (with prediction — out of scope for this POC):**
- Kalman filter predicts position during occlusion frames
- Trail continues through occluded region with lower visual confidence (e.g., dashed line)
- Re-detection corrects the filter state

**"Lost too long" reset:**
- Track consecutive missed-frame count
- Threshold: 30 frames (approximately 1 second at 30fps)
- Action on threshold: clear entire position buffer
- Rationale: after ~1 second without detection, any resumed detection is more likely a new
  appearance than a continuation of the same trajectory. Connecting stale trail to new position
  would be misleading.

**Confidence: HIGH** — null-based gap pattern confirmed by PyImageSearch OpenCV tutorial (direct
code evidence). Threshold value of ~30 frames / 1 second is MEDIUM confidence (common in
literature but not an official standard).

### Coordinate Normalization

**Standard:** All stored positions must be normalized to [0.0, 1.0] relative to the camera
preview render area. Denormalize only at paint time using the `Size` provided to
`CustomPainter.paint()`.

**Why it matters for this codebase specifically:**
- YOLO path is landscape-locked. SSD path is portrait. The render size differs.
- `YOLOResult.normalizedBox` is already normalized — use directly.
- `DetectedObjectDm.renderLocation` is in screen-pixel coordinates scaled by `ScreenParams`. Must
  divide by `ScreenParams.screenPreviewSize` to normalize.
- The `CustomPaint` widget should fill the same bounds as the camera view (`StackFit.expand` or
  matching `AspectRatio`). The `size` parameter in `paint(Canvas, Size)` will then match.

**Coordinate source by pipeline:**

| Pipeline | Raw Source | Normalization Needed |
|----------|------------|----------------------|
| YOLO | `YOLOResult.normalizedBox` (already 0–1) | None — use `normalizedBox.center` directly |
| YOLO (alternative) | `YOLOResult.boundingBox` (pixel) | Divide by preview pixel dimensions (need to track these) |
| SSD | `DetectedObjectDm.renderLocation` (screen pixels) | Divide by `ScreenParams.screenPreviewSize` |

Recommended: use `normalizedBox` for YOLO and normalize `renderLocation` for SSD. Both result in
`Offset` values in [0, 1] space stored in the `BallTracker` buffer.

**Confidence: HIGH** — `YOLOResult` structure confirmed via ultralytics/yolo-flutter-app API docs
showing both `boundingBox` (pixel) and `normalizedBox` (0–1) fields. SSD normalization is
verifiable from existing `DetectedObjectDm.renderLocation` and `ScreenParams` code.

---

## Competitor Feature Analysis

| Feature | OpenCV / Python ball trackers | Ultralytics YOLO track mode | Our POC Approach |
|---------|-------------------------------|------------------------------|------------------|
| Position history | `deque(maxlen=32)` with `None` sentinels | Built-in track ID + trail dict | Manual `List<Offset?>` in Dart |
| Trail rendering | `cv2.line` + thickness taper | Not a mobile rendering concern | Flutter `CustomPainter` with `canvas.drawCircle` + `canvas.drawLine` |
| Occlusion handling | `None` insertion, skip on draw | `track_buffer` param controls miss tolerance | `null` in buffer; clear after 30 missed frames |
| Prediction | Optional Kalman via SORT/ByteTrack | Built-in via BotSORT | Out of scope for POC |
| Coordinate space | Pixel (normalized per user code) | Normalized internally, exposed as pixel | Normalize to [0,1] at ingestion |
| Multi-ball | Separate track IDs per object | Native multi-track with IDs | Single ball (highest confidence) |

**Implication:** The POC deliberately implements a subset of what production trackers provide. That
is correct — the research question is whether real-time on-device tracking is feasible, not whether
it matches production tracker quality.

---

## Sources

- [Ultralytics YOLO Flutter plugin — pub.dev](https://pub.dev/packages/ultralytics_yolo) — `onResult` callback signature, `className`, `confidence` fields
- [Ultralytics yolo-flutter-app GitHub — API docs](https://github.com/ultralytics/yolo-flutter-app) — `YOLOResult.boundingBox` (pixel Rect) and `YOLOResult.normalizedBox` (0–1 Rect) confirmed
- [OpenCV Track Object Movement — PyImageSearch](https://pyimagesearch.com/2015/09/21/opencv-track-object-movement/) — canonical 32-frame deque, `None` sentinel for occlusion gaps, thickness taper formula
- [Multi-Object Tracking — Ultralytics YOLO Docs](https://docs.ultralytics.com/modes/track/) — `trail_depth`, `track_buffer` parameters; trail dict keyed by track IDs
- [Ball Tracking in Sports with Computer Vision — Roboflow](https://blog.roboflow.com/tracking-ball-sports-computer-vision/) — buffer-of-positions trail pattern, color palette interpolation
- [Object Tracking: Must-Know Techniques — Label Your Data](https://labelyourdata.com/articles/machine-learning/object-tracking) — ByteTrack, OC-SORT, Kalman filter occlusion handling overview
- [Player and Ball Detection with YOLO + BotSORT — Medium](https://medium.com/@nikhilc2209/player-and-ball-detection-using-yolov8-botsort-tracking-on-a-custom-dataset-19f84cfdacbf) — BotSORT tracking pipeline, coordinate normalization pattern
- [Flutter CustomPainter Animation — Codemagic Blog](https://blog.codemagic.io/flutter-custom-painter/) — `withOpacity`, `canvas.drawCircle`, `canvas.drawLine`, `repaint` parameter
- [Tennis Ball Tracker — GitHub](https://github.com/nikhilgrad/Tennis-Ball-Tracker) — YOLO detection + position interpolation for missed frames

---

*Feature research for: Ball tracking + visual trail overlay (Flutter mobile ML, v1.1 milestone)*
*Researched: 2026-02-23*
