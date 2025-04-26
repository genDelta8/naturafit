import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'dart:math' as math;

class CustomStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String stepName;
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;

  const CustomStepIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepName,
    this.size,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultSize = screenWidth > 600 ? 60.0 : screenWidth * 0.10;
    final actualSize = size ?? defaultSize;

    const baseColor = myTeal40;
    const fadeColor = myTeal30;
    const trackColor = myTeal30;
    const loadColor = Colors.white;

    return Container(
      constraints: BoxConstraints(
        maxWidth: 120,
        maxHeight: 120,
      ),
      width: actualSize * 1.6,
      height: actualSize * 1.6,
      decoration: BoxDecoration(
        color: fadeColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              stepName,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: actualSize * 0.25,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(
              width: actualSize * 0.5,
              height: actualSize * 0.5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: actualSize * 0.5,
                    height: actualSize * 0.5,
                    child: CircularProgressIndicator(
                      value: currentStep / totalSteps,
                      color: loadColor,
                      backgroundColor: trackColor,
                      strokeWidth: 3,
                    ),
                  ),
                  Text(
                    '${totalSteps - currentStep}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: actualSize * 0.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
