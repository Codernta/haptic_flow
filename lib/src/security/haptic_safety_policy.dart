import 'package:flutter/foundation.dart';

/// Modes for protecting against acoustic and accelerometer-based side-channel eavesdropping.
///
/// Malicious third-party apps with sensor permissions or physical microphones can analyze
/// micro-vibrations and sound waves to infer sensitive user input (e.g. PIN length,
/// password cadence, biometric confirmations).
enum HapticPrivacyMode {
  /// Privacy protection disabled; normal tactile feedback is emitted.
  off,

  /// Injects non-deterministic microsecond timing jitter and amplitude perturbation
  /// to scramble keystroke cadence and PIN length analysis.
  mask,

  /// Completely suppresses tactile feedback in sensitive environments
  /// (e.g., PIN keypads, password fields, OTP inputs).
  mute,
}

/// Safety policy governing tactile feedback to prevent device hardware strain,
/// battery depletion attacks, thermal throttling, and user tactile numbness.
@immutable
class HapticSafetyPolicy {
  /// Creates a [HapticSafetyPolicy].
  const HapticSafetyPolicy({
    this.maxContinuousDuration = const Duration(seconds: 4),
    this.minCoolDownDuration = const Duration(milliseconds: 100),
    this.maxPulsesPerSecond = 30,
    this.maxDutyCycle = 0.75,
    this.customActionTimeout = const Duration(seconds: 3),
    this.preventEventLoopStarvation = true,
    this.privacyMode = HapticPrivacyMode.off,
  });

  /// Standard safety policy recommended for production apps.
  static const HapticSafetyPolicy standard = HapticSafetyPolicy();

  /// Strict safety policy for high-security or accessibility-critical environments.
  static const HapticSafetyPolicy strict = HapticSafetyPolicy(
    maxContinuousDuration: Duration(seconds: 2),
    minCoolDownDuration: Duration(milliseconds: 200),
    maxPulsesPerSecond: 15,
    maxDutyCycle: 0.50,
    customActionTimeout: Duration(seconds: 1),
    preventEventLoopStarvation: true,
    privacyMode: HapticPrivacyMode.mask,
  );

  /// Permissive policy for gaming or intensive physical demonstrations.
  static const HapticSafetyPolicy permissive = HapticSafetyPolicy(
    maxContinuousDuration: Duration(seconds: 10),
    minCoolDownDuration: Duration(milliseconds: 20),
    maxPulsesPerSecond: 60,
    maxDutyCycle: 0.90,
    customActionTimeout: Duration(seconds: 10),
    preventEventLoopStarvation: true,
    privacyMode: HapticPrivacyMode.off,
  );

  /// Disabled safety policy (use only in isolated testing environments).
  static const HapticSafetyPolicy disabled = HapticSafetyPolicy(
    maxContinuousDuration: Duration(days: 365),
    minCoolDownDuration: Duration.zero,
    maxPulsesPerSecond: 1000000,
    maxDutyCycle: 1.0,
    customActionTimeout: Duration(days: 365),
    preventEventLoopStarvation: false,
    privacyMode: HapticPrivacyMode.off,
  );

  /// Maximum continuous tactile vibration duration allowed before enforcing a cooldown.
  final Duration maxContinuousDuration;

  /// Required cooldown resting interval after reaching [maxContinuousDuration].
  final Duration minCoolDownDuration;

  /// Maximum tactile pulses allowed per second to prevent hardware driver saturation.
  final int maxPulsesPerSecond;

  /// Maximum duty cycle (tactile duration / total elapsed time) over a 5-second window.
  final double maxDutyCycle;

  /// Timeout for executing custom actions in sequences to prevent controller deadlocks.
  final Duration customActionTimeout;

  /// Whether to enforce automatic micro-yields to prevent event loop starvation
  /// on zero-duration or infinite sequences.
  final bool preventEventLoopStarvation;

  /// Privacy mode for sensitive inputs and side-channel eavesdropping mitigation.
  final HapticPrivacyMode privacyMode;

