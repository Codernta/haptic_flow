import 'package:flutter/material.dart';
import '../engine/haptic_flow_controller.dart';
import '../models/haptic_step.dart';

/// A rotary wheel / drum picker widget that delivers crisp tactile feedback
/// on every item detent change.
///
/// Simulates physical dials, tumblers, and mechanical wheel selectors.
class HapticPickerWheel extends StatefulWidget {
  /// Creates a [HapticPickerWheel] with an explicit list of child widgets.
  const HapticPickerWheel({
    super.key,
    required this.itemExtent,
    required this.onSelectedItemChanged,
    required List<Widget> children,
    this.initialIndex = 0,
    this.scrollController,
    this.diameterRatio = 1.2,
    this.perspective = 0.003,
    this.magnification = 1.15,
    this.useMagnifier = true,
    this.detentStep = const HapticStep.selection(
      duration: Duration(milliseconds: 30),
      intensity: 0.3,
    ),
    this.boundaryStep = const HapticStep.medium(
      duration: Duration(milliseconds: 50),
      intensity: 0.6,
    ),
    this.physics = const FixedExtentScrollPhysics(),
    this.controller,
  })  : children = children,
        itemBuilder = null,
        itemCount = children.length;

  /// Creates a [HapticPickerWheel] with a lazily-built child delegate.
  const HapticPickerWheel.builder({
    super.key,
    required this.itemExtent,
    required this.onSelectedItemChanged,
    required this.itemBuilder,
    required this.itemCount,
    this.initialIndex = 0,
    this.scrollController,
    this.diameterRatio = 1.2,
    this.perspective = 0.003,
    this.magnification = 1.15,
    this.useMagnifier = true,
    this.detentStep = const HapticStep.selection(
      duration: Duration(milliseconds: 30),
      intensity: 0.3,
    ),
    this.boundaryStep = const HapticStep.medium(
      duration: Duration(milliseconds: 50),
      intensity: 0.6,
    ),
    this.physics = const FixedExtentScrollPhysics(),
    this.controller,
  }) : children = null;

  /// The height of each item in the wheel.
  final double itemExtent;

  /// Called whenever the selected item changes.
  final ValueChanged<int> onSelectedItemChanged;

  /// The child widgets when provided directly.
  final List<Widget>? children;

  /// The total number of items.
  final int itemCount;

  /// The initial selected index.
  final int initialIndex;

  /// An optional scroll controller for programmatic scrolling.
  final FixedExtentScrollController? scrollController;

  /// The relative diameter of the wheel (cylinder radius).
  final double diameterRatio;

  /// 3D perspective effect.
  final double perspective;

  /// Magnification factor for the center selected item.
  final double magnification;

  /// Whether to apply magnification to the center selected item.
  final bool useMagnifier;

  /// The tactile action triggered for normal item index ticks.
  final HapticStep detentStep;

  /// The tactile action triggered when reaching the start or end index.
  final HapticStep boundaryStep;

  /// The scroll physics applied to the wheel.
  final ScrollPhysics physics;

  /// An optional dedicated [HapticFlowController]. If null, [HapticFlow.playStep] is used.
  final HapticFlowController? controller;

  /// An optional builder function for lazy item generation.
  final NullableIndexedWidgetBuilder? itemBuilder;

  @override
  State<HapticPickerWheel> createState() => _HapticPickerWheelState();
}

class _HapticPickerWheelState extends State<HapticPickerWheel> {
  late FixedExtentScrollController _scrollController;
  late int _lastIndex;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.initialIndex;
    _scrollController = widget.scrollController ??
        FixedExtentScrollController(initialItem: widget.initialIndex);
  }

  @override
  void didUpdateWidget(HapticPickerWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != oldWidget.scrollController &&
        widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _triggerHaptic(HapticStep step) {
    if (widget.controller != null) {
      widget.controller!.playStep(step);
    } else {
      HapticFlow.playStep(step);
    }
  }

  void _handleSelectedItemChanged(int index) {
    if (index != _lastIndex) {
      final isBoundary = index == 0 || index == widget.itemCount - 1;
      final step = isBoundary ? widget.boundaryStep : widget.detentStep;
      _triggerHaptic(step);
      _lastIndex = index;
    }
    widget.onSelectedItemChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: _scrollController,
      itemExtent: widget.itemExtent,
      diameterRatio: widget.diameterRatio,
      perspective: widget.perspective,
      magnification: widget.magnification,
      useMagnifier: widget.useMagnifier,
      physics: widget.physics,
      onSelectedItemChanged: _handleSelectedItemChanged,
      childDelegate: widget.children != null
          ? ListWheelChildListDelegate(children: widget.children!)
          : ListWheelChildBuilderDelegate(
              builder: widget.itemBuilder ??
                  (context, index) {
                    if (index < 0 || index >= widget.itemCount) return null;
                    return Center(
                      child: Text(
                        'Item $index',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    );
                  },
              childCount: widget.itemCount,
            ),
    );
  }
}
