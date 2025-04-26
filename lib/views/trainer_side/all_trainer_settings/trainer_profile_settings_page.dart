import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/unit_preferences.dart';
import 'package:naturafit/widgets/custom_date_spinner.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_gender_picker.dart';
import 'package:naturafit/widgets/custom_measure_picker.dart';
import 'package:naturafit/widgets/custom_social_media_selector.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/widgets/custom_top_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum ProfileSection { personal, basic }

class TrainerProfileSettingsPage extends StatefulWidget {
  final String initialBio;
  final List<SocialMediaProfile> initialSocialMedia;
  final String initialBirthday;
  final String initialGender;
  final double? initialHeight;
  final double? initialWeight;
  final String? initialHeightUnit;
  final String? initialWeightUnit;

  const TrainerProfileSettingsPage({
    super.key,
    required this.initialBio,
    required this.initialSocialMedia,
    required this.initialBirthday,
    required this.initialGender,
    this.initialHeight,
    this.initialWeight,
    this.initialHeightUnit,
    this.initialWeightUnit,
  });

  @override
  State<TrainerProfileSettingsPage> createState() => _TrainerProfileSettingsPageState();
}

class _TrainerProfileSettingsPageState extends State<TrainerProfileSettingsPage> {
  final _basicProfileForm = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _socialMediaController = TextEditingController();
  List<SocialMediaProfile> _socialMediaProfiles = [];
  String _selectedGender = 'Not Specified';
  
  // Date related variables
  int _selectedDay = DateTime.now().day;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year - 25;

  int _selectedSectionIndex = 0;

  // Add this variable to track changes
  bool _hasUnsavedChanges = false;

  // Add these variables at the top with other state variables
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  // Add to state class
  double _selectedHeight = 170.0; // Default height in cm
  double _selectedWeight = 70.0; // Default weight in kg
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';

  // Add this method to check for changes
  void _checkForChanges() {
    final bioChanged = _bioController.text != widget.initialBio;
    final socialMediaChanged = !_areListsEqual(_socialMediaProfiles, widget.initialSocialMedia);
    final birthdayChanged = _formatDate() != widget.initialBirthday;
    final genderChanged = _selectedGender != widget.initialGender;
    final heightChanged = _selectedHeight != widget.initialHeight ||
                         _heightUnit != widget.initialHeightUnit;
    final weightChanged = _selectedWeight != widget.initialWeight ||
                         _weightUnit != widget.initialWeightUnit;

    setState(() {
      _hasUnsavedChanges = bioChanged || socialMediaChanged || birthdayChanged || 
                          genderChanged || heightChanged || weightChanged;
    });
  }

