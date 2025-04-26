import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class CustomLoadingBarView extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String status;
  final Color? color;

  const CustomLoadingBarView({
    super.key,
    required this.progress,
    required this.status,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: myGrey90.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Loading...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                color: myGrey10,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250,
                  height: 10,
                  decoration: BoxDecoration(
                    color: myGrey10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(
                  width: 250 * progress,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color ?? myBlue30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Container(
                        height: 10,
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: color ?? myBlue60,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                color: myGrey10,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
            
            const SizedBox(height: 8),
            Text(
              status,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: myGrey10,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
