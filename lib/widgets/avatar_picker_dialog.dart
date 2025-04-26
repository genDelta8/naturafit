import 'package:naturafit/widgets/custom_top_selector.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AvatarPickerDialog extends StatefulWidget {
  final Function(String) onAvatarSelected;

  const AvatarPickerDialog({
    Key? key,
    required this.onAvatarSelected,
  }) : super(key: key);

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<TopSelectorOption> _options = [
    TopSelectorOption(title: 'Male'),
    TopSelectorOption(title: 'Female'),
  ];
  int _selectedIndex = 0;
  void _onOptionSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    
    // Calculate responsive dimensions
    final dialogWidth = size.width < 600 
        ? size.width * 0.9  // Mobile: 90% of screen width
        : size.width * 0.5; // Desktop: 50% of screen width
    
    final dialogHeight = size.width < 600
        ? size.height * 0.8 // Mobile: 80% of screen height
        : size.height * 0.6; // Desktop: 60% of screen height

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: EdgeInsets.symmetric(
          horizontal: size.width < 600 ? 8 : 16,
          vertical: 16
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.brightness == Brightness.light ? myGrey40 : myGrey80),
        ),
        child: Column(
          children: [
            Text(
              l10n.select_avatar,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 16),
            CustomTopSelector(
                options: _options,
                selectedIndex: _selectedIndex,
                onOptionSelected: _onOptionSelected),
            const SizedBox(height: 16),
            Expanded(
              child: _buildAvatarGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarGrid() {
    final int count = _selectedIndex == 0 ? 180 : 210;
    const Color avatarBackgroundColor = Color(0xFFFEF2ED);
    final size = MediaQuery.of(context).size;

    // Adjust grid columns based on screen width
    final crossAxisCount = size.width < 600 ? 4 : 6;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Theme(
        data: Theme.of(context).copyWith(
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.all(myGrey60),
            trackColor: WidgetStateProperty.all(myGrey20),
          ),
        ),
        child: Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          thickness: 6,
          radius: const Radius.circular(0),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width < 600 ? 16.0 : 24.0
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: size.width < 600 ? 8 : 12,
                mainAxisSpacing: size.width < 600 ? 8 : 12,
              ),
              itemCount: count,
              itemBuilder: (context, index) {
                final String avatarPath = _selectedIndex == 0
                    ? 'assets/avatars/male/maleAvatar_$index.png'
                    : 'assets/avatars/female/femaleAvatar_$index.png';
      
                return GestureDetector(
                  onTap: () {
                    widget.onAvatarSelected(avatarPath);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: avatarBackgroundColor,
                      border: Border.all(color: myGrey30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        avatarPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Failed to load avatar: $avatarPath');
                          return Container(
                            color: myGrey20,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: myGrey40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
