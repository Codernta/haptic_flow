# haptic_flow

<p align="center">
  <img src="https://raw.githubusercontent.com/Codernta/haptic_flow/main/assets/haptic_flow_poster.png" alt="HapticFlow Poster" width="100%" style="border-radius: 16px;" />
</p>

[![pub package](https://img.shields.io/badge/pub-v0.1.3-blue.svg)](https://pub.dev/packages/haptic_flow)
[![CI Pipeline](https://github.com/Codernta/haptic_flow/actions/workflows/ci.yml/badge.svg)](https://github.com/Codernta/haptic_flow/actions/workflows/ci.yml)
[![license](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Flutter Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-lightgrey.svg)](https://flutter.dev)

A **Declarative Haptic Choreography Engine** for Flutter.

Compose rhythmic tactile sequences, map gestures and scrolling to dynamic physical feedback, and utilize realistic real-world tactile presets (like mechanical dials, biological heartbeats, typewriter strikes, and affirmative snaps).

---

## ✨ Features

* 🎼 **Declarative Choreography**: Compose complex, multi-stage tactile sequences using a fluent builder, sequence concatenation (`+`, `*`), and shorthand pattern syntax.
* 🛡️ **Hardware & Battery Protection**: Built-in `HapticSafetyGuard` watchdog defends against actuator motor burnout, thermal degradation, battery-drain DoS attacks, and event-loop starvation.
* 🔒 **Privacy & Anti-Eavesdropping**: `HapticPrivacyMode` (`mask`, `mute`) scrambles timing cadence on sensitive screens (PIN keypads, OTP, passwords) to defeat acoustic and accelerometer side-channel eavesdropping.
* ⚡ **Zero-Allocation Optimizations**: Monotonic microsecond clock tracking via `Stopwatch`, cached preset singletons, LRU pattern compilation memoization, and leak-free `CancellationToken` listeners.
* 💾 **Secure JSON Serialization**: Export and deserialize choreographies safely with strict schema validation and bounds clamping against malicious payloads.
* 🎛️ **Tactile Widgets**: Drop-in widgets like `HapticSlider` (with detents, center snaps, and edge bumps), `HapticPickerWheel` (mechanical rotary tumblers), and `HapticGestureDetector`.
* 📜 **Scroll Physics**: `HapticScrollPhysics` automatically fires physical tactile feedback on boundary collisions, overscroll bounces, and customizable scroll distance increments.
* 📦 **Real-World Tactile Presets**: Out-of-the-box physical choreographies (`mechanicalDial`, `heartbeat`, `typewriter`, `successSnap`, `warningBuzz`, `diceRoll`, and more).
* 🛡️ **Platform Safe**: Graceful no-op fallback on web and desktop platforms without unhandled channel exceptions.
* ♿ **Accessibility First**: Scoped muting, privacy masking, and scaling via `HapticFeedbackBoundary`, plus global master toggle support.
* 🧪 **100% Testable**: Built with a decoupled `HapticDriver` abstraction and bundled `MockHapticDriver` for deterministic unit and widget testing.

---

## 🚀 Getting Started

Add `haptic_flow` to your `pubspec.yaml`:

```yaml
dependencies:
  haptic_flow: ^0.1.3
```

Import the package:

```dart
import 'package:haptic_flow/haptic_flow.dart';
```

---

## 💡 Quick Start

### 1. One-Liner Tactile Pulses
Trigger standard tactile impacts anywhere in your app:

```dart
// Direct static calls
await HapticFlow.light();
await HapticFlow.medium();
await HapticFlow.heavy();
await HapticFlow.selection(); // fine click
await HapticFlow.vibrate();

// Or via BuildContext extension
context.hapticLight();
context.hapticSelection();
```

---

### 2. Playing Real-World Presets
Bring your app to life with curated physical presets:

```dart
// Mechanical safe dial
await HapticFlow.play(HapticPresets.mechanicalDial);

// Biological heartbeat (lub-dub)
await HapticFlow.play(HapticPresets.heartbeat);

// Affirmative double-stage success snap
await HapticFlow.play(HapticPresets.successSnap);

// Antique typewriter strike and carriage escapement
await HapticFlow.play(HapticPresets.typewriter);

// Urgent error alarm
await HapticFlow.play(HapticPresets.errorAlarm);

// Decelerating rolling dice
await HapticFlow.play(HapticPresets.diceRoll);
```

| Preset | Description |
| :--- | :--- |
| `HapticPresets.mechanicalDial` | Crisp rotary ticks separated by fine settling intervals. |
| `HapticPresets.heartbeat` | Two-stage cardiac rhythm (`lub-dub`) with resting diastole pause. |
| `HapticPresets.typewriter` | Sharp metal typebar strike followed by carriage escapement click. |
| `HapticPresets.successSnap` | Subtle preparatory tick followed by affirmative medium snap. |
| `HapticPresets.warningBuzz` | Double-pulse cautionary alert. |
| `HapticPresets.errorAlarm` | Triplet heavy pulse for critical rejections or destructive actions. |
| `HapticPresets.diceRoll` | Decelerating click sequence simulating bouncing dice. |
| `HapticPresets.rechargePulse` | Escalating power crescendo ramp. |
| `HapticPresets.lockPick` | Delicate tumbler pin clicks culminating in cylinder turning. |
| `HapticPresets.countdown` | 3 steady cadence ticks concluding with launch impact. |
| `HapticPresets.sparkle` | Playful, rapid staccato flutter of micro-clicks. |
| `HapticPresets.batteringRam` | Massive impact followed by reverberating aftershocks. |

---

### 3. Declarative Sequence Builder
Build your own tactile scores using `HapticSequenceBuilder`:

```dart
final sequence = HapticSequence.builder('Custom Score')
    .light(duration: const Duration(milliseconds: 40))
    .pause(const Duration(milliseconds: 60))
    .medium(duration: const Duration(milliseconds: 70))
    .pause(const Duration(milliseconds: 60))
    .heavy(duration: const Duration(milliseconds: 100))
    .scaleSpeed(1.2) // 20% faster
    .build();

await HapticFlow.play(sequence);
```

#### Sequence Composition & Operators
Sequences support arithmetic chaining:

```dart
final intro = HapticSequence.builder().light().pause(const Duration(milliseconds: 50)).build();
final finale = HapticSequence.builder().heavy().build();

// Concatenate sequences
final score = intro + finale;

// Repeat 3 times
final repeatedScore = intro * 3;
```

#### Shorthand Pattern Parser
Compose sequences using readable tactile strings:

```dart
// Key:
// . or L = light
// - or M = medium
// = or H = heavy
// * or S = selection click
// ~ or V = vibrate
// _      = pause
final score = HapticSequence.fromPattern(
  '.-=*_M_H',
  tickDuration: Duration(milliseconds: 50),
  pauseDuration: Duration(milliseconds: 80),
);

await HapticFlow.play(score);
```

---

## 🎛️ Tactile Widgets

### `HapticSlider`
A slider with tactile detent intervals, center snapping, and boundary edge collisions:

```dart
HapticSlider(
  value: _sliderValue,
  min: 0.0,
  max: 100.0,
  detentInterval: 10.0,      // Subtle tick every 10 units
  centerDetentValue: 50.0,   // Distinct snap at 50
  enableEdgeFeedback: true,  // Heavy bump at 0 and 100
  onChanged: (val) => setState(() => _sliderValue = val),
)
```

### `HapticPickerWheel`
A cylindrical rotary tumbler that triggers crisp mechanical ticks on every item index change:

```dart
HapticPickerWheel(
  itemExtent: 44,
  initialIndex: 2,
  onSelectedItemChanged: (index) {
    print('Selected index: $index');
  },
  children: const [
    Text('Item 1'),
    Text('Item 2'),
    Text('Item 3'),
    Text('Item 4'),
  ],
)
```

### `HapticGestureDetector`
Enriches touch interactions with distinct tactile cues:

```dart
HapticGestureDetector(
  onTap: () => print('Tapped!'),       // Light feedback
  onDoubleTap: () => print('Double!'), // Detent click
  onLongPress: () => print('Heavy!'),  // Heavy bump
  child: MyCustomCard(),
)
```

### `HapticScrollPhysics`
Adds tactile boundary collision feedback and distance detents to scrollable lists:

```dart
ListView.builder(
  physics: const HapticScrollPhysics(
    detentDistance: 80.0,    // Tactile tick every 80px scrolled
    triggerAtEdges: true,    // Distinct feedback when hitting edges or overscrolling
  ),
  itemCount: 50,
  itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
)
```

---

## 🔒 Security, Safety & Privacy

### 1. Hardware Protection & Battery DoS Defense
Uncontrolled or malicious haptic sequences (e.g. from server-driven configs or game scripts) can cause motor overheating, battery depletion, or tactile numbness. `HapticFlow` integrates a built-in safety watchdog enforcing:
* **Rate-limiting**: Prevents platform channel flooding (caps pulses per second).
* **Continuous Cutoff**: Automatically halts non-stop vibrations exceeding `maxContinuousDuration` until a mandatory cooldown resting period passes.
* **Duty-Cycle Limiting**: Restricts active vibration time to a safe fraction of any sliding window.
* **Event-Loop Starvation Defense**: Injects cooperative micro-yields on zero-duration or infinite sequences so Flutter frames never drop.
* **Sandboxed Custom Actions**: Custom closures are automatically governed by `customActionTimeout`.

```dart
// Configure global safety policy
HapticFlow.safetyPolicy = HapticSafetyPolicy.standard; // standard, strict, permissive, or disabled

// Or configure per-controller
final controller = HapticFlowController(
  safetyPolicy: HapticSafetyPolicy.strict,
);
```

### 2. Side-Channel Mitigation (Anti-Eavesdropping)
Microphones and accelerometer sensors on mobile devices can record physical vibrations to reconstruct entered PINs, keystroke cadences, and password lengths.

Use `HapticFeedbackBoundary.secure` to protect sensitive input forms:

```dart
// Scrambles keystroke timing jitter and applies strict safety policy
HapticFeedbackBoundary.secure(
  child: PinCodePad(),
)

// Or explicitly choose privacy mode
HapticFeedbackBoundary(
  privacyMode: HapticPrivacyMode.mask, // or HapticPrivacyMode.mute
  child: PasswordField(),
)
```

### 3. Secure JSON Schema Serialization
Safely transfer choreographies over WebSocket or REST APIs with strict bounds clamping:

```dart
// Serialize to JSON Map
final jsonMap = sequence.toJson();

// Deserialize safely (validates types and caps max steps)
final safeSequence = HapticSequence.fromJson(jsonMap);
```

---

## ⚡ Performance Optimizations

* **Zero-Allocation Monotonic Clock**: Hot paths in `SystemHapticDriver`, `HapticScrollPhysics`, and `HapticSlider` utilize monotonic high-precision timestamps (`Stopwatch`), eliminating thousands of short-lived `DateTime` allocations at 60/120Hz.
* **Immutable Preset Singletons**: `HapticPresets.*` instances are lazily compiled once and cached as singletons.
* **Pattern Memoization Cache**: Frequently used shorthand strings compiled via `HapticSequence.fromPattern` are stored in an LRU cache.
* **Unobserved Event Bypass**: Sequence iterations avoid allocating `HapticPlaybackEvent` objects when no listeners or streams are attached.
* **Leak-Free Cancellation Tokens**: `CancellationToken` listeners are deregistered upon completion to prevent closure retention.

---

## ♿ Accessibility & Scoped Boundaries

Mute or scale haptic feedback for entire subtrees using `HapticFeedbackBoundary`:

```dart
// Mute haptics for a specific dialog or screen
HapticFeedbackBoundary(
  enabled: false,
  child: SettingsScreen(),
)

// Or globally toggle haptics
HapticFlow.enabled = false;
```

---

## 🧪 Unit & Widget Testing

`haptic_flow` is built around the `HapticDriver` interface. In your tests, swap in `MockHapticDriver` to verify tactile choreography without touching platform channels:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_flow/haptic_flow.dart';

void main() {
  test('verifies custom choreography triggers in order', () async {
    final mockDriver = MockHapticDriver();
    final controller = HapticFlowController(driver: mockDriver);

    final sequence = HapticSequence.builder()
        .light(duration: const Duration(milliseconds: 10))
        .heavy(duration: const Duration(milliseconds: 10))
        .build();

    await controller.play(sequence);

    expect(mockDriver.recordedTypes, [
      HapticStepType.light,
      HapticStepType.heavy,
    ]);
  });
}
```

---

## 📱 Interactive Studio Example

Check out the fully-functional demo application inside the [`example/`](example/) folder. It demonstrates:
1. **Live Presets Showcase**: Visual waveforms with real-time playback progress monitors.
2. **Tactile Controls**: Interactive sliders, rotary picker wheels, and gesture touch pads.
3. **Score Composer**: Interactive timeline builder with speed and intensity scaling.
4. **Scroll Physics Playground**: Boundary bounce and distance detents.

To run the example:

```bash
cd example
flutter run
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
