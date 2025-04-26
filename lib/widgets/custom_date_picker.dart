import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class CustomDatePicker {
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final theme = Theme.of(context);
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime.now(),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: myBlue60, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: theme.brightness == Brightness.light ? Colors.black : Colors.white, // Calendar text color
              surface: theme.brightness == Brightness.light ? Colors.white : myGrey80, // Calendar background color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: myBlue60, // Button text color
              ),
            ),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          child: child!,
        );
      },
    );
  }
} 