import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class WeightGoalIndicator extends StatelessWidget {
  final double goalWeight;
  final String unit;
  final double progress;

  const WeightGoalIndicator({
    super.key,
    required this.goalWeight,
    required this.unit,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: Container(
          //color: Colors.red,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Weight loss Goal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loss: ${goalWeight.toStringAsFixed(0)}$unit/Month',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Stack(
                //alignment: Alignment.center,
                children: [
                  Container(
                    child: Center(
                      child: SizedBox(
                        height: 130,
                        width: 130,
                        child: ClipRect(
                          clipper: SemiCircleClipper(),
                          child: Transform.rotate(
                            angle: 3.14159 + 1.5708, // 180 + 90 degrees in radians (pi + pi/2)
                            child: CircularProgressIndicator(
                              value: (0 / goalWeight) * 0.5,
                              strokeWidth: 20,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(myBlue60),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Transform.rotate(
                      angle: - 0.5 * math.pi + (0 / goalWeight) * math.pi, // Start from bottom and rotate based on progress
                      child: Column(
                        children: [
                          CustomPaint(
                          size: const Size(20, 130),
                            painter: NeedlePainter(),
                          ),
                          //const SizedBox(height: 50),
                          
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SemiCircleClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    // Add extra padding for the stroke width
    return Rect.fromLTWH(
      -10, // Negative offset to show full stroke width on left
      -10,
      size.width + 40, // Add stroke width to both sides
      size.height / 2
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}

class NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2 - 4, size.height - 5); // Bottom left
    path.lineTo(size.width / 2 + 4, size.height - 5); // Bottom right
    path.lineTo(size.width / 2, 0); // Top point
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 


