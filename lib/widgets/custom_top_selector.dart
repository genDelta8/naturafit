import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class TopSelectorOption {
  final String title;
  final String? subtitle;

  TopSelectorOption({
    required this.title,
    this.subtitle,
  });
}

class CustomTopSelector extends StatelessWidget {
  final List<TopSelectorOption> options;
  final int selectedIndex;
  final Function(int) onOptionSelected;

  const CustomTopSelector({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onOptionSelected(index),
              child: Container(
                margin: EdgeInsets.only(
                  left: index == 0 ? 8 : 4,
                  right: index == options.length - 1 ? 8 : 4,
                ),
                decoration: BoxDecoration(
                  color: selectedIndex == index 
                      ? (isDark ? myGrey70 : myGrey30)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selectedIndex == index 
                        ? (isDark ? myGrey100 : myGrey90)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    option.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: selectedIndex == index 
                          ? Colors.white
                          : theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
} 