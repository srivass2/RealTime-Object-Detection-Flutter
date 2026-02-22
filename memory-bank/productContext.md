# Product Context

## The Product: Flare Football
Flare Football is a sports technology product. This object detection POC is being built to evaluate a capability that could be integrated into the broader Flare Football platform — specifically, the ability to detect soccer-relevant objects (balls) in real time from a user's device camera.

## Why This POC Exists
The Flare Football team wants to know if on-device AI detection is viable before committing engineering resources to building it into the main product. This app is the "try before you build" step. It uses a real custom-trained model (not a toy demo model) to get a truthful signal about accuracy and performance.

## The Problem Being Solved
Soccer/football analysis currently requires either manual tagging or expensive server-side video processing. If on-device detection works well enough, Flare Football could enable features like:
- Real-time ball tracking during matches or training
- Automated highlight detection ("ball touched", "shot taken")
- Player/ball position analytics captured passively on a phone
- Lightweight, offline-capable detection that doesn't require cloud round-trips

## Who Uses This POC
This is an **internal engineering/product feasibility tool**. The "users" are the Flare Football team members evaluating the technology — developers, product managers, and potentially investors or stakeholders reviewing a demo. It is not intended for end consumers of the Flare Football product.

## Detection Classes
The custom YOLO11n model detects **3 classes**, embedded directly in the model:
| Class | Notes |
|---|---|
| `Soccer ball` | Primary target — the main object of interest |
| `ball` | General ball detection — likely also fires on soccer balls depending on context |
| `tennis-ball` | Present from training data; likely incidental but may fire in certain conditions |

The model was trained on a **custom soccer-focused dataset**, distinct from general COCO-class datasets.

## User Experience Goals (for the POC)
The app needs to demonstrate:
1. **Real-time detection** — bounding boxes appearing live on camera with minimal lag
2. **Accuracy** — detections fire on real soccer balls with low false-positive rate
3. **Stability** — no crashes during a typical 5-10 minute demo session
4. **Both platforms** — evidence that it works on both iOS and Android

## Image Analysis Flow (static photos)
In addition to live camera, the app also supports analyzing:
- Images browsed from the **Unsplash photo grid** (infinite scroll, API-powered)
- Images selected from the **device gallery** via image picker

Static images go through the TFLite/SSD MobileNet pipeline (not YOLO), so they reflect the legacy path rather than the primary evaluation target.

## UI Structure
```
Home Screen
├── Unsplash photo grid (tap any photo → analyze via SSD)
├── Gallery picker button (pick photo → analyze via SSD)
└── Camera FAB → Live Detection Screen
      └── YOLO mode: YOLOView widget (full-screen landscape camera)
      └── TFLite mode: Camera preview + isolate-based detection
```

## Key Product Decisions Already Made
- **YOLO11n was chosen** over larger YOLO variants (11s, 11m, 11l, 11x) deliberately — nano size prioritizes speed and device compatibility over maximum accuracy
- **Landscape-only orientation** was adopted for the YOLO live detection screen — this matches how a phone would realistically be held to film a pitch
- **On-device inference only** — no server calls for detection; fully offline-capable
- **Platform-native model formats** — TFLite for Android, Core ML (mlpackage) for iOS — using the most optimised format per platform rather than one cross-platform format
