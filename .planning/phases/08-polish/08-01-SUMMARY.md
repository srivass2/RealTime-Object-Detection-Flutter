---
phase: 08-polish
plan: 01
subsystem: ui
tags: [flutter, dart, ball-tracking, overlay, yolo, mobile]

# Dependency graph
requires:
  - phase: 07-trail-accumulation-and-rendering
    provides: BallTracker service with _consecutiveMissedFrames counter and trail overlay Stack structure
provides:
  - BallTracker.isBallLost public boolean getter backed by ballLostThreshold = 3
  - Conditional "Ball lost" red badge at top-right of YOLO live detection screen (PLSH-01)
affects: [evaluation, device-verification, polish]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "IgnorePointer wraps UI overlay badges to preserve YOLOView touch handling"
    - "Badge visibility driven by direct getter read in build() — no timers, streams, or MobX"
    - "Threshold constant defined on service (BallTracker) not in widget — single source of truth"

key-files:
  created: []
  modified:
    - lib/services/ball_tracker.dart
    - lib/screens/live_object_detection/live_object_detection_screen.dart

key-decisions:
  - "ballLostThreshold = 3 frames (3 < autoResetThreshold 30; 3 frames ≈ 100ms at 30fps satisfies PLSH-01)"
  - "isBallLost returns boolean only — screen does not need to know the raw miss count"
  - "Badge piggybacks on existing onResult setState — no separate animation loop or state variable needed"
  - "IgnorePointer wraps badge (consistent with trail overlay pattern from Phase 7)"

patterns-established:
  - "PLSH-01 badge pattern: threshold constant on tracker, boolean getter, conditional Stack child wrapped in IgnorePointer"

requirements-completed: [PLSH-01]

# Metrics
duration: ~6min
completed: 2026-02-24
---

# Phase 8 Plan 01: Ball Lost Badge Summary

**Red "Ball lost" badge on YOLO live screen driven by BallTracker.isBallLost getter with 3-frame threshold (~100ms at 30fps), wrapped in IgnorePointer at top-right, not overlapping backend label at top-left**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-02-24T17:57:02Z
- **Completed:** 2026-02-24T17:58:29Z
- **Tasks:** 2 code tasks complete; 1 device-verification checkpoint pending
- **Files modified:** 2

## Accomplishments
- Added `static const int ballLostThreshold = 3` and `bool get isBallLost` to `BallTracker` — satisfies PLSH-01 "within a few frames" requirement (3 frames ≈ 100ms at 30fps)
- Added conditional "Ball lost" badge to YOLO Stack in `LiveObjectDetectionScreen`: red `Container` at `top: 12, right: 12`, wrapped in `IgnorePointer`, visible when `_tracker.isBallLost` is true
- Badge disappears immediately on re-detection (next `onResult` `setState` rebuild reads `isBallLost` as false)
- Zero regressions: `flutter analyze` passes with 0 issues; all architectural constraints maintained

## Task Commits

Each task was committed atomically:

1. **Task 1: Add isBallLost getter and ballLostThreshold to BallTracker** - `8d061c5` (feat)
2. **Task 2: Add conditional Ball lost badge to YOLO live detection screen** - `b6a68fb` (feat)

## Files Created/Modified
- `lib/services/ball_tracker.dart` - Added `ballLostThreshold = 3` constant and `isBallLost` boolean getter
- `lib/screens/live_object_detection/live_object_detection_screen.dart` - Added conditional "Ball lost" badge as YOLO Stack child, wrapped in IgnorePointer at top-right position

## Decisions Made
- `ballLostThreshold = 3` satisfies PLSH-01 "within a few frames" and maps to ~100ms at 30fps; well below `autoResetThreshold = 30`
- Expose only a boolean getter (`isBallLost`) from `BallTracker` — the screen never needs the raw miss count
- Badge piggybacks on existing `onResult` `setState` rebuild cycle — no Timer, Stream, animation controller, or MobX needed
- `IgnorePointer` wraps the entire badge (consistent with trail overlay pattern from Phase 7, preserves YOLOView touch handling)
- `Colors.red.withValues(alpha: 0.85)` — uses non-deprecated API (same as trail overlay code)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Code changes complete and `flutter analyze` clean
- Device verification checkpoint (Task 3) is pending — user must run on iPhone 12 in YOLO mode and confirm badge behavior
- After device verification: Phase 8 (Polish) will be complete; full v1.1 ball tracking milestone finished
- Remaining open items from prior phases: Galaxy A32 testing (blocked on Android SDK), Unsplash API key, iOS camera usage description

---
*Phase: 08-polish*
*Completed: 2026-02-24*
