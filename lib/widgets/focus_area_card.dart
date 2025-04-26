import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class FocusAreaCard extends StatelessWidget {
  final String focusArea;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool showTodayText;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  const FocusAreaCard({
    Key? key,
    required this.focusArea,
    this.margin,
    this.padding,
    this.showTodayText = true,
    this.borderColor,
    this.textColor,
    this.iconBackgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light ? myGrey10 : myGrey80,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor ?? (theme.brightness == Brightness.light ? myBlue60 : myGrey70),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? (theme.brightness == Brightness.light ? myBlue20 : myGrey70),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.track_changes_outlined,
                color: iconColor ?? (theme.brightness == Brightness.light ? myBlue60 : Colors.white),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showTodayText)
                    Text(
                      'TODAY\'S FOCUS',
                      style: GoogleFonts.plusJakartaSans(
                        color: textColor ?? (theme.brightness == Brightness.light ? myBlue60 : Colors.white),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  if (showTodayText)
                    const SizedBox(height: 4),
                  Text(
                    focusArea,
                    style: GoogleFonts.plusJakartaSans(
                      color: textColor ?? (theme.brightness == Brightness.light ? myBlue60 : Colors.white),
                      fontSize: 20,
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