 import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

enum SnackBarType { error, success, warning, info }

class CustomSnackBar {
  static SnackBar show({
    required String title,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    Color getIconColor() {
      switch (type) {
        case SnackBarType.error:
          return myRed60;
        case SnackBarType.success:
          return myGreen60;
        case SnackBarType.warning:
          return myYellow60;
        case SnackBarType.info:
          return myBlue60;
      }
    }

    IconData getIcon() {
      switch (type) {
        case SnackBarType.error:
          return Icons.error_outline;
        case SnackBarType.success:
          return Icons.check_circle_outline;
        case SnackBarType.warning:
          return Icons.warning_amber_rounded;
        case SnackBarType.info:
          return Icons.info_outline;
      }
    }

    return SnackBar(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      content: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: myGrey90,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: getIconColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                getIcon(),
                color: getIconColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Builder(
              builder: (context) => IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.close,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          ],
        ),
      ),
      duration: duration,
      behavior: SnackBarBehavior.floating,
    );
  }
}