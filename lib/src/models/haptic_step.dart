import 'dart:async';
import 'package:flutter/foundation.dart';

/// The discrete category or tactile nature of a haptic step.
enum HapticStepType {
  /// Subtle, crisp impact (similar to iOS light haptic / Android tick).
  light,

  /// Distinct, balanced impact (similar to iOS medium haptic / Android click).
  medium,

  /// Strong, prominent bump (similar to iOS heavy haptic / Android heavy click).
  heavy,

  /// Delicate selection detent (ideal for pickers, dials, and sliders).
  selection,

  /// Device vibration pulse.
  vibrate,

  /// Non-tactile delay or silent interval in a choreography.
  pause,

  /// Custom programmable action executed at this step in the timeline.
  custom,
}

/// Represents an individual tactile action or pause in a [HapticSequence].
///
/// Steps can be chained together sequentially to construct complex, rhythmic
/// haptic choreographies such as heartbeats, mechanical dials, or celebratory snaps.
@immutable
class HapticStep {
  /// Maximum safety duration for an individual step to prevent thread/scheduler locking.
  static const Duration maxStepDuration = Duration(minutes: 5);

  /// Creates a raw [HapticStep] with strict runtime parameter sanitization.
  const HapticStep({
    required this.type,
    this.duration = const Duration(milliseconds: 50),
    this.intensity = 1.0,
    this.customAction,
    this.tag,
  }) : assert(
          intensity >= 0.0 && intensity <= 1.0,
          'intensity must be between 0.0 and 1.0',
        );

  /// Creates a light impact tactile step.
  const HapticStep.light({
    Duration duration = const Duration(milliseconds: 50),
    double intensity = 0.3,
    String? tag,
  }) : this(
          type: HapticStepType.light,
          duration: duration,
          intensity: intensity,
          tag: tag,
        );

  /// Creates a medium impact tactile step.
  const HapticStep.medium({
    Duration duration = const Duration(milliseconds: 70),
    double intensity = 0.6,
    String? tag,
  }) : this(
          type: HapticStepType.medium,
          duration: duration,
          intensity: intensity,
          tag: tag,
        );

  /// Creates a heavy impact tactile step.
  const HapticStep.heavy({
    Duration duration = const Duration(milliseconds: 100),
    double intensity = 1.0,
    String? tag,
  }) : this(
          type: HapticStepType.heavy,
          duration: duration,
          intensity: intensity,
          tag: tag,
        );

  /// Creates a delicate selection detent step (standard dial/slider click).
  const HapticStep.selection({
    Duration duration = const Duration(milliseconds: 40),
    double intensity = 0.2,
    String? tag,
  }) : this(
          type: HapticStepType.selection,
          duration: duration,
          intensity: intensity,
          tag: tag,
        );

  /// Alias for [HapticStep.selection].
  const HapticStep.click({
    Duration duration = const Duration(milliseconds: 40),
    double intensity = 0.2,
    String? tag,
  }) : this.selection(duration: duration, intensity: intensity, tag: tag);

  /// Creates a standard device vibration step.
  const HapticStep.vibrate({
    Duration duration = const Duration(milliseconds: 200),
    double intensity = 0.8,
    String? tag,
  }) : this(
          type: HapticStepType.vibrate,
          duration: duration,
          intensity: intensity,
          tag: tag,
        );

  /// Creates a non-tactile pause or resting period in a sequence.
  const HapticStep.pause(Duration duration, {String? tag})
      : this(
          type: HapticStepType.pause,
          duration: duration,
          intensity: 0.0,
          tag: tag,
        );

  /// Creates a custom step that executes an arbitrary asynchronous [action].
  const HapticStep.custom({
    required FutureOr<void> Function() action,
    Duration duration = Duration.zero,
    double intensity = 1.0,
    String? tag,
  }) : this(
          type: HapticStepType.custom,
          duration: duration,
          intensity: intensity,
          customAction: action,
          tag: tag,
        );

  /// The category or tactile type of this step.
  final HapticStepType type;

  /// The duration of this step.
  ///
  /// For physical impacts, this represents the settling delay before moving to
  /// the next step in the timeline. For [HapticStepType.pause], it represents
  /// the duration of silence.
  final Duration duration;

  /// The normalized intensity (0.0 to 1.0).
  ///
  /// Used for intensity scaling, logging, or custom drivers capable of
  /// continuous amplitude control.
  final double intensity;

  /// An optional custom async action executed when this step is triggered.
  final FutureOr<void> Function()? customAction;

  /// An optional tag for identifying, categorizing, or debugging this step.
  final String? tag;

  /// Whether this step is a silent delay.
  bool get isPause => type == HapticStepType.pause;

  /// Whether this step triggers tactile hardware feedback.
  bool get isTactile => !isPause && type != HapticStepType.custom;

  /// Returns a copy of this step with specified fields replaced, enforcing strict safety bounds.
  HapticStep copyWith({
    HapticStepType? type,
    Duration? duration,
    double? intensity,
    FutureOr<void> Function()? customAction,
    String? tag,
  }) {
    final rawIntensity = intensity ?? this.intensity;
    final safeIntensity =
        rawIntensity.isNaN ? 0.0 : rawIntensity.clamp(0.0, 1.0);

    final rawDuration = duration ?? this.duration;
    final safeDuration = rawDuration.isNegative
        ? Duration.zero
        : (rawDuration > maxStepDuration ? maxStepDuration : rawDuration);

    return HapticStep(
      type: type ?? this.type,
      duration: safeDuration,
      intensity: safeIntensity,
      customAction: customAction ?? this.customAction,
      tag: tag ?? this.tag,
    );
  }

  /// Returns a copy of this step with a new [duration].
  HapticStep withDuration(Duration newDuration) =>
      copyWith(duration: newDuration);

  /// Returns a copy of this step with a new [intensity].
  HapticStep withIntensity(double newIntensity) =>
      copyWith(intensity: newIntensity);

  /// Returns a copy scaled by [intensityScale] and [speedScale] with defensive sanitization.
  HapticStep scaled({double intensityScale = 1.0, double speedScale = 1.0}) {
    final safeIntensityScale = (intensityScale.isNaN ||
            intensityScale.isInfinite ||
            intensityScale < 0)
        ? 1.0
        : intensityScale;
    final safeSpeedScale =
        (speedScale.isNaN || speedScale.isInfinite || speedScale <= 0)
            ? 1.0
            : speedScale.clamp(0.01, 100.0);

    final newIntensity = (intensity * safeIntensityScale).clamp(0.0, 1.0);
    final rawMicros = (duration.inMicroseconds / safeSpeedScale).round();
    final safeMicros = rawMicros.clamp(0, maxStepDuration.inMicroseconds);

    return copyWith(
      intensity: newIntensity,
      duration: Duration(microseconds: safeMicros),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HapticStep &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          duration == other.duration &&
          (intensity - other.intensity).abs() < 0.0001 &&
          tag == other.tag;

  @override
  int get hashCode => Object.hash(type, duration, intensity, tag);

  @override
  String toString() {
    final tagStr = tag != null ? ' ($tag)' : '';
    return 'HapticStep.$type(${duration.inMilliseconds}ms, ${(intensity * 100).round()}%$tagStr)';
  }
}
