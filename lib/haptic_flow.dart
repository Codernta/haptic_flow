/// A declarative haptic choreography engine for Flutter.
///
/// Compose rhythmic tactile sequences, map gestures/scrolls to dynamic
/// physical feedback, and utilize realistic tactile presets.
library;

// Drivers
export 'src/drivers/haptic_driver.dart';

// Security & Safety
export 'src/security/haptic_safety_policy.dart';

// Models
export 'src/models/haptic_pattern.dart';
export 'src/models/haptic_sequence.dart';
export 'src/models/haptic_step.dart';

// Engine
export 'src/engine/haptic_flow_controller.dart';

// Presets
export 'src/presets/haptic_presets.dart';

// Widgets
export 'src/widgets/haptic_feedback_boundary.dart';
export 'src/widgets/haptic_gesture_detector.dart';
export 'src/widgets/haptic_picker_wheel.dart';
export 'src/widgets/haptic_slider.dart';

// Extensions
export 'src/extensions/haptic_context_extensions.dart';
export 'src/extensions/haptic_scroll_physics.dart';
