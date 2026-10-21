import '../models/haptic_sequence.dart';
import '../models/haptic_step.dart';

/// A curated library of realistic physical haptic choreographies.
///
/// These tactile presets simulate real-world physical sensations such as
/// mechanical rotary dials, biological heartbeats, typewriter key strikes,
/// and affirmative user interface confirmations.
class HapticPresets {
  HapticPresets._();

  /// A tactile simulation of turning a finely-machined metal dial or safe combination knob.
  ///
  /// Delivers crisp, regular mechanical clicks separated by brief settling pauses.
  static HapticSequence get mechanicalDial => HapticSequence.builder('Mechanical Dial')
      .selection(duration: const Duration(milliseconds: 35), intensity: 0.3)
      .pause(const Duration(milliseconds: 40))
      .selection(duration: const Duration(milliseconds: 35), intensity: 0.35)
      .pause(const Duration(milliseconds: 45))
      .selection(duration: const Duration(milliseconds: 35), intensity: 0.4)
      .pause(const Duration(milliseconds: 55))
      .selection(duration: const Duration(milliseconds: 40), intensity: 0.45)
      .pause(const Duration(milliseconds: 70))
      .light(duration: const Duration(milliseconds: 45), intensity: 0.5)
      .build();

  /// A biological cardiac rhythm ("lub-dub ... lub-dub").
  ///
  /// Combines a medium systolic contraction with a sharp heavy diastolic thump,
  /// followed by a calm resting diastole pause.
  static HapticSequence get heartbeat => HapticSequence.builder('Heartbeat')
      .medium(duration: const Duration(milliseconds: 70), intensity: 0.5, tag: 'lub')
      .pause(const Duration(milliseconds: 100))
      .heavy(duration: const Duration(milliseconds: 90), intensity: 0.85, tag: 'dub')
      .pause(const Duration(milliseconds: 650))
      .build();

  /// An antique mechanical typewriter key strike.
  ///
  /// A sharp metal typebar strike followed by an immediate carriage escapement click.
  static HapticSequence get typewriter => HapticSequence.builder('Typewriter')
      .selection(duration: const Duration(milliseconds: 30), intensity: 0.4, tag: 'strike')
      .pause(const Duration(milliseconds: 35))
      .light(duration: const Duration(milliseconds: 45), intensity: 0.3, tag: 'escapement')
      .build();

  /// An affirmative, delightful confirmation snap.
  ///
  /// A light preparatory click immediately followed by a solid medium snap.
  /// Perfect for completed tasks, successful switches, or toggle completions.
  static HapticSequence get successSnap => HapticSequence.builder('Success Snap')
      .light(duration: const Duration(milliseconds: 40), intensity: 0.35)
      .pause(const Duration(milliseconds: 30))
      .medium(duration: const Duration(milliseconds: 60), intensity: 0.7)
      .build();

  /// A cautionary double-pulse buzz.
  ///
  /// Two distinct medium-heavy pulses signaling non-destructive warnings or cautions.
  static HapticSequence get warningBuzz => HapticSequence.builder('Warning Buzz')
      .medium(duration: const Duration(milliseconds: 80), intensity: 0.65)
      .pause(const Duration(milliseconds: 90))
      .medium(duration: const Duration(milliseconds: 80), intensity: 0.65)
      .build();

  /// An urgent, unmistakable error alarm.
  ///
  /// Three forceful heavy jolts delivered in rapid succession to communicate
  /// critical failures, rejected inputs, or destructive actions.
  static HapticSequence get errorAlarm => HapticSequence.builder('Error Alarm')
      .heavy(duration: const Duration(milliseconds: 60), intensity: 1.0)
      .pause(const Duration(milliseconds: 60))
      .heavy(duration: const Duration(milliseconds: 60), intensity: 1.0)
      .pause(const Duration(milliseconds: 60))
      .heavy(duration: const Duration(milliseconds: 80), intensity: 1.0)
      .build();

  /// A decelerating sequence simulating a die rolling and settling on a table.
  ///
  /// Clicks start close together and gradually spread apart as kinetic energy dissipates.
  static HapticSequence get diceRoll => HapticSequence.builder('Dice Roll')
      .medium(duration: const Duration(milliseconds: 30), intensity: 0.7)
      .pause(const Duration(milliseconds: 35))
      .medium(duration: const Duration(milliseconds: 30), intensity: 0.6)
      .pause(const Duration(milliseconds: 60))
      .light(duration: const Duration(milliseconds: 35), intensity: 0.5)
      .pause(const Duration(milliseconds: 95))
      .light(duration: const Duration(milliseconds: 35), intensity: 0.4)
      .pause(const Duration(milliseconds: 140))
      .selection(duration: const Duration(milliseconds: 40), intensity: 0.3)
      .build();

  /// An escalating crescendo ramp simulating charging power or energizing a device.
  static HapticSequence get rechargePulse => HapticSequence.builder('Recharge Pulse')
      .ramp(
        steps: 6,
        stepDuration: const Duration(milliseconds: 55),
        startIntensity: 0.15,
        endIntensity: 1.0,
      )
      .build();

  /// Tactile lock-picking choreography: delicate pin clicks culminating in the cylinder turning.
  static HapticSequence get lockPick => HapticSequence.builder('Lock Pick')
      .selection(duration: const Duration(milliseconds: 30), intensity: 0.2, tag: 'pin-1')
      .pause(const Duration(milliseconds: 120))
      .selection(duration: const Duration(milliseconds: 30), intensity: 0.25, tag: 'pin-2')
      .pause(const Duration(milliseconds: 100))
      .light(duration: const Duration(milliseconds: 35), intensity: 0.35, tag: 'pin-3')
      .pause(const Duration(milliseconds: 140))
      .heavy(duration: const Duration(milliseconds: 90), intensity: 0.9, tag: 'cylinder-turn')
      .build();

  /// A rhythmic 3-count metronome countdown concluding with an impactful launch pulse.
  static HapticSequence get countdown => HapticSequence.builder('Countdown')
      .light(duration: const Duration(milliseconds: 60), intensity: 0.4, tag: '3')
      .pause(const Duration(milliseconds: 400))
      .light(duration: const Duration(milliseconds: 60), intensity: 0.5, tag: '2')
      .pause(const Duration(milliseconds: 400))
      .medium(duration: const Duration(milliseconds: 70), intensity: 0.7, tag: '1')
      .pause(const Duration(milliseconds: 400))
      .heavy(duration: const Duration(milliseconds: 120), intensity: 1.0, tag: 'GO')
      .build();

  /// A playful, magical staccato flutter of tiny micro-clicks.
  static HapticSequence get sparkle => HapticSequence.builder('Sparkle')
      .staccato(
        6,
        duration: const Duration(milliseconds: 25),
        gap: const Duration(milliseconds: 30),
        type: HapticStepType.selection,
      )
      .build();

  /// A massive impact with reverberating physical aftershocks.
  static HapticSequence get batteringRam => HapticSequence.builder('Battering Ram')
      .heavy(duration: const Duration(milliseconds: 110), intensity: 1.0, tag: 'impact')
      .pause(const Duration(milliseconds: 40))
      .medium(duration: const Duration(milliseconds: 60), intensity: 0.6, tag: 'aftershock-1')
      .pause(const Duration(milliseconds: 60))
      .light(duration: const Duration(milliseconds: 40), intensity: 0.35, tag: 'aftershock-2')
      .build();
}
