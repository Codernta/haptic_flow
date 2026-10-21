import 'package:flutter/widgets.dart';
import '../engine/haptic_flow_controller.dart';
import '../models/haptic_pattern.dart';
import '../models/haptic_sequence.dart';
import '../models/haptic_step.dart';
import '../widgets/haptic_feedback_boundary.dart';

/// Ergonomic haptic extension methods on [BuildContext].
extension HapticContextExtension on BuildContext {
  /// Whether haptic feedback is allowed within the current context boundary.
  bool get isHapticEnabled => mounted && HapticFeedbackBoundary.isEnabled(this);

  /// Triggers a light impact haptic pulse.
  Future<void> hapticLight() async {
    if (!mounted || !isHapticEnabled) return;
    final boundary = HapticFeedbackBoundary.of(this);
    await HapticFlow.playStep(
      const HapticStep.light().scaled(intensityScale: boundary.intensityScale),
    );
  }

  /// Triggers a medium impact haptic pulse.
  Future<void> hapticMedium() async {
    if (!mounted || !isHapticEnabled) return;
    final boundary = HapticFeedbackBoundary.of(this);
    await HapticFlow.playStep(
      const HapticStep.medium().scaled(intensityScale: boundary.intensityScale),
    );
  }

  /// Triggers a heavy impact haptic pulse.
  Future<void> hapticHeavy() async {
    if (!mounted || !isHapticEnabled) return;
    final boundary = HapticFeedbackBoundary.of(this);
    await HapticFlow.playStep(
      const HapticStep.heavy().scaled(intensityScale: boundary.intensityScale),
    );
  }

  /// Triggers a delicate selection click detent.
  Future<void> hapticSelection() async {
    if (!mounted || !isHapticEnabled) return;
    final boundary = HapticFeedbackBoundary.of(this);
    await HapticFlow.playStep(
      const HapticStep.selection()
          .scaled(intensityScale: boundary.intensityScale),
    );
  }

  /// Alias for [hapticSelection].
  Future<void> hapticClick() => hapticSelection();

  /// Triggers a device vibration pulse.
  Future<void> hapticVibrate() async {
    if (!mounted || !isHapticEnabled) return;
    final boundary = HapticFeedbackBoundary.of(this);
    await HapticFlow.playStep(
      const HapticStep.vibrate()
          .scaled(intensityScale: boundary.intensityScale),
    );
  }

  /// Plays a full [HapticSequence] or individual [HapticStep] within this context,
  /// honoring ambient [HapticFeedbackBoundary] scaling and enablement.
  Future<void> playHaptic(
    dynamic sequenceOrStep, {
    CancellationToken? cancelToken,
  }) async {
    if (!mounted || !isHapticEnabled) return;
    final boundary = HapticFeedbackBoundary.of(this);

    if (sequenceOrStep is HapticSequence) {
      final scaledSeq = sequenceOrStep.scaled(
        intensityScale: sequenceOrStep.intensityScale * boundary.intensityScale,
        speedScale: sequenceOrStep.speedScale * boundary.speedScale,
      );
      await HapticFlow.play(scaledSeq, cancelToken: cancelToken);
    } else if (sequenceOrStep is HapticStep) {
      final scaledStep = sequenceOrStep.scaled(
        intensityScale: boundary.intensityScale,
        speedScale: boundary.speedScale,
      );
      await HapticFlow.playStep(scaledStep);
    }
  }

  /// Stops any actively playing haptic choreography.
  void stopHaptic() => HapticFlow.stop();
}
