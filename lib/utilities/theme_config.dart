import 'package:flutter/material.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConfig {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: myGrey10,
    primaryColor: myBlue60,
    cardColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: myGrey10,
      elevation: 0,
      iconTheme: const IconThemeData(color: myGrey90),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: myGrey90,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.plusJakartaSans(color: myGrey90),
      bodyMedium: GoogleFonts.plusJakartaSans(color: myGrey80),
      labelLarge: GoogleFonts.plusJakartaSans(color: myGrey90),
      titleMedium: GoogleFonts.plusJakartaSans(color: myGrey90),
      titleSmall: GoogleFonts.plusJakartaSans(color: myGrey70),
    ),
    iconTheme: const IconThemeData(color: myGrey80),
    dividerColor: myGrey20,
    shadowColor: myGrey30.withOpacity(0.2),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: myGrey100,
    primaryColor: myBlue60,
    cardColor: myGrey90,
    appBarTheme: AppBarTheme(
      backgroundColor: myGrey100,
      elevation: 0,
      iconTheme: const IconThemeData(color: myGrey10),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: myGrey10,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.plusJakartaSans(color: myGrey10),
      bodyMedium: GoogleFonts.plusJakartaSans(color: myGrey20),
      labelLarge: GoogleFonts.plusJakartaSans(color: myGrey10),
      titleMedium: GoogleFonts.plusJakartaSans(color: myGrey10),
      titleSmall: GoogleFonts.plusJakartaSans(color: myGrey30),
    ),
    iconTheme: const IconThemeData(color: myGrey20),
    dividerColor: myGrey80,
    shadowColor: myGrey100.withOpacity(0.5),
  );
} 