import 'package:flutter/material.dart';
import '../engine/haptic_flow_controller.dart';
import '../models/haptic_step.dart';

/// A [GestureDetector] wrapper that enriches standard touch gestures with
/// tactile haptic feedback.
///
/// Automatically fires customizable haptic steps upon tap, double-tap, and
/// long-press events.
class HapticGestureDetector extends StatelessWidget {
  /// Creates a [HapticGestureDetector].
  const HapticGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.tapStep = const HapticStep.light(
      duration: Duration(milliseconds: 30),
      intensity: 0.3,
    ),
    this.doubleTapStep = const HapticStep.selection(
      duration: Duration(milliseconds: 30),
      intensity: 0.4,
    ),
    this.longPressStep = const HapticStep.heavy(
      duration: Duration(milliseconds: 80),
      intensity: 0.9,
    ),
    this.enableHaptics = true,
    this.behavior = HitTestBehavior.opaque,
    this.controller,
  });

  /// The child widget.
  final Widget child;

  /// Called when a tap occurs.
  final GestureTapCallback? onTap;

  /// Called when a double tap occurs.
  final GestureTapCallback? onDoubleTap;

  /// Called when a long press occurs.
  final GestureLongPressCallback? onLongPress;

  /// Called when a secondary tap (e.g. right click) occurs.
  final GestureTapCallback? onSecondaryTap;

  /// Tactile action triggered on tap.
  final HapticStep tapStep;

  /// Tactile action triggered on double tap.
  final HapticStep doubleTapStep;

  /// Tactile action triggered on long press.
  final HapticStep longPressStep;

  /// Whether haptic feedback is active.
  final bool enableHaptics;

  /// How to behave during hit testing.
  final HitTestBehavior behavior;

  /// An optional dedicated [HapticFlowController].
  final HapticFlowController? controller;

  void _trigger(HapticStep step) {
    if (!enableHaptics) return;
    if (controller != null) {
      controller!.playStep(step);
    } else {
      HapticFlow.playStep(step);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: behavior,
      onTap: onTap != null
          ? () {
              _trigger(tapStep);
              onTap!();
            }
          : null,
      onDoubleTap: onDoubleTap != null
          ? () {
              _trigger(doubleTapStep);
              onDoubleTap!();
            }
          : null,
      onLongPress: onLongPress != null
          ? () {
              _trigger(longPressStep);
              onLongPress!();
            }
          : null,
      onSecondaryTap: onSecondaryTap != null
          ? () {
              _trigger(tapStep);
              onSecondaryTap!();
            }
          : null,
      child: child,
    );
  }
}
