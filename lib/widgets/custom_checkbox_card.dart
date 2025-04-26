import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class CustomCheckboxCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? leading;

  const CustomCheckboxCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? myBlue30 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? myBlue60 : theme.brightness == Brightness.light ? Colors.white : myGrey80,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 3,
            ),
            leading: leading,
            onTap: onTap,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isSelected ? myGrey10 : theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                    ),
                  ),
              ],
            ),
            trailing: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : theme.brightness == Brightness.light ? Colors.white : myGrey80,
                border: Border.all(
                  color: isSelected ? Colors.transparent : theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 15,
                      color: myBlue60,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}