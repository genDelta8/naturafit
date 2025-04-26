import 'package:naturafit/services/theme_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/web/web_coach_side.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:naturafit/widgets/horizontal_number_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:naturafit/services/auth/bloc/my_auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/views/trainer_side/coach_side.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:naturafit/widgets/custom_measure_picker.dart';
import 'package:naturafit/widgets/plus_icon_painter.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_search_bar.dart';
import 'package:naturafit/widgets/custom_selectable_list.dart';
import 'package:naturafit/widgets/custom_available_hours_selector.dart';
import 'package:naturafit/widgets/custom_payment_methods_selector.dart';
import 'package:naturafit/widgets/custom_social_media_selector.dart';
import 'package:naturafit/widgets/custom_date_spinner.dart';
import 'package:naturafit/widgets/custom_gender_picker.dart';
import 'package:naturafit/widgets/custom_profile_photo_picker.dart';
import 'package:naturafit/widgets/custom_phone_number_field.dart';
import 'package:naturafit/services/unit_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/widgets/custom_date_picker.dart';
import 'package:naturafit/services/firebase_service.dart';

class TrainerOnboardingSteps extends StatefulWidget {
  final String userId;
  final String username;
  final String trainerClientId;

  const TrainerOnboardingSteps({
    Key? key,
    required this.userId,
    required this.username,
    required this.trainerClientId,
  }) : super(key: key);

  @override
  State<TrainerOnboardingSteps> createState() => _TrainerOnboardingStepsState();
}

class _TrainerOnboardingStepsState extends State<TrainerOnboardingSteps> {
  final _firestore = FirebaseFirestore.instance;
  int _currentStep = 1;
  final int _totalSteps = 8;

  // Form keys
  final _basicProfileForm = GlobalKey<FormState>();
  final _professionalForm = GlobalKey<FormState>();

  // Controllers for all fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _locationController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _specializationsController = TextEditingController();
  final _additionalSkillsController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _locationsController = TextEditingController();
  final _maxClientsController = TextEditingController();
  final _clientTypesController = TextEditingController();
  final _rateController = TextEditingController();
  final _packageRatesController = TextEditingController();
  final _paymentMethodsController = TextEditingController();
  final _bioController = TextEditingController();
  final _socialMediaController = TextEditingController();

