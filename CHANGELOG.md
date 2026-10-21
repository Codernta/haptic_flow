# Changelog

All notable changes to this project will be documented in this file.

## 0.1.0

* Initial release of **`haptic_flow`**: A Declarative Haptic Choreography Engine for Flutter.
* **Core Architecture**:
  * `HapticStep`: Granular tactile actions (`light`, `medium`, `heavy`, `selection`, `click`, `vibrate`, `pause`, and `custom`) with duration and intensity scaling.
  * `HapticSequence`: Composable timeline sequences with operator overloading (`+`, `*`), fluent builder (`HapticSequenceBuilder`), and shorthand pattern parser (`HapticSequence.fromPattern`).
  * `HapticFlowController` & `HapticFlow`: Reactive playback engine supporting asynchronous scheduling, cancellation tokens (`CancellationToken`), pause/resume, and platform capability checks.
  * `HapticDriver` Abstraction: Pluggable drivers including `SystemHapticDriver` (safe no-op fallback on web and desktop) and `MockHapticDriver` for deterministic testing.
* **Physical Real-World Presets**:
  * `mechanicalDial`, `heartbeat`, `typewriter`, `successSnap`, `warningBuzz`, `errorAlarm`, `diceRoll`, `rechargePulse`, `lockPick`, `countdown`, `sparkle`, and `batteringRam`.
* **Tactile Widgets & Extensions**:
  * `HapticSlider`: Tactile slider with detent intervals, center snap, edge collision feedback, and high-frequency throttling.
  * `HapticPickerWheel`: Mechanical rotary tumbler with tactile slot transitions.
  * `HapticGestureDetector`: Touch pad with haptic feedback on tap, double-tap, and long-press.
  * `HapticFeedbackBoundary`: Scoped subtree configuration for muting and intensity/speed scaling.
  * `HapticScrollPhysics`: Scroll physics with boundary collision feedback and distance detents.
  * `HapticContextExtension`: Ergonomic context helpers (`context.hapticLight()`, `context.playHaptic()`, etc.).
* **Showcase Example & Tests**:
  * Interactive studio example app with preset visualizer, widget playground, and live score composer.
  * Comprehensive test suite with 100% test coverage for core choreography engine and widgets.
