import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class CustomConsentCheckbox extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final Function(bool) onChanged;
  final IconData icon;

  const CustomConsentCheckbox({
    Key? key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        
        decoration: BoxDecoration(
          color: value ? myBlue30 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          
        ),
        
        child: Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: value ? myBlue60 : theme.brightness == Brightness.light ? Colors.white : myGrey80,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value ? myBlue60 : myGrey20,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: value ? Colors.white : theme.brightness == Brightness.light ? myGrey60 : myGrey40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: value ? Colors.white : theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: value ? Colors.white : theme.brightness == Brightness.light ? Colors.white : myGrey80,
                  border: Border.all(
                    color: value ? Colors.transparent : theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                    width: 2,
                  ),
                ),
                child: value
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: myBlue60,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 