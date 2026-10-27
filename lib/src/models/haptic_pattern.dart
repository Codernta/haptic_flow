import 'package:flutter/foundation.dart';
import 'haptic_step.dart';

/// A token that can be passed to [HapticFlow] or [HapticFlowController]
/// to cancel asynchronous playback of a haptic sequence midway.
class CancellationToken {
  bool _isCancelled = false;
  final List<VoidCallback> _listeners = [];

  /// Whether cancellation has been requested.
  bool get isCancelled => _isCancelled;

  /// Requests cancellation of any active playback bound to this token.
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (int i = 0; i < _listeners.length; i++) {
      try {
        _listeners[i]();
      } catch (e, st) {
        debugPrint('Error in CancellationToken listener: $e\n$st');
      }
    }
    _listeners.clear();
  }

  /// Registers a callback to be invoked immediately upon cancellation.
  /// If the token is already cancelled, the callback is invoked synchronously.
  ///
  /// Returns a [VoidCallback] that unregisters the callback when invoked.
  VoidCallback onCancel(VoidCallback callback) {
    if (_isCancelled) {
      callback();
      return () {};
    }
    _listeners.add(callback);
    return () => _listeners.remove(callback);
  }

  /// Throws a [HapticCancelledException] if this token has been cancelled.
  void throwIfCancelled() {
    if (_isCancelled) {
      throw const HapticCancelledException();
    }
  }
}

/// Exception thrown when a sequence playback is aborted via a [CancellationToken].
class HapticCancelledException implements Exception {
  /// Creates a [HapticCancelledException].
  const HapticCancelledException(
      [this.message = 'Haptic playback was cancelled']);

  /// The error message.
  final String message;

  @override
  String toString() => 'HapticCancelledException: $message';
}

/// The execution state of a haptic playback engine.
enum HapticPlaybackStatus {
  /// The engine is idle and not executing any sequence.
  idle,

  /// A sequence is actively playing.
  playing,

  /// Playback is temporarily suspended and can be resumed.
  paused,

  /// The sequence completed normally.
  completed,

  /// Playback was stopped or cancelled before completion.
  cancelled,
}

/// Represents an event emitted during haptic sequence playback.
@immutable
class HapticPlaybackEvent {
  /// Creates a [HapticPlaybackEvent].
  const HapticPlaybackEvent({
    required this.status,
    required this.currentStepIndex,
    required this.totalSteps,
    this.currentStep,
    this.loopIteration = 0,
    this.totalLoops = 1,
  });

  /// The current state of playback.
  final HapticPlaybackStatus status;

  /// The zero-based index of the currently active step.
  final int currentStepIndex;

  /// The total number of steps in the sequence.
  final int totalSteps;

  /// The active [HapticStep] being executed, if any.
  final HapticStep? currentStep;

  /// The current iteration index (0-based) for looping sequences.
  final int loopIteration;

  /// The target number of loops (or 0 for infinite).
  final int totalLoops;

  /// The playback completion progress within the current sequence (0.0 to 1.0).
  double get progress {
    if (totalSteps <= 0) return 0.0;
    return ((currentStepIndex + 1) / totalSteps).clamp(0.0, 1.0);
  }

  @override
  String toString() =>
      'HapticPlaybackEvent(status: $status, step: $currentStepIndex/$totalSteps, '
      'loop: $loopIteration/$totalLoops, progress: ${(progress * 100).toStringAsFixed(1)}%)';
}