  /// Creates a copy of this policy with specified fields replaced.
  HapticSafetyPolicy copyWith({
    Duration? maxContinuousDuration,
    Duration? minCoolDownDuration,
    int? maxPulsesPerSecond,
    double? maxDutyCycle,
    Duration? customActionTimeout,
    bool? preventEventLoopStarvation,
    HapticPrivacyMode? privacyMode,
  }) {
    return HapticSafetyPolicy(
      maxContinuousDuration:
          maxContinuousDuration ?? this.maxContinuousDuration,
      minCoolDownDuration: minCoolDownDuration ?? this.minCoolDownDuration,
      maxPulsesPerSecond: maxPulsesPerSecond ?? this.maxPulsesPerSecond,
      maxDutyCycle: maxDutyCycle ?? this.maxDutyCycle,
      customActionTimeout: customActionTimeout ?? this.customActionTimeout,
      preventEventLoopStarvation:
          preventEventLoopStarvation ?? this.preventEventLoopStarvation,
      privacyMode: privacyMode ?? this.privacyMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HapticSafetyPolicy &&
          runtimeType == other.runtimeType &&
          maxContinuousDuration == other.maxContinuousDuration &&
          minCoolDownDuration == other.minCoolDownDuration &&
          maxPulsesPerSecond == other.maxPulsesPerSecond &&
          (maxDutyCycle - other.maxDutyCycle).abs() < 0.001 &&
          customActionTimeout == other.customActionTimeout &&
          preventEventLoopStarvation == other.preventEventLoopStarvation &&
          privacyMode == other.privacyMode;

  @override
  int get hashCode => Object.hash(
        maxContinuousDuration,
        minCoolDownDuration,
        maxPulsesPerSecond,
        maxDutyCycle,
        customActionTimeout,
        preventEventLoopStarvation,
        privacyMode,
      );
}

/// Internal runtime watchdog that enforces a [HapticSafetyPolicy].
class HapticSafetyGuard {
  /// Creates a [HapticSafetyGuard].
  HapticSafetyGuard({HapticSafetyPolicy? policy})
      : policy = policy ?? HapticSafetyPolicy.standard;

  /// The active safety policy.
  HapticSafetyPolicy policy;

  final Stopwatch _stopwatch = Stopwatch()..start();
  int _continuousVibrationStartMicros = -1;
  int _lastTactileEndMicros = -1;
  final List<int> _recentPulseTimestampsMicros = [];

  // Rolling window for duty cycle: 5 seconds (5,000,000 microseconds)
  static const int _dutyCycleWindowMicros = 5000000;
  final List<_TactileInterval> _recentIntervals = [];

  /// Resets internal safety counters.
  void reset() {
    _continuousVibrationStartMicros = -1;
    _lastTactileEndMicros = -1;
    _recentPulseTimestampsMicros.clear();
    _recentIntervals.clear();
  }

  /// Evaluates whether a tactile pulse is permitted under the safety policy.
  ///
  /// Returns `true` if allowed, or `false` if blocked to prevent hardware strain,
  /// thermal throttling, battery drain, or acoustic eavesdropping.
  bool canTriggerTactile({Duration stepDuration = Duration.zero}) {
    if (policy == HapticSafetyPolicy.disabled) return true;
    if (policy.privacyMode == HapticPrivacyMode.mute) return false;

    final nowMicros = _stopwatch.elapsedMicroseconds;

    // 1. Rate-limiting (max pulses per second)
    final oneSecondAgo = nowMicros - 1000000;
    _recentPulseTimestampsMicros.removeWhere((t) => t < oneSecondAgo);
    if (_recentPulseTimestampsMicros.length >= policy.maxPulsesPerSecond) {
      return false; // Rate limit exceeded
    }

    // 2. Continuous vibration duration limit
    if (_lastTactileEndMicros > 0 &&
        nowMicros - _lastTactileEndMicros <
            policy.minCoolDownDuration.inMicroseconds) {
      // Still in continuous burst
      if (_continuousVibrationStartMicros > 0) {
        final continuousMicros = nowMicros - _continuousVibrationStartMicros;
        if (continuousMicros >= policy.maxContinuousDuration.inMicroseconds) {
          return false; // Continuous limit exceeded, enforce mandatory cooldown
        }
      }
    } else {
      // Cooldown met; start new continuous burst
      _continuousVibrationStartMicros = nowMicros;
    }

    // 3. Duty cycle limit check
    if (policy.maxDutyCycle < 1.0) {
      final windowStart = nowMicros - _dutyCycleWindowMicros;
      _recentIntervals
          .removeWhere((interval) => interval.endMicros < windowStart);
      var activeMicrosInWindow = 0;
      for (final interval in _recentIntervals) {
        final start = interval.startMicros < windowStart
            ? windowStart
            : interval.startMicros;
        activeMicrosInWindow += (interval.endMicros - start);
      }
      final currentDutyCycle = activeMicrosInWindow / _dutyCycleWindowMicros;
      if (currentDutyCycle >= policy.maxDutyCycle) {
        return false; // Duty cycle exceeded
      }
    }

    // Record this pulse
    _recentPulseTimestampsMicros.add(nowMicros);
    final durationMicros =
        stepDuration.inMicroseconds > 0 ? stepDuration.inMicroseconds : 30000;
    _lastTactileEndMicros = nowMicros + durationMicros;
    _recentIntervals.add(_TactileInterval(nowMicros, _lastTactileEndMicros));

    return true;
  }

  /// Calculates privacy jitter in microseconds when [HapticPrivacyMode.mask] is active.
  ///
  /// Adds non-deterministic micro-timing jitter to disguise keystroke cadence
  /// and PIN length from acoustic/accelerometer sensors.
  int getPrivacyJitterMicros() {
    if (policy.privacyMode != HapticPrivacyMode.mask) return 0;
    // Jitter between -8ms and +8ms based on monotonic clock entropy
    final entropy = (_stopwatch.elapsedMicroseconds ^
            DateTime.now().microsecondsSinceEpoch) %
        17;
    return (entropy - 8) * 1000;
  }
}

class _TactileInterval {
  const _TactileInterval(this.startMicros, this.endMicros);
  final int startMicros;
  final int endMicros;
}
