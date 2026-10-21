import 'package:flutter/widgets.dart';

/// Configuration data provided by a [HapticFeedbackBoundary].
class HapticFeedbackBoundaryData {
  /// Creates [HapticFeedbackBoundaryData].
  const HapticFeedbackBoundaryData({
    this.enabled = true,
    this.intensityScale = 1.0,
    this.speedScale = 1.0,
  });

  /// Whether haptic feedback is permitted within this subtree.
  final bool enabled;

  /// Intensity scaling factor for tactile feedback in this subtree.
  final double intensityScale;

  /// Speed scaling factor for sequences played within this subtree.
  final double speedScale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HapticFeedbackBoundaryData &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          (intensityScale - other.intensityScale).abs() < 0.0001 &&
          (speedScale - other.speedScale).abs() < 0.0001;

  @override
  int get hashCode => Object.hash(enabled, intensityScale, speedScale);
}

/// An [InheritedWidget] that scopes haptic playback preferences (such as
/// muting haptics or scaling intensity) to a subtree of the widget tree.
class HapticFeedbackBoundary extends InheritedWidget {
  /// Creates a [HapticFeedbackBoundary].
  const HapticFeedbackBoundary({
    super.key,
    required super.child,
    this.enabled = true,
    this.intensityScale = 1.0,
    this.speedScale = 1.0,
  });

  /// Whether tactile haptics are enabled for children of this boundary.
  final bool enabled;

  /// Global intensity scaling factor applied within this boundary.
  final double intensityScale;

  /// Playback speed multiplier applied within this boundary.
  final double speedScale;

  /// Retrieves the ambient [HapticFeedbackBoundaryData] from the closest ancestor,
  /// or a default enabled instance if none is found.
  static HapticFeedbackBoundaryData of(BuildContext context) {
    final boundary =
        context.dependOnInheritedWidgetOfExactType<HapticFeedbackBoundary>();
    if (boundary == null) {
      return const HapticFeedbackBoundaryData();
    }
    return HapticFeedbackBoundaryData(
      enabled: boundary.enabled,
      intensityScale: boundary.intensityScale,
      speedScale: boundary.speedScale,
    );
  }

  /// Convenience helper to check if haptics are enabled in the current context.
  static bool isEnabled(BuildContext context) => of(context).enabled;

  @override
  bool updateShouldNotify(HapticFeedbackBoundary oldWidget) {
    return enabled != oldWidget.enabled ||
        intensityScale != oldWidget.intensityScale ||
        speedScale != oldWidget.speedScale;
  }
}
