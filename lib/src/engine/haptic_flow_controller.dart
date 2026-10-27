import 'dart:async';
import 'package:flutter/foundation.dart';
import '../drivers/haptic_driver.dart';
import '../models/haptic_pattern.dart';
import '../models/haptic_sequence.dart';
import '../models/haptic_step.dart';
import '../security/haptic_safety_policy.dart';

/// The core execution engine for haptic sequences and tactile choreography.
///
/// [HapticFlowController] manages timeline scheduling, cancellation tokens,
/// pause/resume states, concurrency isolation, and dispatches tactile pulses
/// to the underlying [HapticDriver].
///
/// It extends [ChangeNotifier] for easy integration with Flutter UI widgets and
/// also provides a reactive [events] stream.
class HapticFlowController extends ChangeNotifier {
  /// Creates a [HapticFlowController].
  ///
  /// If [driver] is omitted, a [SystemHapticDriver] will be used.
  /// If [safetyPolicy] is omitted, [HapticSafetyPolicy.standard] is enforced.
  HapticFlowController({
    HapticDriver? driver,
    HapticSafetyPolicy? safetyPolicy,
  })  : _driver = driver ?? const SystemHapticDriver(),
        _safetyGuard = HapticSafetyGuard(
          policy: safetyPolicy ?? HapticSafetyPolicy.standard,
        );

  HapticDriver _driver;
  HapticSafetyGuard _safetyGuard;

  /// The active tactile hardware driver.
  HapticDriver get driver => _driver;

  /// Updates the active [HapticDriver] (e.g. for swapping in [MockHapticDriver] in tests).
  set driver(HapticDriver newDriver) {
    if (_isDisposed) return;
    _driver = newDriver;
    notifyListeners();
  }

  /// The active safety policy enforcing rate-limiting, thermal protection, and anti-burnout guards.
  HapticSafetyPolicy get safetyPolicy => _safetyGuard.policy;

  /// Updates the safety policy.
  set safetyPolicy(HapticSafetyPolicy policy) {
    _safetyGuard = HapticSafetyGuard(policy: policy);
  }

  /// Privacy mode enforced on this controller.
  HapticPrivacyMode get privacyMode => _safetyGuard.policy.privacyMode;

  /// Updates the privacy mode.
  set privacyMode(HapticPrivacyMode mode) {
    _safetyGuard.policy = _safetyGuard.policy.copyWith(privacyMode: mode);
  }

  /// Resets internal safety rate-limiting and duty-cycle counters.
  void resetSafetyCounters() => _safetyGuard.reset();

  /// Whether haptic playback is enabled on this controller.
  bool enabled = true;

  bool _isDisposed = false;

  /// Whether this controller has been disposed.
  bool get isDisposed => _isDisposed;

  int _sessionCounter = 0;
  HapticPlaybackStatus _status = HapticPlaybackStatus.idle;
  HapticSequence? _currentSequence;
  HapticStep? _currentStep;
  int _currentStepIndex = -1;
  int _currentLoopIteration = 0;
  CancellationToken? _activeCancellationToken;
  Completer<void>? _pauseCompleter;
  Completer<void>? _activeSleepCompleter;

  final StreamController<HapticPlaybackEvent> _eventController =
      StreamController<HapticPlaybackEvent>.broadcast();

  /// Reactive stream of playback state changes.
  Stream<HapticPlaybackEvent> get events => _eventController.stream;

  /// The current execution status.
  HapticPlaybackStatus get status => _status;

  /// Whether a sequence is actively playing.
  bool get isPlaying => _status == HapticPlaybackStatus.playing;

  /// Whether playback is currently paused.
  bool get isPaused => _status == HapticPlaybackStatus.paused;

  /// Whether the controller is idle (not playing or paused).
  bool get isIdle => _status == HapticPlaybackStatus.idle;

  /// The sequence currently loaded or playing.
  HapticSequence? get currentSequence => _currentSequence;

  /// The step currently being executed.
  HapticStep? get currentStep => _currentStep;

  /// The zero-based index of the currently active step.
  int get currentStepIndex => _currentStepIndex;

  /// The current loop count iteration (0-based).
  int get currentLoopIteration => _currentLoopIteration;

