import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/measurement_converter.dart';
import 'package:flutter/gestures.dart';

class CustomMeasurePicker extends StatefulWidget {
  final String title;
  final double initialValue;
  final String initialUnit;
  final List<String> units;
  final Function(double, String) onChanged;
  final double markerHeight;
  final Color lineColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;

  const CustomMeasurePicker({
    Key? key,
    required this.title,
    required this.initialValue,
    required this.initialUnit,
    required this.units,
    required this.onChanged,
    this.markerHeight = 32.0,
    this.lineColor = const Color(0xFF2563EB),
    this.selectedTextColor = const Color(0xFF2563EB),
    this.unselectedTextColor = const Color(0xFF94A3B8),
  }) : super(key: key);

  @override
  State<CustomMeasurePicker> createState() => _CustomMeasurePickerState();
}

class _CustomMeasurePickerState extends State<CustomMeasurePicker> {
  late ScrollController _scrollController;
  late double _currentValue;
  late String _currentUnit;
  final double _itemWidth = 40.0;
  late double _baseValue; // Stores the value in base unit for conversions


  final GlobalKey _redContainerKey = GlobalKey();
  double _leftWhiteSpace = 0.0;


  void _measureWhiteSpace() {
    final RenderBox? renderBox = _redContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      setState(() {
        _leftWhiteSpace = position.dx;
        debugPrint('Left White Space: $_leftWhiteSpace');
      });
    }
  }



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureWhiteSpace());
    _currentUnit = widget.initialUnit;
    _currentValue = widget.initialValue;
    _baseValue = MeasurementConverter.toBase(_currentValue, _currentUnit);
    _initializeScrollController();
  }

  void _initializeScrollController() {
    final unitRange = MeasurementConverter.unitRanges[_currentUnit]!;
    final initialOffset = (_currentValue - unitRange['min']!) /
        unitRange['interval']! *
        _itemWidth;

    _scrollController = ScrollController(
      initialScrollOffset: initialOffset,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final unitRange = MeasurementConverter.unitRanges[_currentUnit]!;
    final value = unitRange['min']! +
        (_scrollController.offset / _itemWidth) * unitRange['interval']!;

    if (value != _currentValue) {
      setState(() {
        _currentValue = value;
        _baseValue = MeasurementConverter.toBase(value, _currentUnit);
        widget.onChanged(_currentValue, _currentUnit);
      });
    }
  }

  void _changeUnit(String newUnit) {
    if (newUnit == _currentUnit) return;

    final oldValue = _currentValue;
    final baseValue = MeasurementConverter.toBase(oldValue, _currentUnit);
    final newValue = MeasurementConverter.fromBase(baseValue, newUnit);

    setState(() {
      _currentUnit = newUnit;
      _currentValue = newValue;
    });

    // Update scroll position for new unit
    final unitRange = MeasurementConverter.unitRanges[_currentUnit]!;
    final newOffset = (_currentValue - unitRange['min']!) /
        unitRange['interval']! *
        _itemWidth;

    _scrollController.jumpTo(newOffset);
    widget.onChanged(_currentValue, _currentUnit);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final unitRange = MeasurementConverter.unitRanges[_currentUnit]!;
    final measurePickerWidth = screenWidth * 0.9;
    final theme = Theme.of(context);

    // Add these scroll behavior settings
    final scrollBehavior = ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${widget.title}:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                ),
              ),
            ),

            //const SizedBox(width: 0),

            // Unit Selector
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.units.map((unit) {
                  final isSelected = unit == _currentUnit;
                  return GestureDetector(
                    onTap: () => _changeUnit(unit),
                    child: Container(
                      width: 80,
                      height: 40,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? myGrey90 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? myGrey40 : myGrey20,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          unit,
                          style: GoogleFonts.plusJakartaSans(
                            color: isSelected ? Colors.white : myGrey80,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),

        // Large Number Display
        Container(
          margin: const EdgeInsets.only(bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currentValue.toStringAsFixed(1), // Always show one decimal place
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _currentUnit,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.light ? myGrey70 : myGrey40,
                ),
              ),
            ],
          ),
        ),

        // Measure Picker
        SizedBox(
          width: double.infinity,
          child: Center(
            child: Container(
              key: _redContainerKey,
              height: 130,
              width: screenWidth * 0.9,
              margin: const EdgeInsets.only(bottom: 16),
              child: Stack(
                children: [
                  // Temporary center line guide
                  /*
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 1,
                        height: 130,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  */
            
                  // Center indicator
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_drop_down,
                          color: widget.lineColor,
                          size: 24,
                        ),
                        CustomPaint(
                          size: Size(8, widget.markerHeight * 2.5),
                          painter: IndicatorPainter(color: widget.lineColor),
                        ),
                        Icon(
                          Icons.arrow_drop_up,
                          color: widget.lineColor,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  ScrollConfiguration(
                    behavior: scrollBehavior,
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: (measurePickerWidth / 2) - (_itemWidth / 2),
                      ),
                      itemCount: ((unitRange['max']! - unitRange['min']!) /
                                  unitRange['interval']!)
                              .ceil() +
                          1,
                      itemBuilder: (context, index) {
                        final value =
                            unitRange['min']! + (index * unitRange['interval']!);
                        final isSelected = (value - _currentValue).abs() <
                            unitRange['interval']! / 2;
                
                        return SizedBox(
                          width: _itemWidth,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 2,
                                height: index % 5 == 0
                                    ? widget.markerHeight
                                    : widget.markerHeight / 2,
                                color: isSelected
                                    ? widget.lineColor
                                    : widget.unselectedTextColor,
                              ),
                              if (index % 5 == 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    value.toStringAsFixed(
                                        unitRange['interval']! < 1 ? 1 : 0),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isSelected
                                          ? widget.selectedTextColor
                                          : widget.unselectedTextColor,
                                      fontSize: isSelected ? 16 : 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class IndicatorPainter extends CustomPainter {
  final Color color;

  IndicatorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2 - 3, 0)
      ..lineTo(size.width / 2 + 3, 0)
      ..lineTo(size.width / 2 + 1, size.height)
      ..lineTo(size.width / 2 - 1, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
