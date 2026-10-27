import 'package:flutter/widgets.dart';
import '../engine/haptic_flow_controller.dart';
import '../models/haptic_step.dart';

/// A [ScrollPhysics] that produces physical tactile feedback when reaching
/// scroll boundaries (overscroll bounce / edge collision) or passing
/// distance detents.
class HapticScrollPhysics extends ScrollPhysics {
  /// Creates a [HapticScrollPhysics].
  const HapticScrollPhysics({
    super.parent,
    this.edgeStep = const HapticStep.medium(
      duration: Duration(milliseconds: 40),
      intensity: 0.5,
    ),
    this.tickStep = const HapticStep.selection(
      duration: Duration(milliseconds: 25),
      intensity: 0.2,
    ),
    this.detentDistance,
    this.triggerAtEdges = true,
  });

  /// The tactile action triggered when hitting or bouncing at scroll boundaries.
  final HapticStep edgeStep;

  /// The tactile action triggered when crossing distance detents.
  final HapticStep tickStep;

  /// Optional physical distance in pixels between detent ticks (e.g. 60.0).
  ///
  /// If null, only boundary edge feedback is fired.
  final double? detentDistance;

  /// Whether to fire tactile feedback when reaching minimum/maximum scroll extents.
  final bool triggerAtEdges;

  static final Stopwatch _stopwatch = Stopwatch()..start();
  static int _lastHapticMicros = -100000;

  static void _fireHaptic(HapticStep step) {
    final nowMicros = _stopwatch.elapsedMicroseconds;
    // Throttle boundary feedback to avoid overwhelming the platform bridge (35ms = 35,000 micros)
    if (nowMicros - _lastHapticMicros < 35000) return;
    _lastHapticMicros = nowMicros;
    HapticFlow.playStep(step);
  }

  @override
  HapticScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return HapticScrollPhysics(
      parent: buildParent(ancestor),
      edgeStep: edgeStep,
      tickStep: tickStep,
      detentDistance: detentDistance,
      triggerAtEdges: triggerAtEdges,
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value.isNaN || position.pixels.isNaN) return 0.0;

    if (triggerAtEdges) {
      if (value < position.pixels &&
          position.pixels <= position.minScrollExtent) {
        // Underscroll past leading edge
        _fireHaptic(edgeStep);
      } else if (value < position.minScrollExtent &&
          position.minScrollExtent < position.pixels) {
        // Hit leading edge
        _fireHaptic(edgeStep);
      } else if (value > position.pixels &&
          position.maxScrollExtent <= position.pixels) {
        // Overscroll past trailing edge
        _fireHaptic(edgeStep);
      } else if (position.pixels < position.maxScrollExtent &&
          position.maxScrollExtent < value) {
        // Hit trailing edge
        _fireHaptic(edgeStep);
      }
    }

    if (detentDistance != null &&
        detentDistance! > 0 &&
        !detentDistance!.isNaN &&
        !detentDistance!.isInfinite) {
      final prevIndex = (position.pixels / detentDistance!).floor();
      final currIndex = (value / detentDistance!).floor();
      if (prevIndex != currIndex) {
        _fireHaptic(tickStep);
      }
    }

    return super.applyBoundaryConditions(position, value);
  }
}
