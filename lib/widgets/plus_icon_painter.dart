import 'package:flutter/material.dart';

class PlusIconPainter extends CustomPainter {
  final Color color;
  
  PlusIconPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Horizontal line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Top curved line
    final topPath = Path()
      ..moveTo(size.width * 0.6, 0)  // Start from 60% of width
      ..quadraticBezierTo(
        size.width * 0.5,  // Control point
        size.height * 0.5, // Middle height
        size.width,        // End at right edge
        size.height * 0.5, // Middle height
      );

    // Bottom curved line
    final bottomPath = Path()
      ..moveTo(size.width * 0.6, size.height)  // Start from 60% of width
      ..quadraticBezierTo(
        size.width * 0.5,    // Control point
        size.height * 0.5,   // Middle height
        size.width,          // End at right edge
        size.height * 0.5,   // Middle height
      );

    canvas.drawPath(topPath, paint);
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 