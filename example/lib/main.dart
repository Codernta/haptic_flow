import 'package:flutter/material.dart';
import 'package:haptic_flow/haptic_flow.dart';

void main() {
  runApp(const HapticFlowExampleApp());
}

class HapticFlowExampleApp extends StatelessWidget {
  const HapticFlowExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HapticFlow Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B),
          elevation: 2,
        ),
      ),
      home: const HapticFlowHomePage(),
    );
  }
}

class HapticFlowHomePage extends StatefulWidget {
  const HapticFlowHomePage({super.key});

  @override
  State<HapticFlowHomePage> createState() => _HapticFlowHomePageState();
}

class _HapticFlowHomePageState extends State<HapticFlowHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HapticFlowController _activeController;

  // Preset playback state
  HapticPlaybackEvent? _lastEvent;
  String? _currentlyPlayingName;

  // Slider demo state
  double _sliderValue = 50.0;

  // Picker wheel state
  int _selectedWheelIndex = 3;

  // Composer state
  final List<HapticStep> _customSteps = [
    const HapticStep.light(duration: Duration(milliseconds: 60)),
    const HapticStep.pause(Duration(milliseconds: 80)),
    const HapticStep.medium(duration: Duration(milliseconds: 80)),
    const HapticStep.pause(Duration(milliseconds: 80)),
    const HapticStep.heavy(duration: Duration(milliseconds: 120)),
  ];
  double _composerSpeed = 1.0;
  double _composerIntensity = 1.0;
  int _composerLoopCount = 1;
  final TextEditingController _patternInputController =
      TextEditingController(text: '.-=*_M_H');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _activeController = HapticFlowController();
    _activeController.events.listen((event) {
      if (mounted) {
        setState(() {
          _lastEvent = event;
          if (event.status == HapticPlaybackStatus.idle ||
              event.status == HapticPlaybackStatus.completed ||
              event.status == HapticPlaybackStatus.cancelled) {
            _currentlyPlayingName = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activeController.dispose();
    _patternInputController.dispose();
    super.dispose();
  }

  void _playPreset(String name, HapticSequence sequence) {
    setState(() => _currentlyPlayingName = name);
    _activeController.play(sequence);
  }

  @override
  Widget build(BuildContext context) {
    final isSupported = HapticFlow.isPlatformSupported;
    final isEnabled = HapticFlow.enabled;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.vibration, color: Color(0xFF818CF8)),
            const SizedBox(width: 10),
            const Text(
              'HapticFlow Studio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const Spacer(),
            // Platform hardware support pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSupported
                    ? const Color(0xFF065F46)
                    : const Color(0xFF78350F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSupported ? Icons.check_circle : Icons.warning_amber,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSupported ? 'Haptics Active' : 'Fallback Mode',
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Global master toggle
            IconButton(
              icon: Icon(
                isEnabled ? Icons.volume_up : Icons.volume_off,
                color: isEnabled ? Colors.white : Colors.redAccent,
              ),
              tooltip: isEnabled ? 'Mute All Haptics' : 'Unmute Haptics',
              onPressed: () {
                setState(() {
                  HapticFlow.enabled = !HapticFlow.enabled;
                  _activeController.enabled = HapticFlow.enabled;
                });
              },
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF818CF8),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome), text: 'Presets'),
            Tab(icon: Icon(Icons.tune), text: 'Controls'),
            Tab(icon: Icon(Icons.playlist_play), text: 'Composer'),
            Tab(icon: Icon(Icons.swap_vert), text: 'Physics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPresetsTab(),
          _buildControlsTab(),
          _buildComposerTab(),
          _buildPhysicsTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: PRESETS SHOWCASE
  // ---------------------------------------------------------------------------
  Widget _buildPresetsTab() {
    final presets = [
      ('Mechanical Dial', Icons.speed, 'Crisp rotary safe detents', HapticPresets.mechanicalDial),
      ('Heartbeat', Icons.favorite, 'Biological lub-dub rhythm', HapticPresets.heartbeat),
      ('Typewriter', Icons.keyboard, 'Metal typebar strike & carriage', HapticPresets.typewriter),
      ('Success Snap', Icons.check_circle_outline, 'Affirmative two-stage snap', HapticPresets.successSnap),
      ('Warning Buzz', Icons.warning_amber_rounded, 'Double cautionary pulse', HapticPresets.warningBuzz),
      ('Error Alarm', Icons.error_outline, 'Urgent triplet heavy pulse', HapticPresets.errorAlarm),
      ('Dice Roll', Icons.casino_outlined, 'Decelerating bouncing die ticks', HapticPresets.diceRoll),
      ('Recharge Pulse', Icons.bolt, 'Escalating power crescendo', HapticPresets.rechargePulse),
      ('Lock Pick', Icons.lock_open, 'Delicate pin clicks into cylinder', HapticPresets.lockPick),
      ('Countdown', Icons.timer_outlined, '3.. 2.. 1.. impact blast', HapticPresets.countdown),
      ('Sparkle', Icons.star_border, 'Rapid playful staccato flutter', HapticPresets.sparkle),
      ('Battering Ram', Icons.gavel, 'Heavy impact with reverberations', HapticPresets.batteringRam),
    ];

    return Column(
      children: [
        _buildActivePlaybackMonitor(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final (name, icon, desc, seq) = presets[index];
              final isThisPlaying = _currentlyPlayingName == name;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isThisPlaying
                        ? const Color(0xFF818CF8)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _playPreset(name, seq),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isThisPlaying
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF334155),
                              child: Icon(
                                isThisPlaying ? Icons.graphic_eq : icon,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${seq.totalDuration.inMilliseconds}ms',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivePlaybackMonitor() {
    final isPlaying = _activeController.isPlaying;
    final isPaused = _activeController.isPaused;
    final progress = _activeController.progress;
    final currentStep = _activeController.currentStep;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying ? const Color(0xFF6366F1) : const Color(0xFF334155),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isPlaying
                    ? Icons.play_arrow
                    : isPaused
                        ? Icons.pause
                        : Icons.stop,
                color: isPlaying ? Colors.greenAccent : Colors.white60,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentlyPlayingName != null
                      ? 'Playing: $_currentlyPlayingName'
                      : 'Choreography Engine Idle',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (isPlaying || isPaused) ...[
                IconButton(
                  icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                  onPressed: () {
                    if (isPaused) {
                      _activeController.resume();
                    } else {
                      _activeController.pause();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.stop, color: Colors.redAccent),
                  onPressed: () {
                    _activeController.stop();
                    setState(() => _currentlyPlayingName = null);
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (isPlaying || isPaused) ? progress : 0.0,
            backgroundColor: const Color(0xFF334155),
            color: const Color(0xFF818CF8),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentStep != null
                    ? 'Active Step: ${currentStep.type.name.toUpperCase()} (${currentStep.duration.inMilliseconds}ms) • [${(_lastEvent?.currentStepIndex ?? 0) + 1}/${_lastEvent?.totalSteps ?? 0}]'
                    : 'Awaiting sequence playback...',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: CONTROLS & WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildControlsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. HapticSlider Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.linear_scale, color: Color(0xFF818CF8)),
                    SizedBox(width: 8),
                    Text(
                      'HapticSlider with Dynamic Detents',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fires subtle detents every 10 units, a distinct snap at center (50), '
                  'and heavy bumps at min (0) and max (100) boundaries.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Value: ${_sliderValue.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF818CF8),
                    ),
                  ),
                ),
                HapticSlider(
                  value: _sliderValue,
                  min: 0.0,
                  max: 100.0,
                  detentInterval: 10.0,
                  centerDetentValue: 50.0,
                  enableEdgeFeedback: true,
                  activeColor: const Color(0xFF6366F1),
                  inactiveColor: const Color(0xFF334155),
                  thumbColor: Colors.white,
                  onChanged: (val) => setState(() => _sliderValue = val),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. HapticPickerWheel Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.view_carousel, color: Color(0xFF818CF8)),
                    SizedBox(width: 8),
                    Text(
                      'HapticPickerWheel (Mechanical Tumbler)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Scroll through the cylinder. Every slot transition delivers a crisp tactile selection tick.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Selected Slot: ${_wheelItems[_selectedWheelIndex]}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: HapticPickerWheel(
                    itemExtent: 44,
                    initialIndex: _selectedWheelIndex,
                    onSelectedItemChanged: (index) {
                      setState(() => _selectedWheelIndex = index);
                    },
                    children: _wheelItems.map((item) {
                      return Center(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. HapticGestureDetector Interactive Pad
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.touch_app, color: Color(0xFF818CF8)),
                    SizedBox(width: 8),
                    Text(
                      'HapticGestureDetector Touch Pad',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                HapticGestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tap: Light tactile feedback fired!'),
                        duration: Duration(milliseconds: 600),
                      ),
                    );
                  },
                  onDoubleTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Double Tap: Detent feedback fired!'),
                        duration: Duration(milliseconds: 600),
                      ),
                    );
                  },
                  onLongPress: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Long Press: Heavy impact fired!'),
                        duration: Duration(milliseconds: 600),
                      ),
                    );
                  },
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF334155), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF475569)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fingerprint, size: 36, color: Color(0xFF818CF8)),
                          SizedBox(height: 6),
                          Text(
                            'Tap • Double Tap • Long Press',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const List<String> _wheelItems = [
    'Mode 0: Stealth',
    'Mode 1: Eco Tactile',
    'Mode 2: Balanced',
    'Mode 3: Mechanical Drive',
    'Mode 4: High Resonant',
    'Mode 5: Overdrive',
    'Mode 6: Turbo Pulse',
    'Mode 7: Master Core',
  ];

  // ---------------------------------------------------------------------------
  // TAB 3: COMPOSER PLAYGROUND
  // ---------------------------------------------------------------------------
  Widget _buildComposerTab() {
    final customSeq = HapticSequence(
      List.of(_customSteps),
      name: 'Custom User Score',
      loopCount: _composerLoopCount,
      intensityScale: _composerIntensity,
      speedScale: _composerSpeed,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Composer Controls Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.music_note, color: Color(0xFF818CF8)),
                    const SizedBox(width: 8),
                    const Text(
                      'Interactive Sequence Score',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    Text(
                      '${customSeq.totalDuration.inMilliseconds}ms',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Timeline chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_customSteps.length, (i) {
                    final step = _customSteps[i];
                    return Chip(
                      label: Text(
                        '${i + 1}. ${step.type.name} (${step.duration.inMilliseconds}ms)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() => _customSteps.removeAt(i));
                      },
                      backgroundColor: step.isPause
                          ? const Color(0xFF334155)
                          : const Color(0xFF4338CA),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Add step buttons
                const Text('Add Step to Timeline:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('+ Light'),
                      onPressed: () => setState(() => _customSteps.add(const HapticStep.light())),
                    ),
                    ActionChip(
                      label: const Text('+ Medium'),
                      onPressed: () => setState(() => _customSteps.add(const HapticStep.medium())),
                    ),
                    ActionChip(
                      label: const Text('+ Heavy'),
                      onPressed: () => setState(() => _customSteps.add(const HapticStep.heavy())),
                    ),
                    ActionChip(
                      label: const Text('+ Click'),
                      onPressed: () => setState(() => _customSteps.add(const HapticStep.click())),
                    ),
                    ActionChip(
                      label: const Text('+ Vibrate'),
                      onPressed: () => setState(() => _customSteps.add(const HapticStep.vibrate())),
                    ),
                    ActionChip(
                      label: const Text('+ Pause 100ms'),
                      onPressed: () => setState(() => _customSteps.add(const HapticStep.pause(Duration(milliseconds: 100)))),
                    ),
                    ActionChip(
                      label: const Text('Clear All'),
                      backgroundColor: Colors.red.withAlpha(50),
                      onPressed: () => setState(() => _customSteps.clear()),
                    ),
                  ],
                ),
                const Divider(height: 32, color: Color(0xFF334155)),
                // Sliders for speed & intensity
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Speed Multiplier: ${_composerSpeed.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 12)),
                          Slider(
                            value: _composerSpeed,
                            min: 0.5,
                            max: 3.0,
                            divisions: 5,
                            onChanged: (v) => setState(() => _composerSpeed = v),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Intensity Scale: ${(_composerIntensity * 100).toInt()}%', style: const TextStyle(fontSize: 12)),
                          Slider(
                            value: _composerIntensity,
                            min: 0.1,
                            max: 1.0,
                            divisions: 9,
                            onChanged: (v) => setState(() => _composerIntensity = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play Custom Score'),
                      onPressed: _customSteps.isNotEmpty
                          ? () => _playPreset('Custom Score', customSeq)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      child: Text('Loop: ${_composerLoopCount == 0 ? "Infinite" : "${_composerLoopCount}x"}'),
                      onPressed: () {
                        setState(() {
                          if (_composerLoopCount == 1) {
                            _composerLoopCount = 3;
                          } else if (_composerLoopCount == 3) {
                            _composerLoopCount = 0; // infinite
                          } else {
                            _composerLoopCount = 1;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Shorthand Pattern Parser Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.code, color: Color(0xFF818CF8)),
                    SizedBox(width: 8),
                    Text(
                      'Shorthand Pattern Parser',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Key: . (light), - (medium), = (heavy), * (click), ~ (vibrate), _ (pause)',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _patternInputController,
                  decoration: const InputDecoration(
                    labelText: 'Tactile String Pattern',
                    border: OutlineInputBorder(),
                    hintText: '.-=*_M_H',
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Compile & Play Pattern'),
                  onPressed: () {
                    final seq = HapticSequence.fromPattern(
                      _patternInputController.text,
                      name: 'Pattern String',
                    );
                    _playPreset('Pattern: ${_patternInputController.text}', seq);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: SCROLL PHYSICS & BOUNDARY
  // ---------------------------------------------------------------------------
  bool _boundaryEnabled = true;

  Widget _buildPhysicsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HapticFeedbackBoundary Scope',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _boundaryEnabled
                          ? 'Subtree haptics active'
                          : 'Subtree haptics muted',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _boundaryEnabled,
                onChanged: (val) => setState(() => _boundaryEnabled = val),
              ),
            ],
          ),
        ),
        Expanded(
          child: HapticFeedbackBoundary(
            enabled: _boundaryEnabled,
            child: ListView.separated(
              physics: const HapticScrollPhysics(
                detentDistance: 80,
                triggerAtEdges: true,
              ),
              padding: const EdgeInsets.all(16),
              itemCount: 30,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF334155),
                      child: Text('$index'),
                    ),
                    title: Text('Tactile Scroll Item $index'),
                    subtitle: const Text('Scroll to feel boundary bounce and 80px detents'),
                    trailing: IconButton(
                      icon: const Icon(Icons.touch_app, color: Color(0xFF818CF8)),
                      onPressed: () => context.hapticSelection(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
