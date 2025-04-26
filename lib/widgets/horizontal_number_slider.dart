import 'dart:math';

import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HorizontalNumberSlider extends StatefulWidget {
  final Function(int) onValueChanged;
  final int minValue;
  final int maxValue;
  final int initialValue;
  final String? title;

  const HorizontalNumberSlider({
    super.key,
    required this.onValueChanged,
    this.minValue = 1,
    this.maxValue = 24,
    this.initialValue = 1,
    this.title,
  });

  @override
  State<HorizontalNumberSlider> createState() => _HorizontalNumberSliderState();
}

class _HorizontalNumberSliderState extends State<HorizontalNumberSlider> {
  final GlobalKey _redContainerKey = GlobalKey();
  double _leftWhiteSpace = 0.0;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _isDragging = false;
  double? _dragStartX;
  double _dragStartOffset = 0.0;

  void _measureWhiteSpace() {
    final RenderBox? renderBox = _redContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      setState(() {
        _leftWhiteSpace = position.dx;
      });
    }
  }

  double _getDistanceScale(int index, double centerPosition) {
    final distance = (index * 60 - centerPosition).abs();
    return 1.0 - (distance / 180).clamp(0.0, 0.5);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureWhiteSpace();
      // Scroll to initial value
      _scrollController.jumpTo((widget.initialValue - widget.minValue) * 60.0);
    });
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
      // Calculate and notify the current value
      final currentValue = widget.minValue + (_scrollOffset / 60.0).round();
      widget.onValueChanged(currentValue);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleDragStart(double x) {
    _isDragging = true;
    _dragStartX = x;
    _dragStartOffset = _scrollController.offset;
  }

  void _handleDragUpdate(double x) {
    if (_isDragging && _dragStartX != null) {
      final delta = _dragStartX! - x;
      _scrollController.jumpTo((_dragStartOffset + delta).clamp(
        0.0,
        (widget.maxValue - widget.minValue) * 60.0,
      ));
    }
  }

  void _handleDragEnd() {
    if (_isDragging) {
      _isDragging = false;
      _dragStartX = null;
      
      // Snap to nearest number
      final targetIndex = (_scrollController.offset / 60.0).round();
      _scrollController.animateTo(
        targetIndex * 60.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidthMobile = screenWidth * 0.8;
    final barWidthWeb = min(screenWidth * 0.8, 580);
    final myIsWebOrDektop = isWebOrDesktopCached;
    final barWidth = (myIsWebOrDektop ? barWidthWeb : barWidthMobile).toDouble();
    final theme = Theme.of(context);

    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.title!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.light ? myGrey80 : myGrey20,
                  ),
                ),
              ),
            
            MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: GestureDetector(
                onHorizontalDragStart: (details) => _handleDragStart(details.globalPosition.dx),
                onHorizontalDragUpdate: (details) => _handleDragUpdate(details.globalPosition.dx),
                onHorizontalDragEnd: (_) => _handleDragEnd(),
                child: Container(
                  width: barWidth,
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: myGrey20, width: 1),
                  ),
                  key: _redContainerKey,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Indicator Box
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: myBlue30,  // Subtle white background
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Container(  // Inner container with blue background
                              margin: const EdgeInsets.all(3),  // Space for the "border" effect
                              decoration: BoxDecoration(
                                color: myBlue60,
                                borderRadius: BorderRadius.circular(6),  // Slightly smaller radius
                              ),
                            ),
                          ),
                        ),
                      ),
            
                      SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        physics: _SnapScrollPhysics(
                          parent: const BouncingScrollPhysics(),
                          itemWidth: 60,
                          maxValue: widget.maxValue,
                          minValue: widget.minValue,
                        ),
                        child: SizedBox(
                          height: 60,
                          child: Row(
                            children: [
                              SizedBox(width: (barWidth) / 2 - 30),
                              ...List.generate(
                                widget.maxValue - widget.minValue + 1,
                                (index) {
                                  final number = widget.minValue + index;
                                  final scale = _getDistanceScale(index, _scrollOffset);
                                  final isCenter = (index * 60 - _scrollOffset).abs() < 30;
                                  
                                  return SizedBox(
                                    width: 60,
                                    child: Center(
                                      child: Transform.scale(
                                        scale: scale,
                                        child: Text(
                                          number.toString(),
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w800,
                                            color: isCenter 
                                              ? Colors.white
                                              : theme.brightness == Brightness.light ? myGrey90.withOpacity(scale) : myGrey20.withOpacity(scale),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: (barWidth) / 2 - 30),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SnapScrollPhysics extends ScrollPhysics {
  final double itemWidth;
  final int maxValue;
  final int minValue;
  
  const _SnapScrollPhysics({
    ScrollPhysics? parent,
    required this.itemWidth,
    required this.maxValue,
    required this.minValue,
  }) : super(parent: parent);

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SnapScrollPhysics(
      parent: buildParent(ancestor),
      itemWidth: itemWidth,
      maxValue: maxValue,
      minValue: minValue,
    );
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final tolerance = this.tolerance;
    final target = _getTargetPixels(position, tolerance, velocity);
    
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  double _getTargetPixels(ScrollMetrics position, Tolerance tolerance, double velocity) {
    final itemIndex = (position.pixels / itemWidth).round();
    final boundedIndex = itemIndex.clamp(0, maxValue - minValue);
    final targetNumber = boundedIndex + 1;
    return boundedIndex * itemWidth;
  }
} 