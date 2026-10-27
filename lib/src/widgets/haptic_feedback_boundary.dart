import 'package:flutter/widgets.dart';
import '../security/haptic_safety_policy.dart';

/// Configuration data provided by a [HapticFeedbackBoundary].
class HapticFeedbackBoundaryData {
  /// Creates [HapticFeedbackBoundaryData] with defensive scaling sanitization.
  const HapticFeedbackBoundaryData({
    this.enabled = true,
    this.intensityScale = 1.0,
    this.speedScale = 1.0,
    this.safetyPolicy,
    this.privacyMode,
  });

  /// Whether haptic feedback is permitted within this subtree.
  final bool enabled;

  /// Intensity scaling factor for tactile feedback in this subtree.
  final double intensityScale;

  /// Speed scaling factor for sequences played within this subtree.
  final double speedScale;

  /// Optional scoped safety policy for this subtree.
  final HapticSafetyPolicy? safetyPolicy;

  /// Optional scoped privacy mode for this subtree.
  final HapticPrivacyMode? privacyMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HapticFeedbackBoundaryData &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          (intensityScale - other.intensityScale).abs() < 0.0001 &&
          (speedScale - other.speedScale).abs() < 0.0001 &&
          safetyPolicy == other.safetyPolicy &&
          privacyMode == other.privacyMode;

  @override
  int get hashCode => Object.hash(
        enabled,
        intensityScale,
        speedScale,
        safetyPolicy,
        privacyMode,
      );
}

/// An [InheritedWidget] that scopes haptic playback preferences (such as
/// muting haptics, scaling intensity, safety policy, or privacy masking) to a subtree of the widget tree.
class HapticFeedbackBoundary extends InheritedWidget {
  /// Creates a [HapticFeedbackBoundary].
  const HapticFeedbackBoundary({
    super.key,
    required super.child,
    this.enabled = true,
    this.intensityScale = 1.0,
    this.speedScale = 1.0,
    this.safetyPolicy,
    this.privacyMode,
  });

  /// Convenience constructor for security-sensitive sections (e.g. PIN codes, password inputs).
  ///
  /// Protects against acoustic and accelerometer-based side-channel keystroke inference attacks
  /// by masking timing cadence or muting vibrations.
  const HapticFeedbackBoundary.secure({
    super.key,
    required super.child,
    this.enabled = true,
    this.intensityScale = 1.0,
    this.speedScale = 1.0,
    this.safetyPolicy = HapticSafetyPolicy.strict,
    this.privacyMode = HapticPrivacyMode.mask,
  });

  /// Whether tactile haptics are enabled for children of this boundary.
  final bool enabled;

  /// Global intensity scaling factor applied within this boundary.
  final double intensityScale;

  /// Playback speed multiplier applied within this boundary.
  final double speedScale;

  /// Scoped safety policy applied within this boundary.
  final HapticSafetyPolicy? safetyPolicy;

  /// Scoped privacy mode applied within this boundary.
  final HapticPrivacyMode? privacyMode;

  /// Retrieves the ambient [HapticFeedbackBoundaryData] from the closest ancestor,
  /// with defensive boundary checking.
  static HapticFeedbackBoundaryData of(BuildContext context) {
    if (!context.mounted) return const HapticFeedbackBoundaryData();

    final boundary =
        context.dependOnInheritedWidgetOfExactType<HapticFeedbackBoundary>();
    if (boundary == null) {
      return const HapticFeedbackBoundaryData();
    }

    final safeIntensity = (boundary.intensityScale.isNaN ||
            boundary.intensityScale.isInfinite ||
            boundary.intensityScale < 0)
        ? 1.0
        : boundary.intensityScale.clamp(0.0, 10.0);

    final safeSpeed = (boundary.speedScale.isNaN ||
            boundary.speedScale.isInfinite ||
            boundary.speedScale <= 0)
        ? 1.0
        : boundary.speedScale.clamp(0.01, 100.0);

    return HapticFeedbackBoundaryData(
      enabled: boundary.enabled,
      intensityScale: safeIntensity,
      speedScale: safeSpeed,
      safetyPolicy: boundary.safetyPolicy,
      privacyMode: boundary.privacyMode,
    );
  }

  /// Convenience helper to check if haptics are enabled in the current context.
  static bool isEnabled(BuildContext context) => of(context).enabled;

  @override
  bool updateShouldNotify(HapticFeedbackBoundary oldWidget) {
    return enabled != oldWidget.enabled ||
        intensityScale != oldWidget.intensityScale ||
        speedScale != oldWidget.speedScale ||
        safetyPolicy != oldWidget.safetyPolicy ||
        privacyMode != oldWidget.privacyMode;
  }
}
