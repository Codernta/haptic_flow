import 'dart:async';
import 'package:flutter/foundation.dart';
import 'haptic_step.dart';

/// A declarative, rhythmic sequence of [HapticStep] items designed for
/// tactile choreography.
///
/// Sequences can be created directly, constructed using [HapticSequenceBuilder],
/// or parsed from shorthand pattern strings.
@immutable
class HapticSequence {
  /// Maximum number of steps permitted in a sequence to prevent memory exhaustion / OOM attacks.
  static const int maxSequenceSteps = 10000;

  /// Maximum multiplier for sequence repetition (`*` operator).
  static const int maxRepeatMultiplier = 1000;

  /// Maximum characters parsed in a single shorthand pattern.
  static const int maxPatternLength = 50000;

  /// Creates a [HapticSequence] with defensive property validation.
  const HapticSequence(
    this.steps, {
    this.name,
    this.loopCount = 1,
    this.intensityScale = 1.0,
    this.speedScale = 1.0,
  }) : assert(intensityScale >= 0.0, 'intensityScale must be non-negative'),
       assert(speedScale > 0.0, 'speedScale must be strictly positive');

  /// Creates an empty sequence.
  const HapticSequence.empty() : this(const []);

  /// Starts building a sequence with a fluent [HapticSequenceBuilder].
  static HapticSequenceBuilder builder([String? name]) =>
      HapticSequenceBuilder(name);

  /// Compiles a sequence from a tactile shorthand string [pattern] with safe length limits.
  ///
  /// Key:
  /// * `.` or `L` / `l` -> [HapticStep.light]
  /// * `-` or `M` / `m` -> [HapticStep.medium]
  /// * `=` or `H` / `h` -> [HapticStep.heavy]
  /// * `*` or `S` / `s` -> [HapticStep.selection]
  /// * `~` or `V` / `v` -> [HapticStep.vibrate]
  /// * `_`             -> [HapticStep.pause]
  /// * ` ` (space)     -> Ignored as formatting whitespace
  factory HapticSequence.fromPattern(
    String pattern, {
    Duration tickDuration = const Duration(milliseconds: 50),
    Duration pauseDuration = const Duration(milliseconds: 100),
    String? name,
    int loopCount = 1,
  }) {
    final sanitizedPattern = pattern.length > maxPatternLength
        ? pattern.substring(0, maxPatternLength)
        : pattern;

    final steps = <HapticStep>[];
    for (int i = 0; i < sanitizedPattern.length; i++) {
      if (steps.length >= maxSequenceSteps) break;
      final char = sanitizedPattern[i];
      switch (char) {
        case '.':
        case 'l':
        case 'L':
          steps.add(HapticStep.light(duration: tickDuration));
          break;
        case '-':
        case 'm':
        case 'M':
          steps.add(HapticStep.medium(duration: tickDuration));
          break;
        case '=':
        case 'h':
        case 'H':
          steps.add(HapticStep.heavy(duration: tickDuration));
          break;
        case '*':
        case 's':
        case 'S':
          steps.add(HapticStep.selection(duration: tickDuration));
          break;
        case '~':
        case 'v':
        case 'V':
          steps.add(HapticStep.vibrate(duration: tickDuration * 2));
          break;
        case '_':
          steps.add(HapticStep.pause(pauseDuration));
          break;
        case ' ':
        default:
          // Ignore formatting whitespace or unrecognized characters
          break;
      }
    }
    return HapticSequence(steps, name: name, loopCount: loopCount);
  }

  /// The list of tactile steps and pauses in this sequence.
  final List<HapticStep> steps;

  /// An optional display or debugging name for this sequence.
  final String? name;

  /// The number of times this sequence should play.
  ///
  /// A value of `1` plays once. A value of `0` or negative indicates infinite looping.
  final int loopCount;

  /// Global scaling factor applied to all step intensities.
  final double intensityScale;

  /// Global speed multiplier applied to playback.
  ///
  /// Values greater than 1.0 accelerate playback; values between 0.0 and 1.0 slow it down.
  final double speedScale;