  /// Playback progress of the current sequence (0.0 to 1.0).
  double get progress {
    final seq = _currentSequence;
    if (seq == null || seq.isEmpty || _currentStepIndex < 0) return 0.0;
    return ((_currentStepIndex + 1) / seq.length).clamp(0.0, 1.0);
  }

  /// Whether the host platform supports physical haptic feedback.
  bool get isPlatformSupported => _driver.isSupported;

  void _emitEvent() {
    if (_isDisposed) return;
    final hasStreamListener =
        !_eventController.isClosed && _eventController.hasListener;
    if (!hasListeners && !hasStreamListener) {
      return; // Skip allocating HapticPlaybackEvent when unobserved
    }
    final event = HapticPlaybackEvent(
      status: _status,
      currentStepIndex: _currentStepIndex,
      totalSteps: _currentSequence?.length ?? 0,
      currentStep: _currentStep,
      loopIteration: _currentLoopIteration,
      totalLoops: _currentSequence?.loopCount ?? 1,
    );
    if (hasStreamListener) {
      _eventController.add(event);
    }
    if (hasListeners) {
      notifyListeners();
    }
  }

  /// Plays a single [HapticStep] immediately with strict error boundary and safety protection.
  Future<void> playStep(HapticStep step) async {
    if (_isDisposed || !enabled) return;
    if (step.isTactile) {
      if (_safetyGuard.canTriggerTactile(stepDuration: step.duration)) {
        await _driver.trigger(step.type);
      }
    } else if (step.type == HapticStepType.custom &&
        step.customAction != null) {
      try {
        await Future.sync(step.customAction!)
            .timeout(_safetyGuard.policy.customActionTimeout);
      } catch (e, st) {
        debugPrint(
            'HapticFlowController: Custom action error suppressed: $e\n$st');
      }
    }
  }