  // Helper method to compare social media lists
  bool _areListsEqual(List<SocialMediaProfile> list1, List<SocialMediaProfile> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].platform != list2[i].platform || 
          list1[i].platformLink != list2[i].platformLink) {
        return false;
      }
    }
    return true;
  }

  // Helper method to format date
  String _formatDate() {
    return '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _bioController.text = widget.initialBio;
    _socialMediaProfiles = widget.initialSocialMedia;
    _selectedGender = widget.initialGender;
    
    // Parse birthday
    if (widget.initialBirthday.isNotEmpty) {
      final parts = widget.initialBirthday.split('-');
      if (parts.length == 3) {
        _selectedYear = int.parse(parts[0]);
        _selectedMonth = int.parse(parts[1]);
        _selectedDay = int.parse(parts[2]);
      }
    }

    // Add listeners to track changes
    _bioController.addListener(_checkForChanges);

    // Initialize body measurements
    _selectedHeight = widget.initialHeight ?? 170.0;
    _selectedWeight = widget.initialWeight ?? 70.0;
    _heightUnit = widget.initialHeightUnit ?? 'cm';
    _weightUnit = widget.initialWeightUnit ?? 'kg';
  }

  @override
  void dispose() {
    _bioController.removeListener(_checkForChanges);
    _bioController.dispose();
    _socialMediaController.dispose();
    super.dispose();
  }

  void _updateBirthdayController() {
    // Implementation if needed
  }

  Timestamp _getBirthdayTimestamp() {
    return Timestamp.fromDate(
      DateTime(
        _selectedYear,
        _selectedMonth,
        _selectedDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.brightness == Brightness.light ? Colors.black : Colors.white, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.chevron_left, color: theme.brightness == Brightness.light ? Colors.black : Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          l10n.profile_settings,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _hasUnsavedChanges
              ? () async {
                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(color: myBlue60),
                      ),
                    );


                    final unitPreferences = context.read<UnitPreferences>();

                    if (_heightUnit == 'ft') {
                      _selectedHeight = unitPreferences.ftToCm(_selectedHeight);
                    }

                    if (_weightUnit == 'lbs') {
                      _selectedWeight = unitPreferences.lbsToKg(_selectedWeight);
                    }
                    debugPrint('height::: $_selectedHeight');
                    debugPrint('weight::: $_selectedWeight');


                    // Prepare the updated data
                    final updatedData = {
                      'bio': _bioController.text,
                      'socialMedia': _socialMediaProfiles.map((profile) => {
                        'platform': profile.platform,
                        'username': profile.platformLink,
                      }).toList(),
                      'birthday': _getBirthdayTimestamp(),
                      'gender': _selectedGender,
                      'height': _selectedHeight,
                      'weight': _selectedWeight,
                      'heightUnit': _heightUnit,
                      'weightUnit': _weightUnit,
                    };

                    // Update in Firebase
                    if (context.mounted) {
                      await FirebaseService().updateUser(updatedData, context);
                    }

                    // Update UserProvider
                    if (context.mounted) {
                      final userProvider = context.read<UserProvider>();
                      final currentData = Map<String, dynamic>.from(userProvider.userData ?? {});
                      currentData.addAll(updatedData);
                      userProvider.setUserData(currentData);

                      Navigator.pop(context); // Close loading dialog
                      Navigator.pop(context); // Return to settings page
                    }
                  } catch (e) {
                    if (context.mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.update_failed),
                          content: Text(e.toString()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.ok),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                }
              : null,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _hasUnsavedChanges ? myBlue30 : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _hasUnsavedChanges ? myBlue60 : myGrey30,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.save,
                  style: GoogleFonts.plusJakartaSans(
                    color: _hasUnsavedChanges ? Colors.white : myGrey60,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _buildBasicProfileStep(),
    );
  }

  List<TopSelectorOption> _getSectionOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      TopSelectorOption(title: l10n.personal),
      TopSelectorOption(title: l10n.body),
      TopSelectorOption(title: l10n.basic),
    ];
  }

  Widget _buildBasicProfileStep() {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _basicProfileForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTopSelector(
                  options: _getSectionOptions(context),
                  selectedIndex: _selectedSectionIndex,
                  onOptionSelected: (index) {
                    setState(() {
                      _selectedSectionIndex = index;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                if (_selectedSectionIndex == 0) ...[
                  // Personal section (Bio and Social Media)
                  CustomFocusTextField(
                    controller: _bioController,
                    label: l10n.bio,
                    hintText: l10n.tell_about_yourself,
                    maxLines: 4,
                    isRequired: false,
                  ),
                  const SizedBox(height: 32),
                  CustomSocialMediaSelector(
                    initialValue: _socialMediaProfiles,
                    onChanged: (profiles) {
                      setState(() {
                        _socialMediaProfiles = profiles;
                        _socialMediaController.text = profiles
                            .map((p) => '${p.platform}: ${p.platformLink}')
                            .join('\n');
                      });
                      _checkForChanges();
                    },
                  ),
                ] else if (_selectedSectionIndex == 1) ...[
                  _buildBodyMeasurementsStep(),
                ] else ...[
                  const SizedBox(height: 8),
                  CustomDateSpinner(
                    title: l10n.birthday_title,
                    initialDate: DateTime(_selectedYear, _selectedMonth, _selectedDay),
                    firstDate: DateTime(1940),
                    lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDay = date.day;
                        _selectedMonth = date.month;
                        _selectedYear = date.year;
                        _updateBirthdayController();
                      });
                      _checkForChanges();
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildGenderSelector(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomGenderPicker(
          selectedGender: _selectedGender,
          onGenderSelected: (gender) {
            setState(() {
              _selectedGender = gender;
            });
            _checkForChanges();
          },
        ),
      ],
    );
  }

  Widget _buildBodyMeasurementsStep() {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.body_measurements,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CustomMeasurePicker(
            title: l10n.height,
            initialUnit: _heightUnit,
            units: const ['cm', 'ft'],
            initialValue: _selectedHeight,
            onChanged: (value, unit) {
              setState(() {
                _selectedHeight = value;
                _heightUnit = unit;
                _heightController.text = value.toStringAsFixed(1);
              });
              _checkForChanges();
            },
          ),
          const SizedBox(height: 12),
          CustomMeasurePicker(
            title: l10n.weight,
            initialUnit: _weightUnit,
            units: const ['kg', 'lbs'],
            initialValue: _selectedWeight,
            onChanged: (value, unit) {
              setState(() {
                _selectedWeight = value ;
                _weightUnit = unit;
                _weightController.text = value.toStringAsFixed(1);
                debugPrint('weight::: $_selectedWeight');
                debugPrint('value::: $value');
              });
              _checkForChanges();
            },
          ),
        ],
      ),
    );
  }
} 