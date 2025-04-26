import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class RectangularSliderThumb extends SliderComponentShape {
  final double width;
  final double height;
  final double radius;

  const RectangularSliderThumb({
    this.width = 48,
    this.height = 48,
    this.radius = 12,
  });

  @override
  void paint(
    PaintingContext context,
    Offset center,
    {
      required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow,
    }
  ) {
    final Canvas canvas = context.canvas;

    // Draw background shadow rectangle
    final shadowRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: width + 8, // Slightly wider
        height: height + 8, // Slightly taller
      ),
      Radius.circular(radius + 2),
    );

    canvas.drawRRect(
      shadowRRect,
      Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..style = PaintingStyle.fill,
    );

    // Draw main thumb
    final thumbRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      ),
      Radius.circular(radius),
    );

    canvas.drawRRect(
      thumbRRect,
      Paint()
        ..color = sliderTheme.thumbColor ?? Colors.white
        ..style = PaintingStyle.fill,
    );

    // Draw forward icon
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final iconSize = 16.0;
    final startX = center.dx - iconSize / 4 - 3;
    final startY = center.dy - iconSize / 2;

    // Draw first arrow
    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX + iconSize / 2, startY + iconSize / 2),
      iconPaint,
    );
    canvas.drawLine(
      Offset(startX + iconSize / 2, startY + iconSize / 2),
      Offset(startX, startY + iconSize),
      iconPaint,
    );

    // Draw second arrow (slightly offset)
    canvas.drawLine(
      Offset(startX + iconSize / 2, startY),
      Offset(startX + iconSize, startY + iconSize / 2),
      iconPaint,
    );
    canvas.drawLine(
      Offset(startX + iconSize, startY + iconSize / 2),
      Offset(startX + iconSize / 2, startY + iconSize),
      iconPaint,
    );
  }

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(width + 0, height + 0);
  }
}

class CustomTrackShape extends RectangularSliderTrackShape {
  final double radius;
  const CustomTrackShape({this.radius = 8});

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    final Canvas canvas = context.canvas;
    final trackHeight = sliderTheme.trackHeight;

    final trackRect = Rect.fromLTWH(
      offset.dx,
      offset.dy + (parentBox.size.height - trackHeight!) / 2,
      parentBox.size.width,
      trackHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(trackRect.left, trackRect.top, thumbCenter.dx, trackRect.bottom),
        topLeft: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
      ),
      Paint()..color = sliderTheme.activeTrackColor!,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(thumbCenter.dx, trackRect.top, trackRect.right, trackRect.bottom),
        topRight: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
      ),
      Paint()..color = sliderTheme.inactiveTrackColor!,
    );
  }
}

class CustomFitnessLevelSlider extends StatefulWidget {
  final String initialLevel;
  final Function(String) onLevelChanged;
  final bool isDifficultySlider;
  final bool shouldDisable;

  const CustomFitnessLevelSlider({
    Key? key,
    required this.initialLevel,
    required this.onLevelChanged,
    this.isDifficultySlider = false,
    this.shouldDisable = false,
  }) : super(key: key);

  @override
  State<CustomFitnessLevelSlider> createState() => _CustomFitnessLevelSliderState();
}

class _CustomFitnessLevelSliderState extends State<CustomFitnessLevelSlider> {
  late double _sliderValue;
  final List<Map<String, dynamic>> _difficultyLevels = [
    {'level': 'Level 1', 'description': 'Very Easy'},
    {'level': 'Level 2', 'description': 'Easy'},
    {'level': 'Level 3', 'description': 'Moderate'},
    {'level': 'Level 4', 'description': 'Hard'},
    {'level': 'Level 5', 'description': 'Very Hard'},
  ];

  final List<Map<String, dynamic>> _fitnessLevels = [
    {'level': 'Level 1', 'description': '0-1× Exercise/Week'},
    {'level': 'Level 2', 'description': '1-2× Exercise/Week'},
    {'level': 'Level 3', 'description': '2-3× Exercise/Week'},
    {'level': 'Level 4', 'description': '3-4× Exercise/Week'},
    {'level': 'Level 5', 'description': '4-5× Exercise/Week'},
  ];

  List<Map<String, dynamic>> get _levels => 
      widget.isDifficultySlider ? _difficultyLevels : _fitnessLevels;

  @override
  void initState() {
    super.initState();
    _sliderValue = _getLevelIndex(widget.initialLevel).toDouble();
  }

  int _getLevelIndex(String level) {
    return int.parse(level.split(' ')[1]) - 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _levels[_sliderValue.round()]['level'],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.brightness == Brightness.light ? myGrey90 : Colors.grey[400],
              ),
            ),
            Text(
              _levels[_sliderValue.round()]['description'],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: theme.brightness == Brightness.light ? Colors.black : Colors.grey[400],
              ),
            ),
          ],
        ),
        const SizedBox(height: 0),
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              
              // Slider
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 48,
                  activeTrackColor: myGrey80.withOpacity(0.5),
                  inactiveTrackColor: Colors.white,
                  thumbColor: myGrey80,
                  thumbShape: const RectangularSliderThumb(width: 48, height: 48, radius: 12),
                  overlayColor: Colors.transparent,
                  overlayShape: SliderComponentShape.noOverlay,
                  trackShape: const CustomTrackShape(radius: 12),
                  rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Slider(
                    value: _sliderValue,
                    min: 0,
                    max: 4,
                    divisions: 4,
                    onChanged: widget.shouldDisable ? null : (value) {
                      setState(() {
                        _sliderValue = value;
                      });
                      widget.onLevelChanged(_levels[value.round()]['description']);
                    },
                  ),
                ),
              ),
              // Level indicators
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    5,
                    (index) => Container(
                      width: 3,
                      height: 24,
                      color: (index == _sliderValue) ? Colors.transparent : (index < _sliderValue) ? myGrey60 : myGrey30,
                    ),
                  ),
                ),
              ),
              // Level numbers
              /*
              Positioned(
                bottom: 4,
                left: 24,
                right: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    5,
                    (index) => Text(
                      (index + 1).toString(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: index <= _sliderValue ? myBlue60 : myGrey60,
                      ),
                    ),
                  ),
                ),
              ),
              */
            ],
          ),
        ),
      ],
    );
  }
} 