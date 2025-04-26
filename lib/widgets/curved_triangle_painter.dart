import 'package:flutter/material.dart';

class CurvedTriangle extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final bool flipHorizontally;

  const CurvedTriangle({
    Key? key,
    this.width = 200,
    this.height = 200,
    this.color = Colors.black,
    this.flipHorizontally = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: CurvedTrianglePainter(
        color: color,
        flipHorizontally: flipHorizontally,
      ),
    );
  }
}

class CurvedTrianglePainter extends CustomPainter {
  final Color color;
  final bool flipHorizontally;

  CurvedTrianglePainter({
    required this.color,
    required this.flipHorizontally,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    if (flipHorizontally) {
      path
        ..moveTo(size.width, 0) // Start from top-right
        ..lineTo(0, 0) // Draw line to top-left
        ..quadraticBezierTo(
          size.width * 1, // Control point x
          size.height * 0, // Control point y
          size.width, // End point x
          size.height, // End point y
        ); // Draw curved line to bottom-right
    } else {
      path
        ..moveTo(0, 0) // Start from top-left
        ..lineTo(size.width, 0) // Draw line to top-right
        ..quadraticBezierTo(
          size.width * 0, // Control point x
          size.height * 0, // Control point y
          0, // End point x
          size.height, // End point y
        ); // Draw curved line to bottom-left
    }
    
    path.close(); // Close the path to complete the triangle
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 