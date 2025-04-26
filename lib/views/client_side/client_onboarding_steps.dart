import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/client_side/client_side.dart';
import 'package:naturafit/views/web/web_client_side.dart';
import 'package:naturafit/widgets/custom_select_textfield.dart';
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
import 'package:naturafit/widgets/custom_fitness_level_slider.dart';
import 'package:naturafit/widgets/custom_consent_checkbox.dart';
import 'package:naturafit/widgets/custom_progress_photo_picker.dart';
import 'package:naturafit/widgets/custom_select_multiple_textfield.dart';
import 'package:naturafit/widgets/custom_phone_number_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'dart:typed_data';

class ClientOnboardingSteps extends StatefulWidget {
  final String userId;
  final String username;

  const ClientOnboardingSteps({
    Key? key,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  State<ClientOnboardingSteps> createState() => _ClientOnboardingStepsState();
}

class _ClientOnboardingStepsState extends State<ClientOnboardingSteps> {
  final _firestore = FirebaseFirestore.instance;
  int _currentStep = 1;
  final int _totalSteps = 9;

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

  // Add new controllers
  final _injuriesController = TextEditingController();
  final _dietaryRestrictionsController = TextEditingController();
  String _currentFitnessLevel = 'Level 1';
  String _activityLevel = 'Lightly Active';
  String _primaryGoal = 'General Fitness';
  String _secondaryGoal = '';

  

  // Add these to your state variables
  final _primaryGoalController = TextEditingController();
  final _secondaryGoalController = TextEditingController();

  // Add to state variables
  final _trainerPreferencesController = TextEditingController();

  // Add consent fields
  bool _consentBirthday = true;
  bool _consentEmail = true;
  bool _consentPhone = false;
  bool _consentLocation = true;
  bool _consentSocialMedia = true;
  bool _consentMeasurements = true;
  bool _consentProgressPhotos = false;



  // Add to state variables
  File? _progressPhotoFile;

  // Add these to state variables
  File? _frontPhotoFile;
  File? _backPhotoFile;
  File? _leftSidePhotoFile;
  File? _rightSidePhotoFile;

  // Add web image state variables
  Uint8List? _frontPhotoWeb;
  Uint8List? _backPhotoWeb;
  Uint8List? _leftSidePhotoWeb;
  Uint8List? _rightSidePhotoWeb;

  

  

  // Add these with other state variables
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';

  // Add these state variables near other state variables
  double _displayHeight = 170.0; // To store display value
  double _displayWeight = 70.0; // To store display value

  // Add this helper method to format birthday in a clear way
  String _formatBirthday() {
    // Format as YYYY-MM-DD with padding for single digits
    return DateTime(
      _selectedYear,
      _selectedMonth,
      _selectedDay,
    ).toString().split(' ')[0]; // This gets just the date part
  }

  // Add this helper method to convert birthday to Timestamp
  Timestamp _getBirthdayTimestamp() {
    return Timestamp.fromDate(
      DateTime(
        _selectedYear,
        _selectedMonth,
        _selectedDay,
      ),
    );
  }

  void _updateBirthdayController() {
    // For display purposes, we'll still show a formatted date string
    _birthdayController.text = DateTime(
      _selectedYear,
      _selectedMonth,
      _selectedDay,
    ).toString().split(' ')[0];
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
    _injuriesController.dispose();
    _dietaryRestrictionsController.dispose();
    _primaryGoalController.dispose();
    _secondaryGoalController.dispose();
    _trainerPreferencesController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(String userId, {File? file, Uint8List? webImageBytes}) async {
    if (file == null && webImageBytes == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('progress_photos')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      if (kIsWeb && webImageBytes != null) {
        await storageRef.putData(webImageBytes);
      } else if (file != null) {
        await storageRef.putFile(file);
      }
      
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _completeOnboarding() async {
    final l10n = AppLocalizations.of(context)!;
    final myIsWebOrDektop = isWebOrDesktopCached;
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: myBlue60)),
      );

      // Upload profile image if selected
      String? profileImageURL;
      if (_selectedImageFile != null || _webImageBytes != null) {
        try {
          if (_selectedImageFile?.path.startsWith('assets/') ?? false) {
            // For avatars, just store the asset path directly
            profileImageURL = _selectedImageFile!.path;
          } else if (kIsWeb && _webImageBytes != null) {
            // For web, upload the image bytes
            profileImageURL = await FirebaseService().uploadProfileImageBytes(_webImageBytes!);
          } else if (_selectedImageFile != null) {
            // For mobile/desktop, upload the file
            profileImageURL = await FirebaseService().uploadProfileImage(_selectedImageFile!);
          }
        } catch (e) {
          debugPrint('Error uploading image: $e');
        }
      }

      // Format available hours data
      final Map<String, dynamic> formattedAvailableHours = {};
      formattedAvailableHours['availableHours'] = _availableHours.map(
                      (key, value) => MapEntry(
                        key,
                        value.map((range) => {
                          'start': '${range.start.hour}:${range.start.minute}',
                          'end': '${range.end.hour}:${range.end.minute}',
                        }).toList(),
                      ),
                    );
     

      // Format social media data
      final List<Map<String, dynamic>> socialMediaData = _socialMediaProfiles
          .map((profile) => {
                'platform': profile.platform,
                'platformLink': profile.platformLink,
              })
          .toList();

      // Update user data in Firestore with null checks
      await _firestore.collection('users').doc(widget.userId).set({
        'onboardingCompleted': true,
        'isLoggedIn': true,
        'userType': 'client',
        // Basic info
        'fullName': _fullNameController.text.isEmpty ? widget.username : _fullNameController.text,
        'email': _emailController.text.isEmpty ? '' : _emailController.text,
        'phone': _phoneController.text.isNotEmpty ? _phoneController.text : '',
        'location': _locationController.text.isEmpty ? '' : _locationController.text,
        'birthday': _getBirthdayTimestamp(),
        'gender': _selectedGender.isEmpty ? 'Not Specified' : _selectedGender,
        // Profile
        'profileImageUrl': profileImageURL ?? '',
        'backgroundImageUrl': '',
        'bio': _bioController.text.isEmpty ? '' : _bioController.text,
        'socialMedia': socialMediaData.isEmpty ? [] : socialMediaData,
        // Measurements
        'height': _selectedHeight,
        'heightUnit': _heightUnit.isEmpty ? 'cm' : _heightUnit,
        'weight': _selectedWeight,
        'weightUnit': _weightUnit.isEmpty ? 'kg' : _weightUnit,
        // Health & Fitness
        'currentFitnessLevel': _currentFitnessLevel.isEmpty ? 'Beginner' : _currentFitnessLevel,
        'injuries': _injuriesController.text.isEmpty ? '' : _injuriesController.text,
        'dietaryRestrictions': _dietaryRestrictionsController.text.isEmpty ? '' : _dietaryRestrictionsController.text,
        // Goals & Preferences
        'primaryGoal': _primaryGoal.isEmpty ? '' : _primaryGoal,
        'secondaryGoal': _secondaryGoal.isEmpty ? '' : _secondaryGoal,
        'trainerPreferences': _trainerPreferencesController.text.isEmpty ? '' : _trainerPreferencesController.text,
        // Availability
        'availableHours': formattedAvailableHours.isEmpty ? {} : formattedAvailableHours,
        // Consent settings
        'consentSettings': {
          'birthday': _consentBirthday,
          'email': _consentEmail,
          'phone': _consentPhone,
          'location': _consentLocation,
          'socialMedia': _consentSocialMedia,
          'measurements': _consentMeasurements,
          'progressPhotos': _consentProgressPhotos,
        },
        'onboardingStep': _totalSteps,
        // Progress Photos
        'progressPhotos': {
          'front': await _uploadImage(widget.userId, 
            file: _frontPhotoFile, 
            webImageBytes: _frontPhotoWeb
          ) ?? '',
          'back': await _uploadImage(widget.userId, 
            file: _backPhotoFile, 
            webImageBytes: _backPhotoWeb
          ) ?? '',
          'leftSide': await _uploadImage(widget.userId, 
            file: _leftSidePhotoFile, 
            webImageBytes: _leftSidePhotoWeb
          ) ?? '',
          'rightSide': await _uploadImage(widget.userId, 
            file: _rightSidePhotoFile, 
            webImageBytes: _rightSidePhotoWeb
          ) ?? '',
        },
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => myIsWebOrDektop ? const WebClientSide() : const ClientSide(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
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
              builder: (context) => myIsWebOrDektop ? const WebClientSide() : const ClientSide(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error skipping onboarding: $e');
    }
  }

  Widget _buildNavigationButtons() {
    final theme = Theme.of(context);
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
                    _currentStep == _totalSteps ? l10n.finish : l10n.next,
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
    _primaryGoalController.text = _primaryGoal;
    _secondaryGoalController.text = _secondaryGoal;
    
    // Initialize display values based on stored values and units
    _displayHeight = _heightUnit == 'cm' ? _selectedHeight : _selectedHeight / 30.48;
    _displayWeight = _weightUnit == 'kg' ? _selectedWeight : _selectedWeight / 0.453592;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return PopScope(
      canPop: false, // Prevents back navigation
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, //const Color(0xFFF8FAFC),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _currentStep > 1
              ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.brightness == Brightness.light ? Colors.black : Colors.white, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.chevron_left, color: theme.brightness == Brightness.light ? Colors.black : Colors.white),
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
                  color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
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


  Widget _buildCurrentStep(AppLocalizations l10n, theme) {
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
        return _buildGoalsPreferencesStep(l10n, theme);
      case 6:
        return _buildHealthBackgroundStep(l10n, theme);
      case 7:
        return _buildProgressTrackingStep(l10n, theme);
       case 8:
        return _buildAvailabilityStep(l10n, theme); 
      case 9:
        return _buildConsentStep(l10n, theme);

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

  Widget _buildBasicProfileStep(AppLocalizations l10n, theme) {
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
                    color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
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

  Widget _buildContactInfoStep(AppLocalizations l10n, theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.contact_info,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.contact_info_subtitle,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              CustomFocusTextField(
                label: l10n.email,
                hintText: l10n.enter_email,
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
                label: l10n.city_state_country,
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

  Widget _buildAboutYouStep(AppLocalizations l10n, theme) {
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
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                ),
              ),
              Text(
                l10n.about_you_subtitle,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              CustomFocusTextField(
                controller: _bioController,
                label: l10n.bio,
                hintText: l10n.enter_about,
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

  

  Widget _buildBodyMeasurementsStep(AppLocalizations l10n, theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.body_measurements_title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CustomMeasurePicker(
            title: l10n.height_title,
            initialUnit: _heightUnit,
            units: ['cm', 'ft'],
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
            title: l10n.weight_title,
            initialUnit: _weightUnit,
            units: ['kg', 'lbs'],
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

  Widget _buildHealthBackgroundStep(AppLocalizations l10n, theme) {
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.health_fitness,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                ),
              ),
              const SizedBox(height: 24),
          
              // Fitness Level Dropdown
              Text(
                l10n.current_fitness,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              CustomFitnessLevelSlider(
                initialLevel: _currentFitnessLevel,
                onLevelChanged: (level) {
                  setState(() {
                    _currentFitnessLevel = level;
                  });
                },
              ),
              const SizedBox(height: 24),
          
              // Injuries/Medical Conditions
              CustomSelectMultipleTextField(
                label: l10n.medical_conditions,
                hintText: l10n.enter_injuries,
                controller: _injuriesController,
                options: commonMedicalConditions,
                maxLines: 3,
                onChanged: (selected) {
                  // Handle selected conditions
                  debugPrint('Selected conditions: $selected');
                },
              ),
              const SizedBox(height: 24),
          
              // Dietary Preferences
              CustomSelectMultipleTextField(
                label: l10n.dietary_restrictions,
                hintText: l10n.enter_dietary,
                controller: _dietaryRestrictionsController,
                options: commonDietaryRestrictions,
                maxLines: 3,
                onChanged: (selected) {
                  // Handle selected dietary restrictions
                  debugPrint('Selected dietary restrictions: $selected');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsPreferencesStep(AppLocalizations l10n, theme) {
    
  final List<String> fitnessGoals = [
    l10n.weight_loss,
    l10n.muscle_gain,
    l10n.general_fitness,
    l10n.health_maintenance,
    l10n.strength_training,
    l10n.endurance_building,
    l10n.flexibility_mobility,
    l10n.sports_performance,
    l10n.body_recomposition,
    l10n.stress_reduction
  ];

  
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.goals_preferences_title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                ),
              ),
              const SizedBox(height: 24),
          
              // Primary Goal
              CustomSelectTextField(
                label: l10n.primary_goal,
                hintText: l10n.enter_goals,
                controller: TextEditingController(text: _primaryGoal),
                options: fitnessGoals,
                onChanged: (value) {
                  setState(() {
                    _primaryGoal = value;
                  });
                },
              ),
              const SizedBox(height: 24),
          
              // Secondary Goal
              CustomSelectTextField(
                label: l10n.secondary_goal,
                hintText: l10n.secondary_goal_hint,
                controller: TextEditingController(text: _secondaryGoal),
                options:
                    fitnessGoals.where((goal) => goal != _primaryGoal).toList(),
                onChanged: (value) {
                  setState(() {
                    _secondaryGoal = value;
                  });
                },
              ),
              const SizedBox(height: 24),
          
              // Trainer Preferences
              CustomSelectMultipleTextField(
                label: l10n.trainer_preferences,
                hintText: l10n.enter_trainer_prefs,
                controller: _trainerPreferencesController,
                options: commonTrainerPreferences,
                maxLines: 3,
                onChanged: (selected) {
                  debugPrint('Selected trainer preferences: $selected');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildAvailabilityStep(AppLocalizations l10n, theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.weekly_availability_title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
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



  

  Widget _buildConsentStep(AppLocalizations l10n, theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.data_sharing,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                l10n.data_sharing_subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: myGrey60,
                ),
              ),
              const SizedBox(height: 12),
              CustomConsentCheckbox(
                title: l10n.consent_birthday_title,
                description: l10n.consent_birthday_desc,
                value: _consentBirthday,
                onChanged: (value) => setState(() => _consentBirthday = value),
                icon: Icons.cake_outlined,
              ),
              CustomConsentCheckbox(
                title: l10n.consent_email_title,
                description: l10n.consent_email_desc,
                value: _consentEmail,
                onChanged: (value) => setState(() => _consentEmail = value),
                icon: Icons.email_outlined,
              ),
              CustomConsentCheckbox(
                title: l10n.consent_phone_title,
                description: l10n.consent_phone_desc,
                value: _consentPhone,
                onChanged: (value) => setState(() => _consentPhone = value),
                icon: Icons.phone_outlined,
              ),
              CustomConsentCheckbox(
                title: l10n.consent_location_title,
                description: l10n.consent_location_desc,
                value: _consentLocation,
                onChanged: (value) => setState(() => _consentLocation = value),
                icon: Icons.location_on_outlined,
              ),
              CustomConsentCheckbox(
                title: l10n.consent_social_media_title,
                description: l10n.consent_social_media_desc,
                value: _consentSocialMedia,
                onChanged: (value) => setState(() => _consentSocialMedia = value),
                icon: Icons.share_outlined,
              ),
              CustomConsentCheckbox(
                title: l10n.consent_measurements_title,
                description: l10n.consent_measurements_desc,
                value: _consentMeasurements,
                onChanged: (value) => setState(() => _consentMeasurements = value),
                icon: Icons.straighten_outlined,
              ),
              CustomConsentCheckbox(
                title: l10n.consent_photos_title,
                description: l10n.consent_photos_desc,
                value: _consentProgressPhotos,
                onChanged: (value) =>
                    setState(() => _consentProgressPhotos = value),
                icon: Icons.photo_camera_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalConfirmationStep(AppLocalizations l10n, theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.almost_done,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.review_profile,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: myGrey60,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProgressTrackingStep(AppLocalizations l10n, theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.progress_photos,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomProgressPhotoPicker(
                title: l10n.front_view,
                description: l10n.front_photo_desc,
                selectedImageFile: _frontPhotoFile,
                webImage: _frontPhotoWeb,
                icon: Icons.camera_alt_outlined,
                onImageSelected: (file, [webImageBytes]) => setState(() {
                  if (file.path.isEmpty) {
                    _frontPhotoFile = null;
                    _frontPhotoWeb = null;
                  } else {
                    _frontPhotoFile = file;
                    _frontPhotoWeb = webImageBytes;
                  }
                }),
              ),
              CustomProgressPhotoPicker(
                title: l10n.back_view,
                description: l10n.back_photo_desc,
                selectedImageFile: _backPhotoFile,
                webImage: _backPhotoWeb,
                icon: Icons.camera_alt_outlined,
                onImageSelected: (file, [webImageBytes]) => setState(() {
                  if (file.path.isEmpty) {
                    _backPhotoFile = null;
                    _backPhotoWeb = null;
                  } else {
                    _backPhotoFile = file;
                    _backPhotoWeb = webImageBytes;
                  }
                }),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomProgressPhotoPicker(
                title: l10n.left_side,
                description: l10n.left_photo_desc,
                selectedImageFile: _leftSidePhotoFile,
                webImage: _leftSidePhotoWeb,
                icon: Icons.camera_alt_outlined,
                onImageSelected: (file, [webImageBytes]) => setState(() {
                  if (file.path.isEmpty) {
                    _leftSidePhotoFile = null;
                    _leftSidePhotoWeb = null;
                  } else {
                    _leftSidePhotoFile = file;
                    _leftSidePhotoWeb = webImageBytes;
                  }
                }),
              ),
              CustomProgressPhotoPicker(
                title: l10n.right_side,
                description: l10n.right_photo_desc,
                selectedImageFile: _rightSidePhotoFile,
                webImage: _rightSidePhotoWeb,
                icon: Icons.camera_alt_outlined,
                onImageSelected: (file, [webImageBytes]) => setState(() {
                  if (file.path.isEmpty) {
                    _rightSidePhotoFile = null;
                    _rightSidePhotoWeb = null;
                  } else {
                    _rightSidePhotoFile = file;
                    _rightSidePhotoWeb = webImageBytes;
                  }
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _selectedEducationCategory;
  String? _selectedEducationItem;
  bool _isCustomEducation = false;
  final TextEditingController _subjectController = TextEditingController();

  // Add this list at the top of your file with other constants
  final List<String> commonMedicalConditions = [
    'Asthma',
    'Back Pain',
    'Knee Problems',
    'High Blood Pressure',
    'Diabetes',
    'Heart Condition',
    'Arthritis',
    'Joint Pain',
    'Previous Injuries',
    'Pregnancy',
    'Limited Mobility',
  ];

  // Add this list with other constants
  final List<String> commonDietaryRestrictions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Lactose Intolerant',
    'Nut Allergy',
    'Kosher',
    'Halal',
    'Keto',
    'Paleo',
    'Low-Carb',
    'Low-Fat',
    'No Sugar',
    'No Seafood',
    'No Red Meat',
  ];

  // Add this list with other constants
  final List<String> commonTrainerPreferences = [
    'Experience with Beginners',
    'Specializes in Weight Loss',
    'Strength Training Expert',
    'Rehabilitation Experience',
    'Female Trainer Preferred',
    'Male Trainer Preferred',
    'Online Training Available',
    'In-Person Training',
    'Flexible Schedule',
    'Motivational Coaching Style',
    'Gentle Approach',
    'Intensive Training Style',
    'Sports-Specific Training',
    'Nutrition Guidance',
    'Holistic Approach',
  ];


/*
  String getFormattedPhoneNumber(String storedValue) {
    final parts = storedValue.split('|');
    if (parts.length == 3) {
      return '${parts[1]}${parts[2]}'; // countryCode + phoneNumber
    }
    return storedValue;
  }
  */
}
