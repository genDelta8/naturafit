import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomGenderPicker extends StatelessWidget {
  final String selectedGender;
  final Function(String) onGenderSelected;

  const CustomGenderPicker({
    Key? key,
    required this.selectedGender,
    required this.onGenderSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    
    return Row(
      children: [
        _buildGenderCard(
          context: context,
          gender: 'Male',
          icon: Icons.male,
          label: l10n.i_am_male,
          color: Colors.blue,
          isWideScreen: isWideScreen,
          isDark: isDark,
          theme: theme,
        ),
        const SizedBox(width: 16),
        _buildGenderCard(
          context: context,
          gender: 'Female',
          icon: Icons.female,
          label: l10n.i_am_female,
          color: Colors.pink,
          isWideScreen: isWideScreen,
          isDark: isDark,
          theme: theme,
        ),
        const SizedBox(width: 16),
        _buildGenderCard(
          context: context,
          gender: 'Other',
          icon: Icons.transgender,
          label: l10n.other,
          color: Colors.purple,
          isWideScreen: isWideScreen,
          isDark: isDark,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildGenderCard({
    required BuildContext context,
    required String gender,
    required IconData icon,
    required String label,
    required Color color,
    required bool isWideScreen,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => onGenderSelected(
            selectedGender == gender ? 'Not Specified' : gender),
        child: Container(
          padding: EdgeInsets.all(isWideScreen ? 24 : 16),
          decoration: BoxDecoration(
            color: selectedGender == gender ? color : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selectedGender == gender
                  ? color
                  : isDark ? myGrey80 : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: isWideScreen ? 64 : 48,
                color: selectedGender == gender ? Colors.white : color,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: selectedGender == gender
                      ? Colors.white
                      : theme.textTheme.bodyLarge?.color,
                  fontSize: isWideScreen ? 14 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 