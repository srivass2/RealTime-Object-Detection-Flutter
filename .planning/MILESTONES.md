# Milestones

## v1.0 — Detection Feasibility POC

**Goal:** Evaluate whether YOLO11n can run real-time, on-device soccer ball detection on mobile devices at acceptable speed and accuracy.

**Shipped:**
- YOLO11n real-time detection on Android (TFLite) and iOS (Core ML)
- SSD MobileNet fallback with background Dart isolate inference
- Build-time backend switching via `DETECTOR_BACKEND` env var
- Landscape-only orientation for YOLO detection screen
- Bounding box rendering on SSD MobileNet path (custom `BoxWidget`)
- Three-screen navigation: Home, Live Camera, Photo Analysis
- Evaluation evidence captured (screenshots + recordings, both platforms, multiple scenarios)

**Phases:** 1–5 (informal — predates GSD workflow)

**Outcome:** Detection feasibility confirmed. Both pipelines run on target devices. Architecture is clean and suitable to carry forward.

---
*Archived: 2026-02-23*
