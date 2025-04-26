import 'package:naturafit/services/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:provider/provider.dart';

class CustomTimePicker {
  static Future<TimeOfDay?> show({
    required BuildContext context,
    TimeOfDay? initialTime,
  }) async {
    final theme = Theme.of(context);
    

    return showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        final userData = context.read<UserProvider>().userData;
        final timeFormat = userData?['timeFormat'] as String? ?? '12-hour';
        final use24HourFormat = timeFormat == '24-hour';

        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: theme.brightness == Brightness.light ? Colors.white : myGrey90,
              hourMinuteTextColor: myBlue60,
              dayPeriodTextColor: myBlue60,
              dialHandColor: myBlue60,
              dialBackgroundColor: myBlue60.withOpacity(0.1),
              hourMinuteColor: myBlue60.withOpacity(0.1),
              dayPeriodColor: myBlue60.withOpacity(0.1),
              entryModeIconColor: myBlue60,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: myBlue60,
              ),
            ),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: use24HourFormat,
            ),
            child: child!,
          ),
        );
      },
    );
  }
} 