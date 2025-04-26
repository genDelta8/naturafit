import 'package:naturafit/utilities/platform_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WorkoutCountdownView extends StatelessWidget {
  final int countDown;

  const WorkoutCountdownView({
    super.key,
    required this.countDown,
  });

  @override
  Widget build(BuildContext context) {
    const myBackground = myRed60;
    final myIsWebOrDektop = isWebOrDesktopCached;
    final isWeb = myIsWebOrDektop;

    return Scaffold(
      backgroundColor: myBackground,
      body: isWeb ? countdownForWeb(context) : countdownForMobile(context),
    );
  }

  Widget countdownForMobile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final generateSize = screenWidth * 0.175;
    final generateLargerPadding = screenWidth * 0.085;
    final fadeRadius = screenWidth * 0.075;
    const baseColor = myRed20;
    
    return Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: baseColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(fadeRadius * 3.5),
                      ),
                      child: Container(
                        margin: EdgeInsets.all(generateLargerPadding),
                        decoration: BoxDecoration(
                          color: baseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(fadeRadius * 2.5),
                        ),
                        child: Container(
                          margin: EdgeInsets.all(generateLargerPadding),
                          decoration: BoxDecoration(
                            color: baseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(fadeRadius * 2),
                          ),
                          child: Container(
                            margin: EdgeInsets.all(generateLargerPadding),
                            decoration: BoxDecoration(
                              color: baseColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(fadeRadius * 1.5),
                            ),
                            child: Container(
                              width: generateSize * 1.5,
                              height: generateSize * 1.5,
                              margin: EdgeInsets.all(generateLargerPadding),
                              decoration: BoxDecoration(
                                color: baseColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(fadeRadius),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Center(
            child: Text(
              countDown > 0 ? countDown.toString() : l10n.go,
              style: GoogleFonts.plusJakartaSans(
                fontSize: countDown > 0 ? 120 : 80,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    
  }


  Widget countdownForWeb(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenArea = screenWidth * screenHeight;
    final generateSize = screenArea * 0.0001;
    final generateLargerPadding = screenArea * 0.00005;
    final fadeRadius = screenArea * 0.000025;
    const baseColor = myRed20;

    final numberSize = screenArea * 0.0002;
    final goSize = screenArea * 0.0001;
    
    return Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: baseColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(fadeRadius * 3.5),
                      ),
                      child: Container(
                        margin: EdgeInsets.all(generateLargerPadding),
                        decoration: BoxDecoration(
                          color: baseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(fadeRadius * 2.5),
                        ),
                        child: Container(
                          margin: EdgeInsets.all(generateLargerPadding),
                          decoration: BoxDecoration(
                            color: baseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(fadeRadius * 2),
                          ),
                          child: Container(
                            margin: EdgeInsets.all(generateLargerPadding),
                            decoration: BoxDecoration(
                              color: baseColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(fadeRadius * 1.5),
                            ),
                            child: Container(
                              width: generateSize * 1.5,
                              height: generateSize * 1.5,
                              margin: EdgeInsets.all(generateLargerPadding),
                              decoration: BoxDecoration(
                                color: baseColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(fadeRadius),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Center(
            child: Text(
              countDown > 0 ? countDown.toString() : l10n.go,
              style: GoogleFonts.plusJakartaSans(
                fontSize: countDown > 0 ? numberSize : goSize,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    
  }
} 