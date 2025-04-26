import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SocialMediaProfile {
  final String platform;
  final String platformLink;

  SocialMediaProfile({
    required this.platform,
    required this.platformLink,
  });

  Map<String, dynamic> toMap() => {
    'platform': platform,
    'platformLink': platformLink,
  };
}

class CustomSocialMediaSelector extends StatefulWidget {
  final Function(List<SocialMediaProfile>) onChanged;
  final List<SocialMediaProfile>? initialValue;

  const CustomSocialMediaSelector({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<CustomSocialMediaSelector> createState() => _CustomSocialMediaSelectorState();
}

class _CustomSocialMediaSelectorState extends State<CustomSocialMediaSelector> {
  final List<SocialMediaProfile> _profiles = [];
  final TextEditingController _platformLinkController = TextEditingController();
  String? _selectedPlatform;

  final Map<String, IconData> socialPlatforms = {
    'Instagram': Icons.camera_alt_outlined,
    'Facebook': Icons.facebook_outlined,
    'Twitter': Icons.flutter_dash_outlined,
    'LinkedIn': Icons.work_outline,
    'TikTok': Icons.music_note_outlined,
    'YouTube': Icons.play_circle_outline,
    'Snapchat': Icons.remove_red_eye_outlined,
    'Website': Icons.language_outlined,
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _profiles.addAll(widget.initialValue!);
    }
  }

  void _addProfile() {
    final l10n = AppLocalizations.of(context)!;
    // Add print statements for debugging
    print('Selected Platform: $_selectedPlatform');
    print('Platform Link: ${_platformLinkController.text}');

    if (_selectedPlatform != null && _platformLinkController.text.isNotEmpty) {
      setState(() {
        _profiles.add(SocialMediaProfile(
          platform: _selectedPlatform!,
          platformLink: _platformLinkController.text,
        ));
        _selectedPlatform = null;
        _platformLinkController.clear();
      });
      widget.onChanged(_profiles);
    } else {
      // Show a snackbar if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.social_media,
          message: _selectedPlatform == null 
              ? l10n.please_select_a_platform_first
                : l10n.please_enter_a_link,
          type: SnackBarType.error,
        ),
      );
    }
  }

  void _removeProfile(int index) {
    setState(() {
      _profiles.removeAt(index);
    });
    widget.onChanged(_profiles);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.social_media_links,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
          ),
        ),
        const SizedBox(height: 0),
        Text(
          l10n.please_first_select_a_platform_and_then_enter_your_link,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: theme.brightness == Brightness.light ? myGrey90 : myGrey40,
          ),
        ),
        const SizedBox(height: 8),
        
        // Add new profile section
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(0),
          child: Row(
            children: [
              // Platform dropdown
              Container(
                decoration: BoxDecoration(
                  color: myBlue30,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: myBlue60,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PopupMenuButton<String>(
                    icon: _selectedPlatform != null
                        ? Icon(
                            socialPlatforms[_selectedPlatform],
                            color: Colors.white,
                            size: 20,
                          )
                        : const Icon(
                            Icons.link_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: theme.brightness == Brightness.dark ? myGrey80 : Colors.white,
                    itemBuilder: (context) => socialPlatforms.entries.map((entry) {
                      return PopupMenuItem(
                        value: entry.key,
                        child: Row(
                          children: [
                            Icon(entry.value, size: 20, color: theme.brightness == Brightness.light ? myGrey90 : myGrey10),
                            const SizedBox(width: 8),
                            Text(
                              entry.key,
                              style: GoogleFonts.plusJakartaSans(
                                color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onSelected: (String value) {
                      setState(() {
                        _selectedPlatform = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Platform link input
              Expanded(
                child: CustomFocusTextField(
                  //width: 200,
                  //height: 48,
                  controller: _platformLinkController,
                  label: '',  // Empty label since we're using hint
                  hintText: _selectedPlatform != null 
                      ? '${_selectedPlatform!} link'
                      : l10n.select_platform_first,
                  onChanged: (_) {
                    setState(() {});  // To update the state when text changes
                  },
                  prefixIcon: null,  // No prefix icon needed
                  isRequired: false,
                ),
              ),
              const SizedBox(width: 8),
              
              // Add button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _selectedPlatform != null && _platformLinkController.text.isNotEmpty 
                      ? myBlue20 
                      : myGrey20,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.add, 
                    color: _selectedPlatform != null && _platformLinkController.text.isNotEmpty 
                        ? myBlue60 
                        : myGrey90
                  ),
                  iconSize: 24,
                  onPressed: _selectedPlatform != null && _platformLinkController.text.isNotEmpty 
                      ? _addProfile 
                      : null,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // List of added profiles
        if (_profiles.isNotEmpty) ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _profiles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final profile = _profiles[index];
              return Card(
                elevation: 1,
                color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                
                child: ListTile(
                  leading: Icon(
                    socialPlatforms[profile.platform],
                    color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                  ),
                  title: Text(profile.platform, style: GoogleFonts.plusJakartaSans(
                    color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),),
                  subtitle: Text(profile.platformLink, style: GoogleFonts.plusJakartaSans(
                    color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: myRed50, size: 20,),
                    onPressed: () => _removeProfile(index),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _platformLinkController.dispose();
    super.dispose();
  }
} 