  /// Plays a [HapticSequence] from start to finish with strict concurrency isolation.
  ///
  /// If another sequence is already playing on this controller, it is cancelled
  /// and replaced safely.
  ///
  /// Provide an optional [cancelToken] to allow external abortion of playback.
  Future<void> play(
    HapticSequence sequence, {
    CancellationToken? cancelToken,
  }) async {
    if (_isDisposed) return;

    // Stop any existing sequence before starting a new one
    stop();

    if (!enabled || sequence.isEmpty) {
      _status = HapticPlaybackStatus.completed;
      _emitEvent();
      _status = HapticPlaybackStatus.idle;
      _emitEvent();
      return;
    }

    final sessionId = ++_sessionCounter;
    final localToken = CancellationToken();
    _activeCancellationToken = localToken;

    void onCancelRequested() {
      _cancelActiveSleep();
      if (_pauseCompleter != null && !_pauseCompleter!.isCompleted) {
        _pauseCompleter!.complete();
      }
    }

    final unhookExternal = cancelToken?.onCancel(onCancelRequested);
    final unhookLocal = localToken.onCancel(onCancelRequested);

    _currentSequence = sequence;
    _currentStepIndex = -1;
    _currentLoopIteration = 0;
    _status = HapticPlaybackStatus.playing;
    _emitEvent();

    final isInfinite = sequence.isInfinite;
    final targetLoops = sequence.loopCount;

    try {
      while (isInfinite || _currentLoopIteration < targetLoops) {
        // Starvation defense: if sequence has 0 total duration, enforce cooperative yield
        if (_safetyGuard.policy.preventEventLoopStarvation &&
            sequence.totalDuration == Duration.zero) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (_isDisposed || _sessionCounter != sessionId) return;
        }

        for (var i = 0; i < sequence.length; i++) {
          if (_isDisposed || _sessionCounter != sessionId) return;

          if (localToken.isCancelled || (cancelToken?.isCancelled ?? false)) {
            _status = HapticPlaybackStatus.cancelled;
            _emitEvent();
            return;
          }

          // Handle paused state
          if (_status == HapticPlaybackStatus.paused &&
              _pauseCompleter != null) {
            await _pauseCompleter!.future;
            if (_isDisposed || _sessionCounter != sessionId) return;
            if (localToken.isCancelled || (cancelToken?.isCancelled ?? false)) {
              _status = HapticPlaybackStatus.cancelled;
              _emitEvent();
              return;
            }
          }

          final rawStep = sequence[i];
          final step = rawStep.scaled(
            intensityScale: sequence.intensityScale,
            speedScale: sequence.speedScale,
          );

          _currentStep = step;
          _currentStepIndex = i;
          _emitEvent();

          // Execute step feedback with safety watchdog check
          if (step.isTactile) {
            if (_safetyGuard.canTriggerTactile(stepDuration: step.duration)) {
              await _driver.trigger(step.type);
            }
          } else if (step.type == HapticStepType.custom &&
              step.customAction != null) {
            try {
              await Future.sync(step.customAction!)
                  .timeout(_safetyGuard.policy.customActionTimeout);
            } catch (e, st) {
              debugPrint(
                  'HapticFlowController: Custom action error suppressed: $e\n$st');
            }
          }

          // Await step duration (with privacy jitter if enabled)
          if (step.duration > Duration.zero) {
            var stepDelay = step.duration;
            if (_safetyGuard.policy.privacyMode == HapticPrivacyMode.mask) {
              final jitterMicros = _safetyGuard.getPrivacyJitterMicros();
              final safeMicros = (stepDelay.inMicroseconds + jitterMicros)
                  .clamp(1000, HapticStep.maxStepDuration.inMicroseconds);
              stepDelay = Duration(microseconds: safeMicros);
            }
            await _interruptibleDelay(stepDelay, localToken, cancelToken);
          } else if (_safetyGuard.policy.preventEventLoopStarvation &&
              i > 0 &&
              i % 50 == 0) {
            // Cooperative yield for long bursts of zero-duration steps
            await Future<void>.delayed(Duration.zero);
          }
        }

        _currentLoopIteration++;
      }

      if (_sessionCounter == sessionId && !_isDisposed) {
        _status = HapticPlaybackStatus.completed;
        _emitEvent();
      }
    } catch (e, st) {
      if (e is! HapticCancelledException) {
        debugPrint('HapticFlowController playback error: $e\n$st');
      }
      if (_sessionCounter == sessionId && !_isDisposed) {
        _status = HapticPlaybackStatus.cancelled;
        _emitEvent();
      }
    } finally {
      unhookExternal?.call();
      unhookLocal();
      if (_sessionCounter == sessionId && !_isDisposed) {
        _activeCancellationToken = null;
        _currentStep = null;
        _currentStepIndex = -1;
        _status = HapticPlaybackStatus.idle;
        _emitEvent();
      }
    }
  }

  /// Pauses the active sequence playback.
  void pause() {
    if (_isDisposed || _status != HapticPlaybackStatus.playing) return;
    _status = HapticPlaybackStatus.paused;
    _pauseCompleter = Completer<void>();
    _cancelActiveSleep();
    _emitEvent();
  }

  /// Resumes playback if currently paused.
  void resume() {
    if (_isDisposed || _status != HapticPlaybackStatus.paused) return;
    _status = HapticPlaybackStatus.playing;
    if (_pauseCompleter != null && !_pauseCompleter!.isCompleted) {
      _pauseCompleter!.complete();
    }
    _pauseCompleter = null;
    _emitEvent();
  }

  /// Cancels and terminates any active playback.
  void stop() {
    if (_activeCancellationToken != null &&
        !_activeCancellationToken!.isCancelled) {
      _activeCancellationToken!.cancel();
    }
    _cancelActiveSleep();
    if (_pauseCompleter != null && !_pauseCompleter!.isCompleted) {
      _pauseCompleter!.complete();
    }
    _pauseCompleter = null;
    _currentStep = null;
    _currentStepIndex = -1;
    if (_status != HapticPlaybackStatus.idle && !_isDisposed) {
      _status = HapticPlaybackStatus.cancelled;
      _emitEvent();
      _status = HapticPlaybackStatus.idle;
      _emitEvent();
    }
  }

  /// Alias for [stop].
  void cancel() => stop();

  void _cancelActiveSleep() {
    if (_activeSleepCompleter != null && !_activeSleepCompleter!.isCompleted) {
      _activeSleepCompleter!.complete();
    }
    _activeSleepCompleter = null;
  }

  Future<void> _interruptibleDelay(
    Duration duration,
    CancellationToken token1,
    CancellationToken? token2,
  ) {
    if (token1.isCancelled || (token2?.isCancelled ?? false) || _isDisposed) {
      return Future.value();
    }

    final completer = Completer<void>();
    _activeSleepCompleter = completer;

    Timer? timer;
    void cancelTimer() {
      if (timer?.isActive ?? false) timer!.cancel();
      if (!completer.isCompleted) completer.complete();
    }

    token1.onCancel(cancelTimer);
    token2?.onCancel(cancelTimer);

    timer = Timer(duration, () {
      if (!completer.isCompleted) completer.complete();
    });

    return completer.future;
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    stop();
    _eventController.close();
    super.dispose();
  }
}

