import 'dart:async';
import 'package:flutter/foundation.dart';
import '../drivers/haptic_driver.dart';
import '../models/haptic_pattern.dart';
import '../models/haptic_sequence.dart';
import '../models/haptic_step.dart';

/// The core execution engine for haptic sequences and tactile choreography.
///
/// [HapticFlowController] manages timeline scheduling, cancellation tokens,
/// pause/resume states, and dispatches tactile pulses to the underlying [HapticDriver].
///
/// It extends [ChangeNotifier] for easy integration with Flutter UI widgets and
/// also provides a reactive [events] stream.
class HapticFlowController extends ChangeNotifier {
  /// Creates a [HapticFlowController].
  ///
  /// If [driver] is omitted, a [SystemHapticDriver] will be used.
  HapticFlowController({HapticDriver? driver})
      : _driver = driver ?? const SystemHapticDriver();

  HapticDriver _driver;

  /// The active tactile hardware driver.
  HapticDriver get driver => _driver;

  /// Updates the active [HapticDriver] (e.g. for swapping in [MockHapticDriver] in tests).
  set driver(HapticDriver newDriver) {
    _driver = newDriver;
    notifyListeners();
  }

  /// Whether haptic playback is enabled on this controller.
  bool enabled = true;

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
    final event = HapticPlaybackEvent(
      status: _status,
      currentStepIndex: _currentStepIndex,
      totalSteps: _currentSequence?.length ?? 0,
      currentStep: _currentStep,
      loopIteration: _currentLoopIteration,
      totalLoops: _currentSequence?.loopCount ?? 1,
    );
    _eventController.add(event);
    notifyListeners();
  }

  /// Plays a single [HapticStep] immediately.
  Future<void> playStep(HapticStep step) async {
    if (!enabled) return;
    if (step.isTactile) {
      await _driver.trigger(step.type);
    } else if (step.type == HapticStepType.custom && step.customAction != null) {
      await step.customAction!();
    }
  }

  /// Plays a [HapticSequence] from start to finish.
  ///
  /// If another sequence is already playing on this controller, it is cancelled
  /// and replaced.
  ///
  /// Provide an optional [cancelToken] to allow external abortion of playback.
  Future<void> play(
    HapticSequence sequence, {
    CancellationToken? cancelToken,
  }) async {
    // Stop any existing sequence before starting a new one
    stop();

    if (!enabled || sequence.isEmpty) {
      _status = HapticPlaybackStatus.completed;
      _emitEvent();
      _status = HapticPlaybackStatus.idle;
      _emitEvent();
      return;
    }

    final localToken = CancellationToken();
    _activeCancellationToken = localToken;

    void onCancelRequested() {
      _cancelActiveSleep();
      if (_pauseCompleter != null && !_pauseCompleter!.isCompleted) {
        _pauseCompleter!.complete();
      }
    }

    cancelToken?.onCancel(onCancelRequested);
    localToken.onCancel(onCancelRequested);

    _currentSequence = sequence;
    _currentStepIndex = -1;
    _currentLoopIteration = 0;
    _status = HapticPlaybackStatus.playing;
    _emitEvent();

    final isInfinite = sequence.isInfinite;
    final targetLoops = sequence.loopCount;

    try {
      while (isInfinite || _currentLoopIteration < targetLoops) {
        for (var i = 0; i < sequence.length; i++) {
          if (localToken.isCancelled || (cancelToken?.isCancelled ?? false)) {
            _status = HapticPlaybackStatus.cancelled;
            _emitEvent();
            return;
          }

          // Handle paused state
          if (_status == HapticPlaybackStatus.paused && _pauseCompleter != null) {
            await _pauseCompleter!.future;
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

          // Execute step feedback
          if (step.isTactile) {
            await _driver.trigger(step.type);
          } else if (step.type == HapticStepType.custom && step.customAction != null) {
            await step.customAction!();
          }

          // Await step duration
          if (step.duration > Duration.zero) {
            await _interruptibleDelay(step.duration, localToken, cancelToken);
          }
        }

        _currentLoopIteration++;
      }

      _status = HapticPlaybackStatus.completed;
      _emitEvent();
    } catch (e, st) {
      if (e is! HapticCancelledException) {
        debugPrint('HapticFlowController playback error: $e\n$st');
      }
      _status = HapticPlaybackStatus.cancelled;
      _emitEvent();
    } finally {
      if (_activeCancellationToken == localToken) {
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
    if (_status != HapticPlaybackStatus.playing) return;
    _status = HapticPlaybackStatus.paused;
    _pauseCompleter = Completer<void>();
    _cancelActiveSleep();
    _emitEvent();
  }

  /// Resumes playback if currently paused.
  void resume() {
    if (_status != HapticPlaybackStatus.paused) return;
    _status = HapticPlaybackStatus.playing;
    if (_pauseCompleter != null && !_pauseCompleter!.isCompleted) {
      _pauseCompleter!.complete();
    }
    _pauseCompleter = null;
    _emitEvent();
  }

  /// Cancels and terminates any active playback.
  void stop() {
    if (_activeCancellationToken != null && !_activeCancellationToken!.isCancelled) {
      _activeCancellationToken!.cancel();
    }
    _cancelActiveSleep();
    if (_pauseCompleter != null && !_pauseCompleter!.isCompleted) {
      _pauseCompleter!.complete();
    }
    _pauseCompleter = null;
    _currentStep = null;
    _currentStepIndex = -1;
    if (_status != HapticPlaybackStatus.idle) {
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
    if (token1.isCancelled || (token2?.isCancelled ?? false)) {
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
    stop();
    _eventController.close();
    super.dispose();
  }
}

/// A global, convenient static facade for [HapticFlowController].
///
/// Provides quick one-line calls to play sequences, presets, or individual
/// tactile pulses without managing controller lifecycles.
///
/// Example:
/// ```dart
/// // Play a single pulse
/// await HapticFlow.light();
///
/// // Play a choreography preset
/// await HapticFlow.play(HapticPresets.heartbeat);
///
/// // Compose on the fly
/// await HapticFlow.play(
///   HapticSequence.builder()
///     .light()
///     .pause(Duration(milliseconds: 100))
///     .heavy()
///     .build()
/// );
/// ```
class HapticFlow {
  HapticFlow._();

  static HapticFlowController? _defaultController;

  /// The shared default [HapticFlowController] instance.
  static HapticFlowController get defaultController =>
      _defaultController ??= HapticFlowController();

  /// Gets the global [HapticDriver].
  static HapticDriver get driver => defaultController.driver;

  /// Replaces the global [HapticDriver] (e.g. for testing).
  static set driver(HapticDriver driver) =>
      defaultController.driver = driver;

  /// Global master toggle for all haptics played via [HapticFlow].
  ///
  /// Useful for respecting accessibility preferences or silent mode settings.
  static bool get enabled => defaultController.enabled;
  static set enabled(bool value) => defaultController.enabled = value;

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
  static Future<void> light() => defaultController.playStep(const HapticStep.light());

  /// Plays a medium impact feedback pulse.
  static Future<void> medium() => defaultController.playStep(const HapticStep.medium());

  /// Plays a heavy impact feedback pulse.
  static Future<void> heavy() => defaultController.playStep(const HapticStep.heavy());

  /// Plays a selection click feedback pulse.
  static Future<void> selection() => defaultController.playStep(const HapticStep.selection());

  /// Plays a selection click feedback pulse (alias).
  static Future<void> click() => selection();

  /// Plays a standard device vibration pulse.
  static Future<void> vibrate() => defaultController.playStep(const HapticStep.vibrate());
}
