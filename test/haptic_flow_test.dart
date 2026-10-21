import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_flow/haptic_flow.dart';

void main() {
  group('HapticStep', () {
    test('constructors initialize correct default properties', () {
      const light = HapticStep.light();
      expect(light.type, HapticStepType.light);
      expect(light.isTactile, isTrue);
      expect(light.isPause, isFalse);
      expect(light.intensity, 0.3);

      const medium = HapticStep.medium();
      expect(medium.type, HapticStepType.medium);
      expect(medium.intensity, 0.6);

      const heavy = HapticStep.heavy();
      expect(heavy.type, HapticStepType.heavy);
      expect(heavy.intensity, 1.0);

      const selection = HapticStep.selection();
      expect(selection.type, HapticStepType.selection);
      expect(selection.intensity, 0.2);

      const click = HapticStep.click();
      expect(click.type, HapticStepType.selection);

      const vibrate = HapticStep.vibrate();
      expect(vibrate.type, HapticStepType.vibrate);
      expect(vibrate.intensity, 0.8);

      const pause = HapticStep.pause(Duration(milliseconds: 150));
      expect(pause.type, HapticStepType.pause);
      expect(pause.isPause, isTrue);
      expect(pause.isTactile, isFalse);
      expect(pause.duration, const Duration(milliseconds: 150));
    });

    test('scaling adjusts duration and intensity properly', () {
      const step = HapticStep.medium(
        duration: Duration(milliseconds: 100),
        intensity: 0.5,
      );
      final scaled = step.scaled(intensityScale: 1.5, speedScale: 2.0);
      expect(scaled.intensity, 0.75);
      expect(scaled.duration, const Duration(milliseconds: 50));
    });

    test('equality and hashcode match identical properties', () {
      const a = HapticStep.light(tag: 'step1');
      const b = HapticStep.light(tag: 'step1');
      const c = HapticStep.light(tag: 'step2');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('HapticSequence & HapticSequenceBuilder', () {
    test('builder compiles steps correctly', () {
      final seq = HapticSequence.builder('TestSeq')
          .light()
          .pause(const Duration(milliseconds: 100))
          .heavy()
          .build();

      expect(seq.name, 'TestSeq');
      expect(seq.length, 3);
      expect(seq[0].type, HapticStepType.light);
      expect(seq[1].type, HapticStepType.pause);
      expect(seq[2].type, HapticStepType.heavy);
    });

    test('pattern string parsing', () {
      final seq = HapticSequence.fromPattern(
        '. - = * ~ _',
        tickDuration: const Duration(milliseconds: 50),
        pauseDuration: const Duration(milliseconds: 100),
      );

      expect(seq.length, 6);
      expect(seq[0].type, HapticStepType.light);
      expect(seq[1].type, HapticStepType.medium);
      expect(seq[2].type, HapticStepType.heavy);
      expect(seq[3].type, HapticStepType.selection);
      expect(seq[4].type, HapticStepType.vibrate);
      expect(seq[5].type, HapticStepType.pause);
      expect(seq[5].duration, const Duration(milliseconds: 100));
    });

    test('sequence operators + and *', () {
      final seq1 = HapticSequence.builder().light().build();
      final seq2 = HapticSequence.builder().heavy().build();

      final combined = seq1 + seq2;
      expect(combined.length, 2);
      expect(combined[0].type, HapticStepType.light);
      expect(combined[1].type, HapticStepType.heavy);

      final multiplied = seq1 * 3;
      expect(multiplied.length, 3);
      expect(multiplied[0].type, HapticStepType.light);
      expect(multiplied[1].type, HapticStepType.light);
      expect(multiplied[2].type, HapticStepType.light);
    });

    test('ramp and staccato builder helpers', () {
      final rampSeq = HapticSequence.builder()
          .ramp(
            steps: 4,
            stepDuration: const Duration(milliseconds: 50),
            startIntensity: 0.1,
            endIntensity: 1.0,
          )
          .build();
      expect(rampSeq.length, 4);
      expect(rampSeq[0].intensity, closeTo(0.1, 0.01));
      expect(rampSeq[3].intensity, closeTo(1.0, 0.01));

      final staccatoSeq = HapticSequence.builder()
          .staccato(
            3,
            duration: const Duration(milliseconds: 20),
            gap: const Duration(milliseconds: 15),
          )
          .build();
      // 3 tactile clicks + 2 gaps = 5 steps
      expect(staccatoSeq.length, 5);
      expect(staccatoSeq[0].isTactile, isTrue);
      expect(staccatoSeq[1].isPause, isTrue);
      expect(staccatoSeq[2].isTactile, isTrue);
    });

    test('totalDuration accounts for speedScale', () {
      final seq = HapticSequence.builder()
          .light(duration: const Duration(milliseconds: 100))
          .heavy(duration: const Duration(milliseconds: 100))
          .scaleSpeed(2.0)
          .build();

      expect(seq.totalDuration.inMilliseconds, equals(100));
    });
  });

  group('CancellationToken', () {
    test('fires onCancel listeners when cancelled', () {
      final token = CancellationToken();
      var cancelled = false;
      token.onCancel(() => cancelled = true);

      expect(token.isCancelled, isFalse);
      expect(cancelled, isFalse);

      token.cancel();
      expect(token.isCancelled, isTrue);
      expect(cancelled, isTrue);

      // Subsequent cancel call is safe
      token.cancel();

      // Listening after cancellation invokes immediately
      var secondListenerCalled = false;
      token.onCancel(() => secondListenerCalled = true);
      expect(secondListenerCalled, isTrue);
    });

    test('throwIfCancelled throws HapticCancelledException', () {
      final token = CancellationToken();
      expect(() => token.throwIfCancelled(), returnsNormally);

      token.cancel();
      expect(() => token.throwIfCancelled(),
          throwsA(isA<HapticCancelledException>()));
    });
  });

  group('MockHapticDriver', () {
    test('records events correctly', () async {
      final driver = MockHapticDriver();
      expect(driver.count, 0);

      await driver.lightImpact();
      await driver.mediumImpact();
      await driver.heavyImpact();
      await driver.selectionClick();
      await driver.vibrate();

      expect(driver.count, 5);
      expect(driver.recordedTypes, [
        HapticStepType.light,
        HapticStepType.medium,
        HapticStepType.heavy,
        HapticStepType.selection,
        HapticStepType.vibrate,
      ]);

      driver.clear();
      expect(driver.count, 0);
    });

    test('does not record when isSupported is false', () async {
      final driver = MockHapticDriver(isSupported: false);
      await driver.lightImpact();
      expect(driver.count, 0);
    });
  });

  group('HapticFlowController', () {
    late MockHapticDriver mockDriver;
    late HapticFlowController controller;

    setUp(() {
      mockDriver = MockHapticDriver();
      controller = HapticFlowController(driver: mockDriver);
    });

    tearDown(() {
      controller.dispose();
    });

    test('plays sequence sequentially and updates progress', () async {
      final seq = HapticSequence.builder()
          .light(duration: const Duration(milliseconds: 10))
          .heavy(duration: const Duration(milliseconds: 10))
          .build();

      final states = <HapticPlaybackStatus>[];
      controller.events.listen((e) => states.add(e.status));

      await controller.play(seq);
      await pumpEventQueue();

      expect(mockDriver.recordedTypes, [
        HapticStepType.light,
        HapticStepType.heavy,
      ]);
      expect(states, contains(HapticPlaybackStatus.playing));
      expect(states, contains(HapticPlaybackStatus.completed));
    });

    test('cancellation terminates playback promptly', () async {
      final seq = HapticSequence.builder()
          .light(duration: const Duration(milliseconds: 80))
          .heavy(duration: const Duration(milliseconds: 80))
          .build();

      final cancelToken = CancellationToken();

      final playFuture = controller.play(seq, cancelToken: cancelToken);
      // Wait for first step to trigger
      await Future<void>.delayed(const Duration(milliseconds: 10));
      cancelToken.cancel();
      await playFuture;

      expect(mockDriver.recordedTypes, [HapticStepType.light]);
      expect(controller.status, HapticPlaybackStatus.idle);
    });

    test('pause and resume', () async {
      final seq = HapticSequence.builder()
          .light(duration: const Duration(milliseconds: 60))
          .heavy(duration: const Duration(milliseconds: 60))
          .build();

      final playFuture = controller.play(seq);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller.pause();
      expect(controller.isPaused, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      // Second step should not have fired yet
      expect(mockDriver.recordedTypes, [HapticStepType.light]);

      controller.resume();
      await playFuture;
      expect(mockDriver.recordedTypes, [
        HapticStepType.light,
        HapticStepType.heavy,
      ]);
    });

    test('does not play when disabled', () async {
      controller.enabled = false;
      final seq = HapticSequence.builder().light().build();
      await controller.play(seq);
      expect(mockDriver.count, 0);
    });

    test('looping sequence repeats specified number of times', () async {
      final seq = HapticSequence.builder()
          .selection(duration: const Duration(milliseconds: 10))
          .loop(3)
          .build();

      await controller.play(seq);
      expect(mockDriver.count, 3);
    });
  });

  group('HapticPresets', () {
    test('all presets have valid steps and positive duration', () {
      final presets = [
        HapticPresets.mechanicalDial,
        HapticPresets.heartbeat,
        HapticPresets.typewriter,
        HapticPresets.successSnap,
        HapticPresets.warningBuzz,
        HapticPresets.errorAlarm,
        HapticPresets.diceRoll,
        HapticPresets.rechargePulse,
        HapticPresets.lockPick,
        HapticPresets.countdown,
        HapticPresets.sparkle,
        HapticPresets.batteringRam,
      ];

      for (final preset in presets) {
        expect(preset.isNotEmpty, isTrue,
            reason: 'Preset ${preset.name} is empty');
        expect(preset.totalDuration, greaterThan(Duration.zero));
      }
    });
  });

  group('Widgets & Extensions', () {
    late MockHapticDriver mockDriver;

    setUp(() {
      mockDriver = MockHapticDriver();
      HapticFlow.driver = mockDriver;
      HapticFlow.enabled = true;
    });

    testWidgets('HapticSlider triggers edge feedback and detents',
        (tester) async {
      double value = 10.0;
      final controller = HapticFlowController(driver: mockDriver);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return HapticSlider(
                  value: value,
                  min: 0.0,
                  max: 100.0,
                  detentInterval: 10.0,
                  enableEdgeFeedback: true,
                  centerDetentValue: 50.0,
                  controller: controller,
                  onChanged: (v) => setState(() => value = v),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);

      // Drag slider thumb to test detents
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(mockDriver.count, greaterThan(0));
    });

    testWidgets('HapticGestureDetector triggers haptic feedback on gestures',
        (tester) async {
      final controller = HapticFlowController(driver: mockDriver);
      var tapped = false;
      var longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HapticGestureDetector(
              controller: controller,
              onTap: () => tapped = true,
              onLongPress: () => longPressed = true,
              child: const Text('Touch Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Touch Me'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
      expect(mockDriver.recordedTypes, contains(HapticStepType.light));

      mockDriver.clear();
      await tester.longPress(find.text('Touch Me'));
      await tester.pumpAndSettle();
      expect(longPressed, isTrue);
      expect(mockDriver.recordedTypes, contains(HapticStepType.heavy));
    });

    testWidgets('HapticFeedbackBoundary respects enabled toggle',
        (tester) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        MaterialApp(
          home: HapticFeedbackBoundary(
            enabled: false,
            child: Builder(
              builder: (ctx) {
                testContext = ctx;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(testContext.isHapticEnabled, isFalse);
      await testContext.hapticLight();
      expect(mockDriver.count, 0);
    });

    testWidgets('HapticPickerWheel triggers detents on item scroll',
        (tester) async {
      final controller = HapticFlowController(driver: mockDriver);
      int selectedItem = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: HapticPickerWheel(
                itemExtent: 40,
                controller: controller,
                onSelectedItemChanged: (index) => selectedItem = index,
                children: List.generate(10, (i) => Text('Item $i')),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(HapticPickerWheel), findsOneWidget);
      await tester.drag(find.byType(HapticPickerWheel), const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(selectedItem, greaterThan(0));
      expect(mockDriver.count, greaterThan(0));
    });
  });

  group('Security & Robustness', () {
    test('HapticStep handles NaN, negative, and extreme values safely', () {
      const step = HapticStep.medium();
      final sanitized =
          step.scaled(intensityScale: double.nan, speedScale: -5.0);
      expect(sanitized.intensity, isNot(isNaN));
      expect(sanitized.intensity, equals(0.6));
      expect(sanitized.duration.isNegative, isFalse);
    });

    test('HapticSequence enforces maximum step bounds against OOM attacks', () {
      final bigStepList = List.generate(100, (i) => const HapticStep.light());
      final seq = HapticSequence(bigStepList);
      // Attempting to multiply 100 steps by 10,000 times will be capped at maxSequenceSteps (10,000)
      final massive = seq * 200;
      expect(
          massive.length, lessThanOrEqualTo(HapticSequence.maxSequenceSteps));
    });

    test('HapticFlowController safely suppresses custom action exceptions',
        () async {
      final mockDriver = MockHapticDriver();
      final controller = HapticFlowController(driver: mockDriver);

      final seq = HapticSequence.builder()
          .light(duration: const Duration(milliseconds: 10))
          .custom(action: () => throw StateError('Simulated malicious failure'))
          .heavy(duration: const Duration(milliseconds: 10))
          .build();

      // Should complete normally without throwing unhandled exception
      await expectLater(controller.play(seq), completes);
      expect(mockDriver.recordedTypes, [
        HapticStepType.light,
        HapticStepType.heavy,
      ]);

      controller.dispose();
    });

    test('HapticFlowController safely aborts on disposal', () async {
      final mockDriver = MockHapticDriver();
      final controller = HapticFlowController(driver: mockDriver);

      final seq = HapticSequence.builder()
          .light(duration: const Duration(milliseconds: 100))
          .heavy(duration: const Duration(milliseconds: 100))
          .build();

      final playFuture = controller.play(seq);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller.dispose();
      await playFuture;

      expect(controller.isDisposed, isTrue);
      expect(mockDriver.recordedTypes, [HapticStepType.light]);
    });
  });
}
