import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomSingleSpinner<T> extends StatefulWidget {
  final T initialValue;
  final List<T> values;
  final double itemWidth;
  final double itemHeight;
  final Function(T)? onValueChanged;
  final String Function(T)? textMapper;
  final TextStyle? textStyle;

  const CustomSingleSpinner({
    Key? key,
    required this.initialValue,
    required this.values,
    required this.itemWidth,
    this.itemHeight = 50,
    this.onValueChanged,
    this.textMapper,
    this.textStyle,
  }) : super(key: key);

  @override
  State<CustomSingleSpinner<T>> createState() => _CustomSingleSpinnerState<T>();
}

class _CustomSingleSpinnerState<T> extends State<CustomSingleSpinner<T>> {
  late FixedExtentScrollController _controller;
  late int initialIndex;

  @override
  void initState() {
    super.initState();
    initialIndex = widget.values.indexOf(widget.initialValue);
    _controller = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getDisplayText(T value) {
    if (widget.textMapper != null) {
      return widget.textMapper!(value);
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        


        // Center indicator
        Positioned.fill(
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: myBlue30,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                height: widget.itemHeight,
                width: widget.itemWidth * 0.7,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: myBlue60,
                  
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        // Spinner
        ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: widget.itemHeight,
          perspective: 0.005,
          diameterRatio: 1.5,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            if (widget.onValueChanged != null) {
              widget.onValueChanged!(widget.values[index]);
            }
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.values.length,
            builder: (context, index) {
              final isSelected = index == _controller.selectedItem;
              return Container(
                width: widget.itemWidth,
                alignment: Alignment.center,
                child: Text(
                  _getDisplayText(widget.values[index]),
                  style: (widget.textStyle ?? GoogleFonts.plusJakartaSans()).copyWith(
                    fontSize: isSelected ? 18 : 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