/// A global, convenient static facade for [HapticFlowController].
///
/// Provides quick one-line calls to play sequences, presets, or individual
/// tactile pulses without managing controller lifecycles.
class HapticFlow {
  HapticFlow._();

  static HapticFlowController? _defaultController;

  /// The shared default [HapticFlowController] instance.
  static HapticFlowController get defaultController =>
      _defaultController ??= HapticFlowController();

  /// Gets the global [HapticDriver].
  static HapticDriver get driver => defaultController.driver;

  /// Replaces the global [HapticDriver] (e.g. for testing).
  static set driver(HapticDriver driver) => defaultController.driver = driver;

  /// Global master toggle for all haptics played via [HapticFlow].
  ///
  /// Useful for respecting accessibility preferences or silent mode settings.
  static bool get enabled => defaultController.enabled;
  static set enabled(bool value) => defaultController.enabled = value;

  /// Global safety policy enforced by the default controller.
  static HapticSafetyPolicy get safetyPolicy => defaultController.safetyPolicy;
  static set safetyPolicy(HapticSafetyPolicy policy) =>
      defaultController.safetyPolicy = policy;

  /// Global privacy mode enforced by the default controller (e.g. for masking sensitive inputs).
  static HapticPrivacyMode get privacyMode => defaultController.privacyMode;
  static set privacyMode(HapticPrivacyMode mode) =>
      defaultController.privacyMode = mode;

  /// Resets safety rate-limiting counters on the default controller.
  static void resetSafetyCounters() => defaultController.resetSafetyCounters();

  /// Checks if the host platform supports physical haptic feedback.
  static bool get isPlatformSupported => defaultController.isPlatformSupported;

  /// Plays a [HapticSequence] or [HapticStep].
  static Future<void> play(
    dynamic sequenceOrStep, {
    CancellationToken? cancelToken,
  }) async {
    if (sequenceOrStep is HapticSequence) {
      await defaultController.play(sequenceOrStep, cancelToken: cancelToken);
    } else if (sequenceOrStep is HapticStep) {
      await defaultController.playStep(sequenceOrStep);
    } else {
      throw ArgumentError(
        'Expected HapticSequence or HapticStep, got ${sequenceOrStep.runtimeType}',
      );
    }
  }

  /// Plays a single [HapticStep].
  static Future<void> playStep(HapticStep step) =>
      defaultController.playStep(step);

  /// Pauses current playback on the default controller.
  static void pause() => defaultController.pause();

  /// Resumes paused playback on the default controller.
  static void resume() => defaultController.resume();

  /// Stops any active playback on the default controller.
  static void stop() => defaultController.stop();

  /// Plays a light impact feedback pulse.
  static Future<void> light() =>
      defaultController.playStep(const HapticStep.light());

  /// Plays a medium impact feedback pulse.
  static Future<void> medium() =>
      defaultController.playStep(const HapticStep.medium());

  /// Plays a heavy impact feedback pulse.
  static Future<void> heavy() =>
      defaultController.playStep(const HapticStep.heavy());

  /// Plays a selection click feedback pulse.
  static Future<void> selection() =>
      defaultController.playStep(const HapticStep.selection());

  /// Plays a selection click feedback pulse (alias).
  static Future<void> click() => selection();

  /// Plays a standard device vibration pulse.
  static Future<void> vibrate() =>
      defaultController.playStep(const HapticStep.vibrate());
}