  /// The total calculated playback duration for a single iteration of this sequence,
  /// accounting for [speedScale].
  Duration get totalDuration {
    var totalMicros = 0;
    final safeSpeed = (speedScale.isNaN || speedScale.isInfinite || speedScale <= 0)
        ? 1.0
        : speedScale;
    for (final step in steps) {
      final scaledMicros =
          (step.duration.inMicroseconds / safeSpeed).round();
      totalMicros += scaledMicros;
    }
    return Duration(microseconds: totalMicros);
  }

  /// Total number of steps in the sequence.
  int get length => steps.length;

  /// Whether the sequence contains no steps.
  bool get isEmpty => steps.isEmpty;

  /// Whether the sequence contains one or more steps.
  bool get isNotEmpty => steps.isNotEmpty;

  /// Whether this sequence is set to loop indefinitely.
  bool get isInfinite => loopCount <= 0;

  /// Retrieves the step at [index].
  HapticStep operator [](int index) => steps[index];

  /// Concatenates this sequence with [other] to create a new sequence,
  /// strictly enforcing [maxSequenceSteps].
  HapticSequence operator +(HapticSequence other) {
    final available = maxSequenceSteps - steps.length;
    final otherSteps = available > 0
        ? (other.steps.length > available
            ? other.steps.take(available)
            : other.steps)
        : const <HapticStep>[];

    return HapticSequence(
      [...steps, ...otherSteps],
      name: name != null && other.name != null ? '$name + ${other.name}' : null,
      loopCount: loopCount,
      intensityScale: intensityScale,
      speedScale: speedScale,
    );
  }

  /// Multiplies the steps of this sequence [times] times, enforcing strict memory bounds.
  HapticSequence operator *(int times) {
    if (times <= 0 || steps.isEmpty) return const HapticSequence.empty();
    final safeTimes = times.clamp(0, maxRepeatMultiplier);
    final repeated = <HapticStep>[];
    for (var i = 0; i < safeTimes; i++) {
      if (repeated.length + steps.length > maxSequenceSteps) {
        final remaining = maxSequenceSteps - repeated.length;
        if (remaining > 0) repeated.addAll(steps.take(remaining));
        break;
      }
      repeated.addAll(steps);
    }
    return HapticSequence(
      repeated,
      name: name != null ? '$name x$safeTimes' : null,
      loopCount: loopCount,
      intensityScale: intensityScale,
      speedScale: speedScale,
    );
  }

  /// Returns a new sequence with the order of steps reversed.
  HapticSequence reversed() {
    return HapticSequence(
      steps.reversed.toList(),
      name: name != null ? '$name (reversed)' : null,
      loopCount: loopCount,
      intensityScale: intensityScale,
      speedScale: speedScale,
    );
  }

  /// Returns a copy of this sequence with modified scaling.
  HapticSequence scaled({double? intensityScale, double? speedScale}) {
    return copyWith(
      intensityScale: intensityScale ?? this.intensityScale,
      speedScale: speedScale ?? this.speedScale,
    );
  }

  /// Returns a copy of this sequence configured to loop [count] times.
  /// Pass `0` for infinite looping.
  HapticSequence loop([int count = 0]) => copyWith(loopCount: count);

