# Requirements: Flare Football Object Detection POC

**Defined:** 2026-02-23
**Core Value:** Real-time soccer ball detection and tracking must run on-device with acceptable speed and accuracy on both iOS and Android

## v1.1 Requirements

Requirements for Ball Tracking milestone. Each maps to roadmap phases.

### Overlay Foundation

- [ ] **OVLY-01**: User can see ball center-point extracted from YOLO detection results using normalizedBox coordinates
- [ ] **OVLY-02**: User can see ball center-point extracted from SSD detection results with coordinate normalization via ScreenParams
- [ ] **OVLY-03**: Native YOLOView bounding box overlay is disabled so custom trail overlay is the only rendering layer
- [ ] **OVLY-04**: All detection callbacks guard against setState after dispose with mounted check

### Trail Tracking

- [ ] **TRAK-01**: Ball positions are stored in a bounded queue (max ~45 entries, ~1.5s at 30fps) that automatically evicts oldest entries
- [ ] **TRAK-02**: Occlusion is handled via null sentinels — trail pauses when ball is not detected and resumes on re-detection with a visible gap
- [ ] **TRAK-03**: Class priority filter selects "Soccer ball" over "ball" and rejects "tennis-ball" detections
- [ ] **TRAK-04**: When multiple valid detections exist in the same frame, nearest-to-last-known-position is used as tiebreaker
- [ ] **TRAK-05**: Trail auto-clears after 30+ consecutive frames with no ball detected

### Trail Rendering

- [ ] **RNDR-01**: User can see a fading dot trail with age-based opacity gradient (recent dots are opaque, older dots fade out)
- [ ] **RNDR-02**: Connecting line segments are drawn between consecutive trail positions
- [ ] **RNDR-03**: Line segments skip occlusion gaps — no line is drawn across null sentinels
- [ ] **RNDR-04**: Trail CustomPainter is wrapped in RepaintBoundary for rendering isolation (does not trigger camera layer repaints)
- [ ] **RNDR-05**: Trail overlay renders correctly on YOLO path in landscape orientation
- [ ] **RNDR-06**: Trail overlay renders correctly on SSD path independently from YOLO path

### Polish

- [ ] **PLSH-01**: User can see a "Ball lost" badge overlay when tracking has lost the ball for multiple consecutive frames

## v2+ Requirements

Deferred to future release. Tracked but not in current roadmap.

### Enhancements

- **ENH-01**: Current-frame marker dot (distinct visual for the latest detection position)
- **ENH-02**: EMA smoothing to reduce trail jitter (only if evaluation shows jitter is a problem)
- **ENH-03**: Kalman filter predictive tracking (estimate ball position during occlusion)
- **ENH-04**: Trail color changes based on ball speed
- **ENH-05**: Multi-ball tracking with stable IDs across frames
- **ENH-06**: Configurable trail length via runtime UI control

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Kalman filter predictive tracking | Significant complexity, needs per-device tuning; POC should show raw tracking quality first |
| Multi-ball tracking | Separate research problem; single ball is the target use case |
| Trail color by speed | Requires calibrated pixel-to-world mapping; not needed for feasibility |
| Runtime trail configuration UI | POC does not need end-user tuning; hardcoded values are fine |
| Video recording of trail | Out of scope per original POC constraints |
| Persisting tracking data | POC-only; no storage needed |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| OVLY-01 | Phase 6 | Pending |
| OVLY-02 | Phase 6 | Pending |
| OVLY-03 | Phase 6 | Pending |
| OVLY-04 | Phase 6 | Pending |
| TRAK-01 | Phase 7 | Pending |
| TRAK-02 | Phase 7 | Pending |
| TRAK-03 | Phase 7 | Pending |
| TRAK-04 | Phase 7 | Pending |
| TRAK-05 | Phase 7 | Pending |
| RNDR-01 | Phase 7 | Pending |
| RNDR-02 | Phase 7 | Pending |
| RNDR-03 | Phase 7 | Pending |
| RNDR-04 | Phase 7 | Pending |
| RNDR-05 | Phase 7 | Pending |
| RNDR-06 | Phase 7 | Pending |
| PLSH-01 | Phase 8 | Pending |

**Coverage:**
- v1.1 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-02-23*
*Last updated: 2026-02-23 — traceability filled in after roadmap creation*