  String _selectedGender = 'Not Specified';
  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Not Specified'
  ];

  // Data storage
  final Map<String, dynamic> _trainerData = {};

  // Add these to the state class
  final List<String> _selectedSpecializations = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customSpecController = TextEditingController();
  String _selectedCategory = 'General';

  

  // Add to state class
  File? _selectedImageFile;
  Uint8List? _webImageBytes;

  // Add these to state class
  final List<Map<String, dynamic>> _educationList = [];
  final TextEditingController _customEducationController =
      TextEditingController();
  final TextEditingController _educationStartDateController =
      TextEditingController();
  final TextEditingController _educationEndDateController =
      TextEditingController();

  

  // Add to state class
  final List<Map<String, dynamic>> _experienceList = [];
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _experienceStartDateController =
      TextEditingController();
  final TextEditingController _experienceEndDateController =
      TextEditingController();
  int _yearsOfExperience = 0;

  int _selectedDay = DateTime.now().day;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year - 25; // Default to 25 years ago

  // Add to state class
  double _selectedHeight = 170.0; // Default height in cm
  double _selectedWeight = 70.0; // Default weight in kg

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();

  // Add this near other state variables
  bool _showSearchBar = false;

  // Add this with other controller declarations at the top of the class
  final ScrollController _experienceScrollController = ScrollController();
  final ScrollController _educationScrollController = ScrollController();

  // Add this to your state variables
  Map<String, List<TimeRange>> _availableHours = {};

  // Add to state variables
  late List<Map<String, dynamic>> _selectedPaymentMethods;

  // Add to state variables
  List<SocialMediaProfile> _socialMediaProfiles = [];

  // Add these with other state variables
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';

  // Add these state variables near other state variables
  double _displayHeight = 170.0; // To store display value
  double _displayWeight = 70.0; // To store display value

  void _updateBirthdayController() {
    _birthdayController.text =
        '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Dispose all controllers
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    _locationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _specializationsController.dispose();
    _additionalSkillsController.dispose();
    _availabilityController.dispose();
    _locationsController.dispose();
    _maxClientsController.dispose();
    _clientTypesController.dispose();
    _rateController.dispose();
    _packageRatesController.dispose();
    _paymentMethodsController.dispose();
    _bioController.dispose();
    _socialMediaController.dispose();
    _searchController.dispose();
    _customSpecController.dispose();
    _customEducationController.dispose();
    _educationStartDateController.dispose();
    _educationEndDateController.dispose();
    _jobTitleController.dispose();
    _organizationController.dispose();
    _experienceStartDateController.dispose();
    _experienceEndDateController.dispose();
    _categoryController.dispose();
    _educationController.dispose();
    _experienceScrollController.dispose();
    _educationScrollController.dispose();
    super.dispose();
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

/*
  String getFormattedPhoneNumber(String storedValue) {
    final parts = storedValue.split('|');
    if (parts.length == 3) {
      return '${parts[1]}${parts[2]}'; // countryCode + phoneNumber
    }
    return storedValue;
  }
  */

  Future<void> _completeOnboarding() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: myBlue60),
      ),
    );

    final myIsWebOrDektop = isWebOrDesktopCached;

    try {
      String? imageUrl;

      if (_selectedImageFile != null || _webImageBytes != null) {
        // Check if the selected image is an avatar (asset path)
        if (_selectedImageFile?.path.startsWith('assets/') ?? false) {
          // For avatars, just store the asset path directly
          imageUrl = _selectedImageFile!.path;
        } else if (kIsWeb && _webImageBytes != null) {
          // For web, upload the image bytes
          imageUrl = await FirebaseService().uploadProfileImageBytes(_webImageBytes!);
        } else if (_selectedImageFile != null) {
          // For mobile/desktop, upload the file
          imageUrl = await FirebaseService().uploadProfileImage(_selectedImageFile!);
        }
      }

      const timeFormat = '12-hour';
      const dateFormat = 'MM/dd/yyyy';

      // Store unit preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('heightUnit', _heightUnit);
      await prefs.setString('weightUnit', _weightUnit);
      await prefs.setString('timeFormat', timeFormat);
      await prefs.setString('dateFormat', dateFormat);
      await prefs.setBool('isMetric', _heightUnit == 'cm' && _weightUnit == 'kg');

      final Map<String, dynamic> formData = {
        'onboardingCompleted': true,
        'isLoggedIn': true,
      };

      // Only add values that are not empty/null
      if (imageUrl != null) formData[fbProfileImageURL] = imageUrl;
      if (_fullNameController.text.isNotEmpty) formData[fbFullName] = _fullNameController.text;
      if (_emailController.text.isNotEmpty) formData['email'] = _emailController.text;
      if (_phoneController.text.isNotEmpty) formData['phone'] = _phoneController.text; else formData['phone'] = '';
      if (_selectedYear != null && _selectedMonth != null && _selectedDay != null) {
        formData['birthday'] = _getBirthdayTimestamp(); //DateFormat('yyyy-MM-dd').format(DateTime(_selectedYear, _selectedMonth, _selectedDay));
      }
      if (_selectedGender != 'Not Specified') formData['gender'] = _selectedGender;
      if (_locationController.text.isNotEmpty) formData['location'] = _locationController.text;
      if (_selectedHeight != 0) formData['height'] = _selectedHeight;
      if (_selectedWeight != 0) formData['weight'] = _selectedWeight;
      formData['heightUnit'] = _heightUnit;
      formData['weightUnit'] = _weightUnit;


      if (_selectedSpecializations.isNotEmpty) formData['specializations'] = _selectedSpecializations;
      if (_availableHours.isNotEmpty) {
        formData['availableHours'] = _availableHours.map(
                      (key, value) => MapEntry(
                        key,
                        value.map((range) => {
                          'start': '${range.start.hour}:${range.start.minute}',
                          'end': '${range.end.hour}:${range.end.minute}',
                        }).toList(),
                      ),
                    );
       
      }
      if (_rateController.text.isNotEmpty) {
        formData['hourlyRate'] = double.tryParse(_rateController.text) ?? 0.0;
      }
      if (_packageRatesController.text.isNotEmpty) formData['packageRates'] = _packageRatesController.text;
      if (_selectedPaymentMethods.isNotEmpty) formData['paymentMethods'] = _selectedPaymentMethods;
      if (_bioController.text.isNotEmpty) formData['bio'] = _bioController.text;
      if (_socialMediaProfiles.isNotEmpty) formData['socialMedia'] = _socialMediaProfiles.map((p) => p.toMap()).toList();
      if (_yearsOfExperience > 0) formData['yearsOfExperience'] = _yearsOfExperience;
      if (_experienceList.isNotEmpty) formData['experienceList'] = _experienceList;
      if (_educationList.isNotEmpty) formData['educationList'] = _educationList;

      await _firestore.collection('users').doc(widget.userId).update(formData);


      String trainerClientProfileImageURL = '';
      if (imageUrl != null) trainerClientProfileImageURL = imageUrl; 

      // Add this block to create client profile
      await _firestore.collection('users').doc(widget.trainerClientId).set({
        'userId': widget.trainerClientId,
        'role': 'client',
        'linkedTrainerId': widget.userId,
        'isTrainerClientProfile': true,
        'onboardingCompleted': true,
        'isLoggedIn': false,
        fbFullName: _fullNameController.text.isNotEmpty ? _fullNameController.text : widget.username,
        fbRandomName: widget.username,
        fbProfileImageURL: trainerClientProfileImageURL,
        'backgroundImageUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'birthday': _selectedYear != null && _selectedMonth != null && _selectedDay != null ? DateFormat('yyyy-MM-dd').format(DateTime(_selectedYear, _selectedMonth, _selectedDay)) : null,
        'email': _emailController.text.isNotEmpty ? _emailController.text : null,
        'phone': _phoneController.text.isNotEmpty ? _phoneController.text : '',
        'location': _locationController.text.isNotEmpty ? _locationController.text : null,
        'gender': _selectedGender != 'Not Specified' ? _selectedGender : null,
        'dataConsent': {
          'birthday': true,
          'email': true,
          'phone': true,
          'location': true,
          'socialMedia': true,
          'measurements': true,
          'progressPhotos': true,
        },
        'height': _selectedHeight,
        'weight': _selectedWeight,
        'heightUnit': _heightUnit,
        'weightUnit': _weightUnit,
        'timeFormat': timeFormat,
        'dateFormat': dateFormat,
        'primaryGoal': 'General Fitness',
        'onboardingStep': 8,
      }, SetOptions(merge: true));


      //final connectionId = '${widget.userId}_${widget.trainerClientId}';

      // Add this block to create trainer connection
      await _firestore.collection('connections').doc('trainer').collection(widget.userId).doc(widget.trainerClientId).set({
        'clientId': widget.trainerClientId,
        'clientName': _fullNameController.text.isNotEmpty ? _fullNameController.text : widget.username,
        'clientFullName': _fullNameController.text.isNotEmpty ? _fullNameController.text : widget.username,
        'clientProfileImageUrl': trainerClientProfileImageURL,
        'role': 'client',
        'timestamp': FieldValue.serverTimestamp(),
        'status': fbClientConfirmedStatus,
        'connectionType': fbAppConnectionType,
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));


      // Add this block to create client connection
      await _firestore.collection('connections').doc('client').collection(widget.trainerClientId).doc(widget.userId).set({
        'professionalId': widget.userId,
        'professionalUsername': widget.username,
        'professionalFullName': _fullNameController.text.isNotEmpty ? _fullNameController.text : widget.username,
        'professionalProfileImageUrl': trainerClientProfileImageURL,
        'role': 'trainer',
        'timestamp': FieldValue.serverTimestamp(),
        'status': fbClientConfirmedStatus,
        'connectionType': fbAppConnectionType,
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        context.read<AuthBloc>().add(CheckAuthStatus(context));
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => myIsWebOrDektop ? const WebCoachSide() : const CoachSide(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.error,
            message: l10n.error_completing_setup(e.toString()),
            type: SnackBarType.error,
          ),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
      _saveCurrentStep();
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
      _saveCurrentStep();
    }
  }

  Future<void> _saveCurrentStep() async {
    try {
      await _firestore.collection('users').doc(widget.userId).update({
        'onboardingStep': _currentStep,
      });
    } catch (e) {
      debugPrint('Error saving current step: $e');
    }
  }

  void _skipAll() async {
    final myIsWebOrDektop = isWebOrDesktopCached;
    try {
      await _firestore.collection('users').doc(widget.userId).update({
        'onboardingCompleted': true,
        'isLoggedIn': true,
      });

      if (mounted) {
        context.read<AuthBloc>().add(CheckAuthStatus(context));
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => myIsWebOrDektop ? const WebCoachSide() : const CoachSide(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error skipping onboarding: $e');
    }
  }

  Widget _buildNavigationButtons() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _currentStep == _totalSteps ? _completeOnboarding : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: myBlue60,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep == _totalSteps ? l10n.complete_button : l10n.continue_button,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_currentStep != _totalSteps) const SizedBox(width: 8),
                  if (_currentStep != _totalSteps)
                    SizedBox(
                      width: 16,
                      height: 12,
                      child: CustomPaint(
                        painter: PlusIconPainter(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize payment methods
    _selectedPaymentMethods = [
      <String, dynamic>{
        'name': 'Cash',
        'selected': true,
        'fields': <String, String>{},
      }
    ];
    // ... other initializations ...
    
    // Initialize display values based on stored values and units
    _displayHeight = _heightUnit == 'cm' ? _selectedHeight : _selectedHeight / 30.48;
    _displayWeight = _weightUnit == 'kg' ? _selectedWeight : _selectedWeight / 0.453592;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return PopScope(
      canPop: false, // Prevents back navigation
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _currentStep > 1
              ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.brightness == Brightness.dark ? Colors.white : Colors.black, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.chevron_left, color: theme.brightness == Brightness.dark ? Colors.white : Colors.black),
                    onPressed: _previousStep,
                  ),
                )
              : null,
          centerTitle: true,
          title: Container(
            width: 200, // Adjust width as needed
            height: 8,
            decoration: BoxDecoration(
              color: myGrey20,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                Flexible(
                  flex: _currentStep,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light ? myGrey80 : myGrey70,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Flexible(
                  flex: _totalSteps - _currentStep,
                  child: Container(),
                ),
              ],
            ),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: () => _skipAll(),
              child: Text(
                l10n.skip_all,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildCurrentStep(l10n, theme),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.step_count(_currentStep, _totalSteps),
                style: GoogleFonts.plusJakartaSans(
                  color: myBlue60,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _skipAll,
                child: Text(
                  l10n.skip_all,
                  style: GoogleFonts.plusJakartaSans(
                    color: myBlue60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _currentStep / _totalSteps,
            backgroundColor: myBlue60.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(myBlue60),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(AppLocalizations l10n, ThemeData theme) {
    switch (_currentStep) {
      case 1:
        return _buildBasicProfileStep(l10n, theme);
      case 2:
        return _buildContactInfoStep(l10n, theme);
      case 3:
        return _buildAboutYouStep(l10n, theme);
      case 4:
        return _buildBodyMeasurementsStep(l10n, theme);
      case 5:
        return _buildEducationStep(l10n, theme);
      case 6:
        return _buildExperienceStep(l10n, theme);
      case 7:
        return _buildSpecializationsStep(l10n, theme);
      case 8:
        return _buildAvailabilityStep(l10n, theme);
        /*
      case 9:
        return _buildBusinessProfileStep();
        */
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    int? maxLines,
    bool isOptional = true,
  }) {
    IconData? getIconForField() {
      if (keyboardType == TextInputType.emailAddress) return Icons.mail_outline;
      if (keyboardType == TextInputType.phone) return Icons.phone_outlined;
      if (label == 'Full Name') return Icons.person_outline;
      if (label == 'Location') return Icons.location_on_outlined;
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${isOptional ? '' : ' *'}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: myGrey90,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines ?? 1,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: myGrey60,
                fontSize: 16,
              ),
              prefixIcon: Icon(
                getIconForField(),
                color: myGrey60,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String value,
    required Function(String?) onChanged,
    bool isOptional = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${isOptional ? '' : ' *'}',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem(
              value: item,
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 100,
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: myBlue60),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate:
                  DateTime.now().subtract(const Duration(days: 365 * 18)),
              firstDate: DateTime(1940),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              controller.text = DateFormat('yyyy-MM-dd').format(picked);
            }
          },
          child: IgnorePointer(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                suffixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildBasicProfileStep(AppLocalizations l10n, ThemeData theme) {
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
                Text(
                  l10n.basic_profile,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                _buildProfilePhotoPicker(),
                const SizedBox(height: 8),
                CustomFocusTextField(
                  label: l10n.full_name,
                  hintText: l10n.enter_full_name,
                  controller: _fullNameController,
                  prefixIcon: Icons.person_outline,
                  onChanged: (value) {
                    // Add any onChange logic here if needed
                  },
                ),
                const SizedBox(height: 8),
                CustomDateSpinner(
                  title: l10n.birthday_title,
                  initialDate:
                      DateTime(_selectedYear, _selectedMonth, _selectedDay),
                  firstDate: DateTime(1940),
                  lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDay = date.day;
                      _selectedMonth = date.month;
                      _selectedYear = date.year;
                      _updateBirthdayController();
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildGenderSelector(),
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
          },
        ),
      ],
    );
  }

  Widget _buildProfilePhotoPicker() {
    return CustomProfilePhotoPicker(
      selectedImageFile: _selectedImageFile,
      webImage: _webImageBytes,
      onImageSelected: (File file, [Uint8List? webImageBytes]) {
        setState(() {
          if (file.path.isEmpty) {
            _selectedImageFile = null;
            _webImageBytes = null;
          } else {
            _selectedImageFile = file;
            _webImageBytes = webImageBytes;
          }
        });
      },
    );
  }

  Widget _buildContactInfoStep(AppLocalizations l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.how_can_clients_reach,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.how_can_clients_reach_subtitle,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.dark ? myGrey40 : myGrey60,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              CustomFocusTextField(
                label: l10n.email_address,
                hintText: l10n.enter_your_email,
                controller: _emailController,
                prefixIcon: Icons.mail_outline,
                onChanged: (value) {
                  // Add any onChange logic here if needed
                },
              ),
              const SizedBox(height: 16),
              CustomPhoneNumberField(
                controller: _phoneController,
                onChanged: (value) {
                  // Add any onChange logic here if needed
                },
              ),
              const SizedBox(height: 16),
              CustomFocusTextField(
                label: l10n.location,
                hintText: l10n.city_state_country,
                controller: _locationController,
                prefixIcon: Icons.location_on_outlined,
                onChanged: (value) {
                  // Add any onChange logic here if needed
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutYouStep(AppLocalizations l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.about_you,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                l10n.tell_about_yourself_subtitle,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              CustomFocusTextField(
                controller: _bioController,
                label: l10n.bio,
                hintText: l10n.tell_about_yourself,
                maxLines: 4,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              CustomSocialMediaSelector(
                initialValue: _socialMediaProfiles,
                onChanged: (profiles) {
                  setState(() {
                    _socialMediaProfiles = profiles;
                    _socialMediaController.text = profiles
                        .map((p) => '${p.platform}: ${p.platformLink}')
                        .join('\n');
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildBodyMeasurementsStep(AppLocalizations l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.body_measurements,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          CustomMeasurePicker(
            title: l10n.height,
            initialUnit: _heightUnit,
            units: const ['cm', 'ft'],
            initialValue: _heightUnit == 'cm' ? _selectedHeight : _displayHeight,
            onChanged: (value, unit) {
              setState(() {
                _heightUnit = unit;
                _displayHeight = value;
                // Convert to cm for storage
                if (unit == 'ft') {
                  _selectedHeight = value * 30.48; // 1 foot = 30.48 cm
                } else {
                  _selectedHeight = value;
                }
                _heightController.text = value.toStringAsFixed(0);
                //debugPrint('height::: $_selectedHeight');
              });
            },
          ),
          const SizedBox(height: 12),
          CustomMeasurePicker(
            title: l10n.weight,
            initialUnit: _weightUnit,
            units: const ['kg', 'lbs'],
            initialValue: _weightUnit == 'kg' ? _selectedWeight : _displayWeight,
            onChanged: (value, unit) {
              setState(() {
                _weightUnit = unit;
                _displayWeight = value;
                // Convert to kg for storage
                if (unit == 'lbs') {
                  _selectedWeight = value * 0.453592; // 1 lb = 0.453592 kg
                } else {
                  _selectedWeight = value;
                }
                _weightController.text = value.toStringAsFixed(0);
                //debugPrint('weight::: $_selectedWeight');
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEducationStep(AppLocalizations l10n, ThemeData theme) {
    


    final Map<String, List<String>> educationCategories = {
    l10n.formal_education: [
      l10n.high_school_diploma,
      l10n.associate_degree,
      l10n.bachelor_degree,
      l10n.master_degree,
      l10n.phd,
    ],
    l10n.certifications: [
      l10n.certified_personal_trainer,
      l10n.certified_strength_and_conditioning_specialist,
      l10n.certified_functional_strength_coach,
      l10n.corrective_exercise_specialist,
      l10n.performance_enhancement_specialist,
      l10n.certified_nutrition_specialist,
      l10n.precision_nutrition_certification,
      l10n.certified_pilates_instructor,
      l10n.certified_yoga_instructor,
      l10n.crossfit_level_1_trainer,
      l10n.trx_suspension_training_certification,
      l10n.kettlebell_instructor_certification,
      l10n.sports_massage_therapy_certification,
      l10n.senior_fitness_specialist_certification,
      l10n.pre_and_post_natal_fitness_certification,
      l10n.youth_fitness_specialist_certification,
      l10n.group_fitness_instructor_certification,
    ],
    l10n.specialized_education: [
      l10n.aquatic_exercise_association_certification,
      l10n.tactical_strength_and_conditioning_certification,
      l10n.behavior_change_specialist_certification,
      l10n.mobility_and_movement_specialist_certification,
      l10n.advanced_biomechanics_certification,
      l10n.martial_arts_and_self_defense_trainer_certification,
      l10n.cpr_aed_certification,
      l10n.first_aid_certification,
      l10n.injury_prevention_and_management,
      l10n.advanced_program_design,
      l10n.nutrition_for_athletes,
      l10n.mental_health_and_fitness_integration,
      l10n.sports_psychology_basics,
      l10n.functional_movement_screen_fms_certification,
      l10n.advanced_recovery_techniques,
    ],
  };


    return SingleChildScrollView(
      controller: _educationScrollController,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.education_certifications,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
          
              // Category Field
              CustomFocusTextField(
                label: l10n.category,
                hintText: l10n.enter_select_category,
                controller: _categoryController,
                prefixIcon: Icons.school_outlined,
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: myGrey60,
                ),
                onSuffixTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: educationCategories.keys.length,
                        itemBuilder: (context, index) {
                          final category =
                              educationCategories.keys.elementAt(index);
                          return ListTile(
                            title: Text(category),
                            onTap: () {
                              setState(() {
                                _categoryController.text = category;
                                _selectedEducationCategory = category;
                                _selectedEducationItem = null;
                                _educationController.clear();
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
                onChanged: (value) {
                  setState(() {
                    _selectedEducationCategory = value;
                    _selectedEducationItem = null;
                  });
                },
              ),
              const SizedBox(height: 16),
          
              // Education/Certification Field
              CustomFocusTextField(
                label: l10n.education_certification,
                hintText: l10n.enter_select_education,
                controller: _educationController,
                prefixIcon: Icons.workspace_premium_outlined,
                suffixIcon:
                    educationCategories.keys.contains(_selectedEducationCategory)
                        ? Icon(
                            Icons.arrow_drop_down,
                            color: myGrey60,
                          )
                        : null,
                onSuffixTap: educationCategories.keys
                        .contains(_selectedEducationCategory)
                    ? () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount:
                                  educationCategories[_selectedEducationCategory]
                                          ?.length ??
                                      0,
                              itemBuilder: (context, index) {
                                final item = educationCategories[
                                    _selectedEducationCategory]![index];
                                return ListTile(
                                  title: Text(item),
                                  onTap: () {
                                    setState(() {
                                      _educationController.text = item;
                                      _selectedEducationItem = item;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      }
                    : null,
                onChanged: (value) {
                  setState(() {
                    _selectedEducationItem = value;
                  });
                },
              ),
              const SizedBox(height: 16),
          
              // Subject Field
              CustomFocusTextField(
                label: l10n.subject_specialization,
                hintText: l10n.enter_subject,
                controller: _subjectController,
                prefixIcon: Icons.topic_outlined,
                onChanged: (value) {
                  // Add any onChange logic here if needed
                },
              ),
              const SizedBox(height: 16),
          
              // Date Fields Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.start_date,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _educationStartDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: l10n.select_date,
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                            onTap: () async {
                              final DateTime? picked = await CustomDatePicker.show(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1940),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _educationStartDateController.text =
                                      DateFormat('yyyy-MM-dd').format(picked);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.end_date,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _educationEndDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: l10n.select_date,
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                            onTap: () async {
                              final DateTime? picked = await CustomDatePicker.show(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1940),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _educationEndDateController.text =
                                      DateFormat('yyyy-MM-dd').format(picked);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          
              // Add Button
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_categoryController.text.isNotEmpty &&
                          _educationController.text.isNotEmpty) {
                        setState(() {
                          _educationList.add({
                            'category': _categoryController.text,
                            'education': _educationController.text,
                            'subject': _subjectController.text,
                            'startDate': _educationStartDateController.text,
                            'endDate': _educationEndDateController.text,
                          });
                          // Clear the form
                          _categoryController.clear();
                          _educationController.clear();
                          _subjectController.clear();
                          _educationStartDateController.clear();
                          _educationEndDateController.clear();
                          _selectedEducationCategory = null;
                          _selectedEducationItem = null;
                        });
          
                        // Add scroll animation after setState
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _educationScrollController.animateTo(
                            _educationScrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myBlue20,
                      foregroundColor: myBlue60,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.add_education,
                          style: GoogleFonts.plusJakartaSans(
                            color: myBlue60,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_currentStep != _totalSteps) const SizedBox(width: 8),
                        if (_currentStep != _totalSteps)
                          const Icon(
                            Icons.school_outlined,
                            color: myBlue60,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
          
              // Added Education List
              if (_educationList.isNotEmpty) ...[
                Text(
                  l10n.added_education_certifications,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _educationList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final education = _educationList[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      elevation: 1,
                      color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side - Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.light ? myBlue60.withOpacity(0.1) : myBlue20,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.school_outlined,
                                color: myBlue60,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
          
                            // Middle - Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    education['education'],
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      education['category'],
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: theme.brightness == Brightness.light ? myGrey70 : myGrey10,
                                      ),
                                    ),
                                  ),
                                  if (education['subject'].isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      education['subject'],
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: theme.brightness == Brightness.light ? myGrey70 : myGrey10,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${education['startDate']} - ${education['endDate'].isEmpty ? 'Present' : education['endDate']}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
          
                            // Right side - Delete button
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: myRed50,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _educationList.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceStep(AppLocalizations l10n, ThemeData theme) {
    return SingleChildScrollView(
      controller: _experienceScrollController,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.professional_experience,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
          
              // Years of Experience Slider
              Container(
                margin: const EdgeInsets.only(top: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HorizontalNumberSlider(
                      onValueChanged: (value) {
                        setState(() {
                          _yearsOfExperience = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              ),
              //const Divider(height: 32),
              const SizedBox(height: 16),
          
              // Experience Form
              CustomFocusTextField(
                label: l10n.job_title,
                hintText: l10n.enter_job_title,
                controller: _jobTitleController,
                prefixIcon: Icons.work_outline,
                onChanged: (value) {
                  // Add any onChange logic here if needed
                },
              ),
              const SizedBox(height: 16),
              CustomFocusTextField(
                label: l10n.organization,
                hintText: l10n.enter_organization,
                controller: _organizationController,
                prefixIcon: Icons.business_outlined,
                onChanged: (value) {
                  // Add any onChange logic here if needed
                },
              ),
              const SizedBox(height: 16),
          
              // Date Fields Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.start_date,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _experienceStartDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: l10n.select_date,
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                            onTap: () async {
                              final DateTime? picked = await CustomDatePicker.show(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1940),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _experienceStartDateController.text =
                                      DateFormat('yyyy-MM-dd').format(picked);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.end_date,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _experienceEndDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: l10n.select_date,
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                            onTap: () async {
                              final DateTime? picked = await CustomDatePicker.show(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1940),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _experienceEndDateController.text =
                                      DateFormat('yyyy-MM-dd').format(picked);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Add Button
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_jobTitleController.text.isNotEmpty &&
                          _organizationController.text.isNotEmpty) {
                        setState(() {
                          _experienceList.add({
                            'jobTitle': _jobTitleController.text,
                            'organization': _organizationController.text,
                            'startDate': _experienceStartDateController.text,
                            'endDate': _experienceEndDateController.text,
                          });
                          // Clear the form
                          _jobTitleController.clear();
                          _organizationController.clear();
                          _experienceStartDateController.clear();
                          _experienceEndDateController.clear();
                        });
          
                        // Add scroll animation after setState
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _experienceScrollController.animateTo(
                            _experienceScrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myBlue20,
                      foregroundColor: myBlue60,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.add_experience,
                          style: GoogleFonts.plusJakartaSans(
                            color: myBlue60,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_currentStep != _totalSteps) const SizedBox(width: 8),
                        if (_currentStep != _totalSteps)
                          const Icon(
                            Icons.work_outline,
                            color: myBlue60,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
          
              // Experience List
              if (_experienceList.isNotEmpty) ...[
                Text(
                  l10n.added_experience,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _experienceList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final experience = _experienceList[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      elevation: 1,
                      color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side - Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.light ? myBlue60.withOpacity(0.1) : myBlue20,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.work_outline,
                                color: myBlue60,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
          
                            // Middle - Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    experience['jobTitle'],
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      experience['organization'],
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: theme.brightness == Brightness.light ? myGrey70 : myGrey10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${experience['startDate']} - ${experience['endDate'].isEmpty ? 'Present' : experience['endDate']}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
          
                            // Right side - Delete button
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: myRed50,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _experienceList.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecializationsStep(AppLocalizations l10n, ThemeData theme) {

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _selectedCategory = l10n.general;
    });



    // Add this map to store categories and their specializations
  final Map<String, List<String>> specializationCategories = {
    l10n.general: [
      l10n.weight_loss_coaching,
      l10n.strength_training,
      l10n.cardiovascular_endurance,
      l10n.core_stability_training,
      l10n.functional_fitness_training,
      l10n.general_fitness_for_beginners,
      l10n.body_recomposition,
      l10n.metabolic_conditioning,
      l10n.low_impact_fitness,
      l10n.circuit_training,
    ],
    l10n.advanced: [
      l10n.high_intensity_interval_training,
      l10n.crossfit_coaching,
      l10n.powerlifting,
      l10n.olympic_lifting,
      l10n.strongman_training,
      l10n.kettlebell_training,
      l10n.suspension_training,
      l10n.plyometrics_and_explosive_movements,
      l10n.hybrid_training,
      l10n.agility_and_speed_training,
    ],
    l10n.sports: [
      l10n.sports_specific_conditioning,
      l10n.marathon_training,
      l10n.triathlon_training,
      l10n.cycling_and_spin_training,
      l10n.swimming_and_aquatic_training,
      l10n.golf_fitness,
      l10n.tennis_fitness,
      l10n.soccer_conditioning,
      l10n.basketball_training,
      l10n.martial_arts_fitness,
    ],
    l10n.recovery: [
      l10n.pre_and_post_natal_fitness,
      l10n.senior_fitness,
      l10n.youth_fitness,
      l10n.post_rehabilitation_training,
      l10n.joint_pain_management,
      l10n.chronic_disease_management,
      l10n.injury_prevention,
      l10n.mobility_and_flexibility_training,
      l10n.stress_management_programs,
      l10n.restorative_fitness,
    ],
    l10n.transformation: [
      l10n.bodybuilding,
      l10n.physique_and_aesthetic_coaching,
      l10n.bikini_competition_preparation,
      l10n.muscle_gain_programs,
      l10n.lean_bulk_planning,
      l10n.contest_preparation_coaching,
      l10n.weight_gain_assistance,
      l10n.advanced_sculpting_programs,
      l10n.maintenance_coaching,
      l10n.body_dysmorphia_awareness_training,
    ],
    l10n.mind_body: [
      l10n.yoga,
      l10n.pilates,
      l10n.tai_chi_fitness,
      l10n.mindfulness_based_fitness,
      l10n.meditation_integration,
      l10n.breathing_techniques,
      l10n.body_mind_centering,
      l10n.qigong_for_fitness,
      l10n.barre_workouts,
      l10n.dance_fitness,
    ],
    l10n.lifestyle: [
      l10n.corporate_fitness_programs,
      l10n.family_fitness,
      l10n.outdoor_adventure_fitness,
      l10n.hiking_and_trail_fitness,
      l10n.fitness_for_gamers,
      l10n.military_and_tactical_fitness,
      l10n.emergency_services_fitness,
      l10n.fitness_for_travelers,
      l10n.minimalist_fitness_bodyweight,
      l10n.home_workouts,
    ],
    l10n.diet_and_nutrition: [
      l10n.nutrition_planning,
      l10n.plant_based_nutrition_coaching,
      l10n.ketogenic_diet_support,
      l10n.paleo_diet_fitness_programs,
      l10n.intermittent_fasting_guidance,
      l10n.sports_nutrition_coaching,
      l10n.weight_loss_meal_planning,
      l10n.lean_mass_nutrition,
      l10n.food_intolerance_management,
      l10n.gut_health_and_fitness,
    ],
    l10n.specialty: [
      l10n.lgbtq_inclusive_fitness,
      l10n.adaptive_fitness_for_disabilities,
      l10n.neurodivergent_fitness_programs,
      l10n.fitness_for_cancer_survivors,
      l10n.arthritis_friendly_training,
      l10n.fibromyalgia_specific_workouts,
      l10n.cardiac_rehabilitation_programs,
      l10n.diabetes_specific_fitness,
      l10n.autoimmune_disorder_friendly_fitness,
      l10n.hormonal_balance_training,
    ],
    l10n.technology: [
      l10n.wearable_tech_integration,
      l10n.online_personal_training,
      l10n.app_based_fitness_guidance,
      l10n.virtual_reality_fitness_programs,
      l10n.fitness_gamification_coaching,
      l10n.ai_driven_workouts,
      l10n.biofeedback_coaching,
      l10n.genetic_fitness_planning,
      l10n.data_driven_fitness_programs,
      l10n.fitness_equipment_mastery,
    ],
  };

  
    List<String> filteredSpecs = [];
    if (_searchController.text.isEmpty) {
      filteredSpecs = specializationCategories[_selectedCategory] ?? [];
    } else {
      filteredSpecs = specializationCategories.values
          .expand((specs) => specs)
          .where((spec) =>
              spec.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.specializations,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
          
              
              
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            const SizedBox(width: 8),
                            ...specializationCategories.keys.map((category) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _selectedCategory == category
                                          ? myGrey30
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: _selectedCategory == category
                                            ? myGrey90
                                            : theme.brightness == Brightness.light ? Colors.transparent : myGrey80,
                                        border: Border.all(
                                          color: _selectedCategory == category
                                              ? Colors.transparent
                                              : theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: Text(
                                        category,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: _selectedCategory == category
                                              ? Colors.white
                                              : theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showSearchBar = !_showSearchBar;
                              if (!_showSearchBar) {
                                _searchController.clear();
                              }
                            });
                          },
                          child: Icon(
                            Icons.search,
                            color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          
              const SizedBox(height: 8),
          
              if (_showSearchBar)
                CustomSearchBar(
                  controller: _searchController,
                  hintText: l10n.search_specializations,
                  onChanged: (value) => setState(() {}),
                ),
          
              const SizedBox(height: 8),
              CustomSelectableList(
                items: _searchController.text.isEmpty 
                  ? specializationCategories[_selectedCategory] ?? []
                  : specializationCategories.values
                      .expand((specs) => specs)
                      .where((spec) => 
                        spec.toLowerCase().contains(_searchController.text.toLowerCase()))
                      .toList(),
                selectedItems: _selectedSpecializations,
                onItemSelected: (item) {
                  setState(() {
                    _selectedSpecializations.add(item);
                  });
                },
                onItemDeselected: (item) {
                  setState(() {
                    _selectedSpecializations.remove(item);
                  });
                },
              ),
          
              const SizedBox(height: 0),
          
              Row(
                children: [
                  Expanded(
                    child: CustomFocusTextField(
                      label: '',
                      hintText: l10n.enter_custom_specialization,
                      controller: _customSpecController,
                      prefixIcon: Icons.category_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_customSpecController.text.isNotEmpty) {
                        setState(() {
                          _selectedSpecializations.add(_customSpecController.text);
                          _customSpecController.clear();
                        });
                      }
                    },
                    child: Text(l10n.add),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: myBlue60,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
          
              //const SizedBox(height: 16),
          
              if (_selectedSpecializations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? myGrey10 : theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selected,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedSpecializations.map((spec) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: myGrey20,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  spec,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: myGrey70,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedSpecializations.remove(spec);
                                    });
                                  },
                                  child: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: myGrey60,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityStep(AppLocalizations l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.weekly_availability,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              
              CustomAvailableHoursSelector(
                initialValue: _availableHours,
                use24HourFormat: false,
                onChanged: (value) {
                  
                  setState(() {
                    //_availableHours = value;
                    _availableHours = value.map(
                      (key, list) => MapEntry(
                        key,
                        List<TimeRange>.from(list),
                      ),
                    );
                    _availabilityController.text = value.entries
                        .where((entry) => entry.value.isNotEmpty)
                        .map((entry) =>
                            '${entry.key}: ${entry.value.map((range) => '${range.start.format(context)}-${range.end.format(context)}').join(', ')}')
                        .join('\n');
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _selectedEducationCategory;
  String? _selectedEducationItem;
  bool _isCustomEducation = false;
  final TextEditingController _subjectController = TextEditingController();
}