  /// Returns a copy with the given fields replaced.
  HapticSequence copyWith({
    List<HapticStep>? steps,
    String? name,
    int? loopCount,
    double? intensityScale,
    double? speedScale,
  }) {
    final rawIntensity = intensityScale ?? this.intensityScale;
    final safeIntensity = (rawIntensity.isNaN || rawIntensity.isInfinite || rawIntensity < 0)
        ? 1.0
        : rawIntensity.clamp(0.0, 10.0);

    final rawSpeed = speedScale ?? this.speedScale;
    final safeSpeed = (rawSpeed.isNaN || rawSpeed.isInfinite || rawSpeed <= 0)
        ? 1.0
        : rawSpeed.clamp(0.01, 100.0);

    return HapticSequence(
      steps ?? this.steps,
      name: name ?? this.name,
      loopCount: loopCount ?? this.loopCount,
      intensityScale: safeIntensity,
      speedScale: safeSpeed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HapticSequence &&
          runtimeType == other.runtimeType &&
          listEquals(steps, other.steps) &&
          name == other.name &&
          loopCount == other.loopCount &&
          (intensityScale - other.intensityScale).abs() < 0.0001 &&
          (speedScale - other.speedScale).abs() < 0.0001;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(steps),
        name,
        loopCount,
        intensityScale,
        speedScale,
      );

  @override
  String toString() =>
      'HapticSequence(${name ?? "unnamed"}, steps: ${steps.length}, '
      'duration: ${totalDuration.inMilliseconds}ms, loops: $loopCount)';
}

/// A fluent builder for constructing declarative [HapticSequence] instances.
class HapticSequenceBuilder {
  /// Creates a [HapticSequenceBuilder].
  HapticSequenceBuilder([this._name]);

  String? _name;
  int _loopCount = 1;
  double _intensityScale = 1.0;
  double _speedScale = 1.0;
  final List<HapticStep> _steps = [];

  bool get _canAddStep => _steps.length < HapticSequence.maxSequenceSteps;

  /// Sets the sequence name.
  HapticSequenceBuilder withName(String name) {
    _name = name;
    return this;
  }

  /// Configures looping. Set to `0` for infinite playback.
  HapticSequenceBuilder loop([int count = 0]) {
    _loopCount = count;
    return this;
  }

  /// Sets the global intensity scaling factor.
  HapticSequenceBuilder scaleIntensity(double factor) {
    if (!factor.isNaN && !factor.isInfinite && factor >= 0) {
      _intensityScale = factor.clamp(0.0, 10.0);
    }
    return this;
  }

  /// Sets the global playback speed factor.
  HapticSequenceBuilder scaleSpeed(double factor) {
    if (!factor.isNaN && !factor.isInfinite && factor > 0) {
      _speedScale = factor.clamp(0.01, 100.0);
    }
    return this;
  }

  /// Appends a light impact step.
  HapticSequenceBuilder light({
    Duration duration = const Duration(milliseconds: 50),
    double intensity = 0.3,
    String? tag,
  }) {
    if (_canAddStep) {
      _steps.add(HapticStep.light(duration: duration, intensity: intensity, tag: tag));
    }
    return this;
  }

  /// Appends a medium impact step.
  HapticSequenceBuilder medium({
    Duration duration = const Duration(milliseconds: 70),
    double intensity = 0.6,
    String? tag,
  }) {
    if (_canAddStep) {
      _steps.add(HapticStep.medium(duration: duration, intensity: intensity, tag: tag));
    }
    return this;
  }

  /// Appends a heavy impact step.
  HapticSequenceBuilder heavy({
    Duration duration = const Duration(milliseconds: 100),
    double intensity = 1.0,
    String? tag,
  }) {
    if (_canAddStep) {
      _steps.add(HapticStep.heavy(duration: duration, intensity: intensity, tag: tag));
    }
    return this;
  }

  /// Appends a selection detent step.
  HapticSequenceBuilder selection({
    Duration duration = const Duration(milliseconds: 40),
    double intensity = 0.2,
    String? tag,
  }) {
    if (_canAddStep) {
      _steps.add(HapticStep.selection(duration: duration, intensity: intensity, tag: tag));
    }
    return this;
  }

  /// Alias for [selection].
  HapticSequenceBuilder click({
    Duration duration = const Duration(milliseconds: 40),
    double intensity = 0.2,
    String? tag,
  }) => selection(duration: duration, intensity: intensity, tag: tag);

  /// Appends a vibration pulse step.
  HapticSequenceBuilder vibrate({
    Duration duration = const Duration(milliseconds: 200),
    double intensity = 0.8,
    String? tag,
  }) {
    if (_canAddStep) {
      _steps.add(HapticStep.vibrate(duration: duration, intensity: intensity, tag: tag));
    }
    return this;
  }

