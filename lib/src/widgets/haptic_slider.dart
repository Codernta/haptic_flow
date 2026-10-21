import 'package:flutter/material.dart';
import '../engine/haptic_flow_controller.dart';
import '../models/haptic_step.dart';

/// A haptic-enhanced [Slider] that delivers dynamic physical feedback as the
/// user drags the thumb across detents, intervals, and boundary edges.
///
/// Features:
/// * Automatic detent feedback based on [detentInterval] or [detentValues].
/// * Distinct boundary feedback at [min] and [max] edges.
/// * Distinct center snap feedback at [centerDetentValue].
/// * Customizable tactile steps for ticks, edges, and center points.
class HapticSlider extends StatefulWidget {
  /// Creates a [HapticSlider].
  const HapticSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.detentInterval,
    this.detentValues,
    this.enableEdgeFeedback = true,
    this.centerDetentValue,
    this.tickStep = const HapticStep.selection(
      duration: Duration(milliseconds: 30),
      intensity: 0.25,
    ),
    this.edgeStep = const HapticStep.heavy(
      duration: Duration(milliseconds: 80),
      intensity: 0.9,
    ),
    this.centerStep = const HapticStep.medium(
      duration: Duration(milliseconds: 60),
      intensity: 0.6,
    ),
    this.controller,
  }) : assert(min <= max, 'min must be less than or equal to max'),
       assert(
         value >= min && value <= max,
         'value $value must be between min $min and max $max',
       );

  /// The currently selected value.
  final double value;

  /// Called when the user is selecting a new value for the slider.
  final ValueChanged<double>? onChanged;

  /// Called when the user starts selecting a new value.
  final ValueChanged<double>? onChangeStart;

  /// Called when the user is done selecting a new value.
  final ValueChanged<double>? onChangeEnd;

  /// The minimum value the user can select.
  final double min;

  /// The maximum value the user can select.
  final double max;

  /// The number of discrete divisions.
  final int? divisions;

  /// A label to display above the slider thumb.
  final String? label;

  /// The color to use for the portion of the slider that is active.
  final Color? activeColor;

  /// The color for the inactive portion.
  final Color? inactiveColor;

  /// The color of the thumb.
  final Color? thumbColor;

  /// The cursor for a mouse pointer when entering or hovering over the widget.
  final MouseCursor? mouseCursor;

  /// Controls whether this widget has keyboard focus.
  final FocusNode? focusNode;

  /// True if this widget will be selected as the initial focus.
  final bool autofocus;

  /// The numerical step interval at which tactile detents are felt.
  ///
  /// For example, if min is 0, max is 100, and detentInterval is 10,
  /// detents will trigger at 10, 20, 30, etc.
  final double? detentInterval;

  /// Explicit discrete values that should trigger detents when crossed.
  final List<double>? detentValues;

  /// Whether to trigger a distinct [edgeStep] when hitting [min] or [max].
  final bool enableEdgeFeedback;

  /// An optional specific value (e.g. 0.0 or 50.0) that triggers a distinct [centerStep]
  /// when the thumb passes through it.
  final double? centerDetentValue;

  /// The tactile action triggered for normal detent ticks.
  final HapticStep tickStep;

  /// The tactile action triggered when the thumb hits the min or max edge.
  final HapticStep edgeStep;

  /// The tactile action triggered when the thumb crosses the center value.
  final HapticStep centerStep;

  /// An optional dedicated [HapticFlowController]. If null, [HapticFlow.playStep] is used.
  final HapticFlowController? controller;

  @override
  State<HapticSlider> createState() => _HapticSliderState();
}

class _HapticSliderState extends State<HapticSlider> {
  late double _lastValue;
  int? _lastIntervalIndex;
  bool _atMinEdge = false;
  bool _atMaxEdge = false;
  DateTime _lastHapticTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _lastValue = widget.value;
    _atMinEdge = widget.value <= widget.min;
    _atMaxEdge = widget.value >= widget.max;
    if (widget.detentInterval != null && widget.detentInterval! > 0) {
      _lastIntervalIndex = (widget.value / widget.detentInterval!).round();
    }
  }

  void _triggerStep(HapticStep step) {
    final now = DateTime.now();
    // Throttle detents to avoid saturating platform queues during fast sweeps (minimum 20ms gap)
    if (now.difference(_lastHapticTime).inMilliseconds < 20) return;
    _lastHapticTime = now;

    if (widget.controller != null) {
      widget.controller!.playStep(step);
    } else {
      HapticFlow.playStep(step);
    }
  }

  void _handleChanged(double newValue) {
    if (newValue.isNaN || newValue.isInfinite) return;
    final sanitizedValue = newValue.clamp(widget.min, widget.max);
    final previousValue = _lastValue;
    _lastValue = sanitizedValue;

    // 1. Check boundary edge feedback
    if (widget.enableEdgeFeedback) {
      final isNowMin = sanitizedValue <= widget.min;
      final isNowMax = sanitizedValue >= widget.max;

      if (isNowMin && !_atMinEdge) {
        _atMinEdge = true;
        _triggerStep(widget.edgeStep);
        widget.onChanged?.call(sanitizedValue);
        return;
      } else if (!isNowMin) {
        _atMinEdge = false;
      }

      if (isNowMax && !_atMaxEdge) {
        _atMaxEdge = true;
        _triggerStep(widget.edgeStep);
        widget.onChanged?.call(sanitizedValue);
        return;
      } else if (!isNowMax) {
        _atMaxEdge = false;
      }
    }

    // 2. Check center detent crossing
    if (widget.centerDetentValue != null) {
      final center = widget.centerDetentValue!;
      final crossedCenter =
          (previousValue < center && sanitizedValue >= center) ||
          (previousValue > center && sanitizedValue <= center);
      if (crossedCenter) {
        _triggerStep(widget.centerStep);
        widget.onChanged?.call(sanitizedValue);
        return;
      }
    }

    // 3. Check discrete detent values
    if (widget.detentValues != null && widget.detentValues!.isNotEmpty) {
      for (final detent in widget.detentValues!) {
        final crossed =
            (previousValue < detent && sanitizedValue >= detent) ||
            (previousValue > detent && sanitizedValue <= detent);
        if (crossed) {
          _triggerStep(widget.tickStep);
          break;
        }
      }
    }

    // 4. Check regular interval detents
    if (widget.detentInterval != null && widget.detentInterval! > 0) {
      final interval = widget.detentInterval!;
      final currentIndex = (sanitizedValue / interval).round();
      if (_lastIntervalIndex != null && currentIndex != _lastIntervalIndex) {
        _lastIntervalIndex = currentIndex;
        _triggerStep(widget.tickStep);
      }
    }

    // 5. Divisions detents if specified and no explicit detent interval given
    if (widget.divisions != null &&
        widget.divisions! > 0 &&
        widget.detentInterval == null &&
        widget.detentValues == null) {
      final stepSize = (widget.max - widget.min) / widget.divisions!;
      final prevDiv = ((previousValue - widget.min) / stepSize).round();
      final currDiv = ((sanitizedValue - widget.min) / stepSize).round();
      if (prevDiv != currDiv) {
        _triggerStep(widget.tickStep);
      }
    }

    widget.onChanged?.call(sanitizedValue);
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: widget.value,
      onChanged: widget.onChanged != null ? _handleChanged : null,
      onChangeStart: widget.onChangeStart,
      onChangeEnd: widget.onChangeEnd,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      label: widget.label,
      activeColor: widget.activeColor,
      inactiveColor: widget.inactiveColor,
      thumbColor: widget.thumbColor,
      mouseCursor: widget.mouseCursor,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
    );
  }
}
