import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/haptic_step.dart';

/// An abstract interface representing a haptic feedback driver.
///
/// Implementations of [HapticDriver] are responsible for delivering physical
/// tactile feedback to the device hardware. This abstraction enables seamless
/// testing via [MockHapticDriver] and allows custom haptic backends (e.g.,
/// advanced core haptics, external game controllers, or audio-tactile engines).
abstract class HapticDriver {
  /// Default const constructor for subclasses.
  const HapticDriver();

  /// Whether tactile haptic feedback is supported and available on the current device.
  bool get isSupported;

  /// Performs a light impact haptic pulse (subtle, quick tick).
  Future<void> lightImpact();

  /// Performs a medium impact haptic pulse (distinct, crisp feedback).
  Future<void> mediumImpact();

  /// Performs a heavy impact haptic pulse (prominent, strong bump).
  Future<void> heavyImpact();

  /// Performs a tactile selection click (fine detent for pickers/sliders).
  Future<void> selectionClick();

  /// Performs a standard device vibration pulse.
  Future<void> vibrate();

  /// Triggers feedback corresponding to the provided [type].
  ///
  /// For [HapticStepType.pause] and [HapticStepType.custom], this call is a no-op
  /// or delegates according to implementation.
  Future<void> trigger(HapticStepType type) async {
    switch (type) {
      case HapticStepType.light:
        await lightImpact();
        break;
      case HapticStepType.medium:
        await mediumImpact();
        break;
      case HapticStepType.heavy:
        await heavyImpact();
        break;
      case HapticStepType.selection:
        await selectionClick();
        break;
      case HapticStepType.vibrate:
        await vibrate();
        break;
      case HapticStepType.pause:
      case HapticStepType.custom:
        break;
    }
  }
}

/// The default [HapticDriver] backed by Flutter's [HapticFeedback] system service.
///
/// Safely guards against missing platform channels, unsupported environments
/// (e.g., web or desktop), and hardware vibrator saturation without throwing
/// unhandled exceptions.
class SystemHapticDriver extends HapticDriver {
  /// Creates a [SystemHapticDriver].
  ///
  /// If [enableLogging] is true, platform warnings will be logged via [debugPrint].
  const SystemHapticDriver({this.enableLogging = false});

  /// Whether to print debug warnings when haptics fail or are unsupported.
  final bool enableLogging;

  static DateTime _lastInvokeTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Minimum spacing between hardware driver invokes (10ms) to prevent hardware thermal
  /// throttling and platform channel flooding.
  static const Duration minHardwareInterval = Duration(milliseconds: 10);

  @override
  bool get isSupported {
    if (kIsWeb) return false;
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
          return true;
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> _safeInvoke(Future<void> Function() action) async {
    if (!isSupported) return;

    final now = DateTime.now();
    if (now.difference(_lastInvokeTime) < minHardwareInterval) {
      // Gracefully coalesce rapid bursts to protect device hardware
      return;
    }
    _lastInvokeTime = now;

    try {
      await action();
    } catch (e, stackTrace) {
      if (enableLogging) {
        debugPrint(
            'HapticFlow [SystemHapticDriver] platform warning: $e\n$stackTrace');
      }
    }
  }

  @override
  Future<void> lightImpact() => _safeInvoke(HapticFeedback.lightImpact);

  @override
  Future<void> mediumImpact() => _safeInvoke(HapticFeedback.mediumImpact);

  @override
  Future<void> heavyImpact() => _safeInvoke(HapticFeedback.heavyImpact);

  @override
  Future<void> selectionClick() => _safeInvoke(HapticFeedback.selectionClick);

  @override
  Future<void> vibrate() => _safeInvoke(HapticFeedback.vibrate);
}

/// Represents a recorded haptic action for testing and verification.
class RecordedHapticEvent {
  /// Creates a [RecordedHapticEvent].
  const RecordedHapticEvent({
    required this.type,
    required this.timestamp,
    this.intensity = 1.0,
  });

  /// The tactile action type.
  final HapticStepType type;

  /// The exact time when this event was recorded.
  final DateTime timestamp;

  /// The relative intensity (0.0 to 1.0).
  final double intensity;

  @override
  String toString() =>
      'RecordedHapticEvent(type: $type, timestamp: $timestamp, intensity: $intensity)';
}

/// A mock implementation of [HapticDriver] designed for unit and widget testing.
///
/// Records all triggered haptic events in chronological order to allow
/// assertions against expected choreography behavior.
class MockHapticDriver extends HapticDriver {
  /// Creates a [MockHapticDriver] with optional [isSupported] state.
  MockHapticDriver({this.isSupported = true});

  /// Maximum events retained in memory to prevent test runner memory leaks.
  static const int maxRecordLimit = 5000;

  @override
  bool isSupported;

  final List<RecordedHapticEvent> _records = [];

  /// An unmodifiable view of all recorded events.
  List<RecordedHapticEvent> get records => List.unmodifiable(_records);

  /// A simplified list of just the recorded [HapticStepType] values.
  List<HapticStepType> get recordedTypes =>
      _records.map((e) => e.type).toList();

  /// Returns the total count of recorded events.
  int get count => _records.length;

  /// Returns the most recently triggered event, or `null` if none recorded.
  RecordedHapticEvent? get lastEvent =>
      _records.isNotEmpty ? _records.last : null;

  /// Clears all recorded events.
  void clear() => _records.clear();

  void _record(HapticStepType type, [double intensity = 1.0]) {
    if (!isSupported) return;
    if (_records.length >= maxRecordLimit) {
      _records.removeAt(0); // Evict oldest record
    }
    _records.add(
      RecordedHapticEvent(
        type: type,
        timestamp: DateTime.now(),
        intensity: intensity,
      ),
    );
  }

  @override
  Future<void> lightImpact() async => _record(HapticStepType.light, 0.3);

  @override
  Future<void> mediumImpact() async => _record(HapticStepType.medium, 0.6);

  @override
  Future<void> heavyImpact() async => _record(HapticStepType.heavy, 1.0);

  @override
  Future<void> selectionClick() async => _record(HapticStepType.selection, 0.2);

  @override
  Future<void> vibrate() async => _record(HapticStepType.vibrate, 0.8);
}