  /// Appends a non-tactile pause or delay.
  HapticSequenceBuilder pause(Duration duration, {String? tag}) {
    if (_canAddStep) {
      _steps.add(HapticStep.pause(duration, tag: tag));
    }
    return this;
  }

  /// Appends a custom programmatic step.
  HapticSequenceBuilder custom({
    required FutureOr<void> Function() action,
    Duration duration = Duration.zero,
    double intensity = 1.0,
    String? tag,
  }) {
    if (_canAddStep) {
      _steps.add(HapticStep.custom(
        action: action,
        duration: duration,
        intensity: intensity,
        tag: tag,
      ));
    }
    return this;
  }

  /// Appends an existing [HapticStep].
  HapticSequenceBuilder step(HapticStep step) {
    if (_canAddStep) {
      _steps.add(step);
    }
    return this;
  }

  /// Appends multiple existing [HapticStep] items.
  HapticSequenceBuilder steps(Iterable<HapticStep> steps) {
    for (final s in steps) {
      if (!_canAddStep) break;
      _steps.add(s);
    }
    return this;
  }

  /// Parses and appends steps from a shorthand tactile [pattern].
  HapticSequenceBuilder pattern(
    String pattern, {
    Duration tickDuration = const Duration(milliseconds: 50),
    Duration pauseDuration = const Duration(milliseconds: 100),
  }) {
    final parsed = HapticSequence.fromPattern(
      pattern,
      tickDuration: tickDuration,
      pauseDuration: pauseDuration,
    );
    for (final s in parsed.steps) {
      if (!_canAddStep) break;
      _steps.add(s);
    }
    return this;
  }

  /// Appends an intensity ramp (crescendo or decrescendo) of tactile steps.
  HapticSequenceBuilder ramp({
    required int steps,
    required Duration stepDuration,
    double startIntensity = 0.1,
    double endIntensity = 1.0,
  }) {
    final safeSteps = steps.clamp(1, 500);
    for (int i = 0; i < safeSteps; i++) {
      if (!_canAddStep) break;
      final t = safeSteps == 1 ? 1.0 : i / (safeSteps - 1);
      final intensity = startIntensity + (endIntensity - startIntensity) * t;
      HapticStepType type;
      if (intensity < 0.35) {
        type = HapticStepType.light;
      } else if (intensity < 0.75) {
        type = HapticStepType.medium;
      } else {
        type = HapticStepType.heavy;
      }
      _steps.add(HapticStep(
        type: type,
        duration: stepDuration,
        intensity: intensity.clamp(0.0, 1.0),
      ));
    }
    return this;
  }

  /// Appends a rapid staccato burst of clicks with rhythmic gaps.
  HapticSequenceBuilder staccato(
    int count, {
    Duration duration = const Duration(milliseconds: 30),
    Duration gap = const Duration(milliseconds: 30),
    HapticStepType type = HapticStepType.selection,
  }) {
    final safeCount = count.clamp(1, 500);
    for (int i = 0; i < safeCount; i++) {
      if (!_canAddStep) break;
      _steps.add(HapticStep(type: type, duration: duration));
      if (i < safeCount - 1 && gap > Duration.zero) {
        if (!_canAddStep) break;
        _steps.add(HapticStep.pause(gap));
      }
    }
    return this;
  }

  /// Repeats a sub-sequence block [times] times.
  HapticSequenceBuilder repeat(
    int times,
    void Function(HapticSequenceBuilder sub) subSequence,
  ) {
    final safeTimes = times.clamp(0, HapticSequence.maxRepeatMultiplier);
    if (safeTimes == 0) return this;

    final sub = HapticSequenceBuilder();
    subSequence(sub);
    final builtSub = sub.build();
    for (var i = 0; i < safeTimes; i++) {
      for (final s in builtSub.steps) {
        if (!_canAddStep) break;
        _steps.add(s);
      }
    }
    return this;
  }

  /// Finalizes and compiles the [HapticSequence].
  HapticSequence build() {
    return HapticSequence(
      List.unmodifiable(_steps),
      name: _name,
      loopCount: _loopCount,
      intensityScale: _intensityScale,
      speedScale: _speedScale,
    );
  }
}
