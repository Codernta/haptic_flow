# Changelog

All notable changes to this project will be documented in this file.

## 0.1.2

* **Lightweight Distribution**:
  * Added `.pubignore` to exclude promotional media assets from the published package distribution archive, slashing package download size from **1 MB down to ~30 KB (97% reduction)**.
  * Preserved full backwards compatibility with all previous 0.1.x APIs.
* **CI/CD Quality Pipelines**:
  * Added automated GitHub Actions CI pipeline (`.github/workflows/ci.yml`) covering code formatting, static analysis (`--fatal-infos`), test coverage, example app validation, and pub.dev pre-publishing checks.
  * Added automated tag release workflow (`.github/workflows/publish.yml`).
* **Code Formatting**:
  * Standardized dart formatting across all library, test, and example files.

## 0.1.1

* **Security & Hardening**:
  * Added strict input validation and clamping for `HapticStep` intensity (`0.0` to `1.0`) and non-negative duration guards.
  * Enforced sequence memory limits (`HapticSequence.maxSequenceSteps = 10000`, `maxRepeatMultiplier = 1000`, `maxPatternLength = 50000`) preventing memory exhaustion attacks.
  * Added hardware thermal and rate-limiting protection in `SystemHapticDriver` to protect physical vibrator motors from rapid burst saturation.
  * Added concurrency session counters in `HapticFlowController` ensuring clean async cancellation and preventing race conditions.
  * Added exception isolation for custom actions in `HapticStep.custom` preventing host UI isolate crashes.
  * Added defensive `mounted` checks in `HapticContextExtension` preventing asynchronous unmounted widget tree crashes.
  * Hardened `HapticSlider`, `HapticFeedbackBoundary`, and `HapticScrollPhysics` against `NaN` and infinite value edge cases.
* **Documentation & Assets**:
  * Updated official Flutter package release poster and visual documentation.

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
