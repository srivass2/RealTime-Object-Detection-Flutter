import 'dart:collection' show ListQueue;

import 'package:flutter/painting.dart' show Offset;

import 'package:tensorflow_demo/models/tracked_position.dart';

/// Manages the ball position history for trail rendering.
///
/// Positions are stored in a time-windowed [ListQueue]. Entries older than
/// [trailWindow] are automatically evicted on every [update] or [markOccluded]
/// call. The default window is 1.5 seconds (TRAK-01).
///
/// When the ball is lost, [markOccluded] inserts a single occlusion sentinel
/// at the last known position. Consecutive lost frames do NOT stack additional
/// sentinels (TRAK-02). After [autoResetThreshold] consecutive missed frames
/// the entire trail is cleared via [reset] (TRAK-05).
///
/// This is a plain Dart class — no Flutter widget dependencies — so it is
/// safe to unit-test in isolation.
class BallTracker {
  /// Duration of the sliding time window. Entries older than this are pruned.
  /// Defaults to 1.5 seconds per TRAK-01.
  final Duration trailWindow;

  /// Number of consecutive missed frames that triggers an automatic [reset].
  /// Resets [_consecutiveMissedFrames] to zero and clears [_history].
  static const int autoResetThreshold = 30;

  final _history = ListQueue<TrackedPosition>();

  /// Counts consecutive frames where no ball was detected.
  /// Reset to 0 in [update] (ball found) and [reset] (manual/auto clear).
  /// Incremented in [markOccluded] (ball missing).
  /// Never modified inside [_prune] — see research Pitfall 3.
  int _consecutiveMissedFrames = 0;

  BallTracker({
    this.trailWindow = const Duration(seconds: 1, milliseconds: 500),
  });

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Unmodifiable snapshot of the current trail history.
  ///
  /// Painters must not mutate the queue directly. Iterate this list and break
  /// the polyline wherever [TrackedPosition.isOccluded] is true.
  List<TrackedPosition> get trail => List.unmodifiable(_history);

  /// Returns the [normalizedCenter] of the most recent non-occluded entry,
  /// or null if no such entry exists.
  ///
  /// Used by the screen as a tiebreaker when multiple YOLO detections arrive
  /// in the same frame (TRAK-04 nearest-neighbour logic).
  Offset? get lastKnownPosition {
    for (final entry in _history.toList().reversed) {
      if (!entry.isOccluded) return entry.normalizedCenter;
    }
    return null;
  }

  /// Called when a ball IS detected in the current frame.
  ///
  /// Resets the consecutive-miss counter, appends the new position, then
  /// prunes expired entries.
  void update(Offset normalizedCenter) {
    _consecutiveMissedFrames = 0;
    _history.addLast(
      TrackedPosition(
        normalizedCenter: normalizedCenter,
        timestamp: DateTime.now(),
      ),
    );
    _prune();
  }

  /// Called when NO ball is detected in the current frame.
  ///
  /// Increments the miss counter. If the counter reaches [autoResetThreshold]
  /// the trail is cleared entirely (TRAK-05). Otherwise, a single occlusion
  /// sentinel is inserted at the last known position to mark the gap — but
  /// only if the most recent entry is not already a sentinel (TRAK-02).
  void markOccluded() {
    _consecutiveMissedFrames++;

    if (_consecutiveMissedFrames >= autoResetThreshold) {
      reset();
      return;
    }

    if (_history.isNotEmpty && !_history.last.isOccluded) {
      _history.addLast(
        TrackedPosition(
          normalizedCenter: _history.last.normalizedCenter,
          timestamp: DateTime.now(),
          isOccluded: true,
        ),
      );
      _prune();
    }
  }

  /// Clears all history and resets the consecutive-miss counter.
  ///
  /// Called automatically when [_consecutiveMissedFrames] reaches
  /// [autoResetThreshold], or can be called manually (e.g. on screen dispose).
  void reset() {
    _history.clear();
    _consecutiveMissedFrames = 0;
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  /// Removes entries from the front of the queue whose [timestamp] falls
  /// before the current time minus [trailWindow].
  ///
  /// CRITICAL: This method must NOT touch [_consecutiveMissedFrames].
  /// That counter tracks frame-level continuity and is only reset in [update]
  /// and [reset] — resetting it here would mask accumulated miss counts
  /// (see research Pitfall 3).
  void _prune() {
    final cutoff = DateTime.now().subtract(trailWindow);
    while (_history.isNotEmpty &&
        _history.first.timestamp.isBefore(cutoff)) {
      _history.removeFirst();
    }
  }
}
