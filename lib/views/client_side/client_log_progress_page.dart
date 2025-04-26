import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/unit_preferences.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_measure_picker.dart';
import 'package:naturafit/widgets/custom_progress_photo_picker.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:naturafit/widgets/custom_top_selector.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/models/achievements/client_achievements.dart';
import 'package:naturafit/services/achievement_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';

class LogProgressPage extends StatefulWidget {
  final double? initialHeight;
  final double? initialWeight;
  final String? initialHeightUnit;
  final String? initialWeightUnit;
  final bool isEnteredByTrainer;
  final Map<String, dynamic>? passedClientForTrainer;
  final Map<String, dynamic>? passedConsentSettingsForTrainer;

  const LogProgressPage({
    super.key,
    this.initialHeight,
    this.initialWeight,
    this.initialHeightUnit,
    this.initialWeightUnit,
    this.isEnteredByTrainer = false,
    this.passedClientForTrainer,
    this.passedConsentSettingsForTrainer,
  });

  @override
  State<LogProgressPage> createState() => _LogProgressPageState();
}

class _LogProgressPageState extends State<LogProgressPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _bicepsController = TextEditingController();
  final _thighsController = TextEditingController();
  final _calvesController = TextEditingController();
  final _notesController = TextEditingController();
  final _muscleMassController = TextEditingController();

  late double _selectedHeight; // Height in cm
  late double _selectedWeight; // Weight in kg

  String _heightUnit = 'cm';
  String _weightUnit = 'kg';
  String _unitForBodySection = 'cm';
  String _unitForMuscleMassSection = 'kg';

  File? _frontPhotoFile;
  File? _backPhotoFile;
  File? _leftSidePhotoFile;
  File? _rightSidePhotoFile;

  // Add web image state variables
  Uint8List? _frontPhotoWeb;
  Uint8List? _backPhotoWeb;
  Uint8List? _leftSidePhotoWeb;
  Uint8List? _rightSidePhotoWeb;

  // Add these new variables to track changes
  bool _hasChanges = false;
  late double _initialHeight;
  late double _initialWeight;

  @override
  void initState() {
    super.initState();
    debugPrint('LogProgressPage initState');
    debugPrint('widget.initialHeight: ${widget.initialHeight}');
    debugPrint('widget.initialWeight: ${widget.initialWeight}');
    _initialHeight = widget.initialHeight ?? 170.0;
    _initialWeight = widget.initialWeight ?? 70.0;
    _selectedHeight = _initialHeight;
    _selectedWeight = _initialWeight;
    _heightUnit = widget.initialHeightUnit ?? 'cm';
    _weightUnit = widget.initialWeightUnit ?? 'kg';
    _unitForBodySection = widget.initialHeightUnit == 'ft' ? 'inch' : 'cm';
    _unitForMuscleMassSection =
        widget.initialWeightUnit == 'lbs' ? 'lbs' : 'kg';

    // Add listeners to all controllers to track changes
    _bodyFatController.addListener(_checkForChanges);
    _chestController.addListener(_checkForChanges);
    _waistController.addListener(_checkForChanges);
    _hipsController.addListener(_checkForChanges);
    _bicepsController.addListener(_checkForChanges);
    _thighsController.addListener(_checkForChanges);
    _calvesController.addListener(_checkForChanges);
    _notesController.addListener(_checkForChanges);
    _muscleMassController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    bool hasChanges = false;

    // Check if height or weight changed
    if (_selectedHeight != _initialHeight ||
        _selectedWeight != _initialWeight) {
      hasChanges = true;
    }

    // Check if any measurements were entered
    if (_bodyFatController.text.isNotEmpty ||
        _chestController.text.isNotEmpty ||
        _waistController.text.isNotEmpty ||
        _hipsController.text.isNotEmpty ||
        _bicepsController.text.isNotEmpty ||
        _thighsController.text.isNotEmpty ||
        _calvesController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _muscleMassController.text.isNotEmpty) {
      hasChanges = true;
    }

    // Check if any photos were selected (both file and web)
    if (_frontPhotoFile != null || _frontPhotoWeb != null ||
        _backPhotoFile != null || _backPhotoWeb != null ||
        _leftSidePhotoFile != null || _leftSidePhotoWeb != null ||
        _rightSidePhotoFile != null || _rightSidePhotoWeb != null) {
      hasChanges = true;
    }

    setState(() {
      _hasChanges = hasChanges;
    });
  }

  Future<void> _saveProgress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: myBlue60)),
      );

      final userId = widget.isEnteredByTrainer ? (widget.passedClientForTrainer?['clientId'] ?? '') : context.read<UserProvider>().userData?['userId'] ?? '';
      final userData = widget.isEnteredByTrainer ? widget.passedClientForTrainer : context.read<UserProvider>().userData;

      final unitPreferences = context.read<UnitPreferences>();

      if (widget.initialHeightUnit == 'ft') {
        _selectedHeight = unitPreferences.ftToCm(_selectedHeight);
      }

      if (widget.initialWeightUnit == 'lbs') {
        _selectedWeight = unitPreferences.lbsToKg(_selectedWeight);
      }

      // Current measurements
      final currentWeight = double.tryParse(_weightController.text);
      var currentMuscleMass = double.tryParse(_muscleMassController.text);
      final currentBodyFat = double.tryParse(_bodyFatController.text);
      var currentChest = double.tryParse(_chestController.text);
      var currentWaist = double.tryParse(_waistController.text);
      var currentHips = double.tryParse(_hipsController.text);
      var currentBiceps = double.tryParse(_bicepsController.text);
      var currentThighs = double.tryParse(_thighsController.text);
      var currentCalves = double.tryParse(_calvesController.text);


      if (_heightUnit == 'ft') {
        _selectedHeight = unitPreferences.ftToCm(_selectedHeight);
        currentChest = unitPreferences.inchToCm(currentChest ?? 0);
        currentWaist = unitPreferences.inchToCm(currentWaist ?? 0);
        currentHips = unitPreferences.inchToCm(currentHips ?? 0);
        currentBiceps = unitPreferences.inchToCm(currentBiceps ?? 0);
        currentThighs = unitPreferences.inchToCm(currentThighs ?? 0);
        currentCalves = unitPreferences.inchToCm(currentCalves ?? 0);
      }

      if (_weightUnit == 'lbs') {
        _selectedWeight = unitPreferences.lbsToKg(_selectedWeight);
        currentMuscleMass = unitPreferences.lbsToKg(currentMuscleMass ?? 0);
      }

      // Get previous measurements for comparison
      final previousMeasurements = await FirebaseFirestore.instance
          .collection('progress_logs')
          .doc('clients')
          .collection(userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      final previousWeight = previousMeasurements.docs.isNotEmpty
          ? previousMeasurements.docs.first.data()['weight'] as double?
          : null;
      final previousMuscleMass = previousMeasurements.docs.isNotEmpty
          ? previousMeasurements.docs.first.data()['muscleMass'] as double?
          : null;
      final previousBodyFat = previousMeasurements.docs.isNotEmpty
          ? previousMeasurements.docs.first.data()['bodyFat'] as double?
          : null;

      String? photoUrl;
      // Upload photos if any
      final Map<String, dynamic> progressPhotos = {};

      // Upload front photo if exists
      if (_frontPhotoFile != null || _frontPhotoWeb != null) {
        final frontPhotoRef = FirebaseStorage.instance
            .ref()
            .child('progress_photos')
            .child(userId)
            .child('front_${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        if (kIsWeb && _frontPhotoWeb != null) {
          await frontPhotoRef.putData(_frontPhotoWeb!);
        } else if (_frontPhotoFile != null) {
          await frontPhotoRef.putFile(_frontPhotoFile!);
        }
        progressPhotos['frontPhoto'] = await frontPhotoRef.getDownloadURL();
      }

      // Upload back photo if exists
      if (_backPhotoFile != null || _backPhotoWeb != null) {
        final backPhotoRef = FirebaseStorage.instance
            .ref()
            .child('progress_photos')
            .child(userId)
            .child('back_${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        if (kIsWeb && _backPhotoWeb != null) {
          await backPhotoRef.putData(_backPhotoWeb!);
        } else if (_backPhotoFile != null) {
          await backPhotoRef.putFile(_backPhotoFile!);
        }
        progressPhotos['backPhoto'] = await backPhotoRef.getDownloadURL();
      }

      // Upload left side photo if exists
      if (_leftSidePhotoFile != null || _leftSidePhotoWeb != null) {
        final leftPhotoRef = FirebaseStorage.instance
            .ref()
            .child('progress_photos')
            .child(userId)
            .child('left_${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        if (kIsWeb && _leftSidePhotoWeb != null) {
          await leftPhotoRef.putData(_leftSidePhotoWeb!);
        } else if (_leftSidePhotoFile != null) {
          await leftPhotoRef.putFile(_leftSidePhotoFile!);
        }
        progressPhotos['leftSidePhoto'] = await leftPhotoRef.getDownloadURL();
      }

      // Upload right side photo if exists
      if (_rightSidePhotoFile != null || _rightSidePhotoWeb != null) {
        final rightPhotoRef = FirebaseStorage.instance
            .ref()
            .child('progress_photos')
            .child(userId)
            .child('right_${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        if (kIsWeb && _rightSidePhotoWeb != null) {
          await rightPhotoRef.putData(_rightSidePhotoWeb!);
        } else if (_rightSidePhotoFile != null) {
          await rightPhotoRef.putFile(_rightSidePhotoFile!);
        }
        progressPhotos['rightSidePhoto'] = await rightPhotoRef.getDownloadURL();
      }

      // Create progress data
      final progressData = {
        'userId': userId,
        'clientId': userId,
        'clientFullName': widget.isEnteredByTrainer
            ? (widget.passedClientForTrainer?['clientFullName'] ?? '')
            : userData?[fbFullName],
        'clientUsername': widget.isEnteredByTrainer
            ? (widget.passedClientForTrainer?['clientName'] ?? '')
            : userData?[fbRandomName],
        'role': 'client',
        'loggedByClient': widget.isEnteredByTrainer ? false : true,
        'trainerId': widget.isEnteredByTrainer ? userId : '',
        'date': Timestamp.now(),
        'weight': _selectedWeight,
        'height': _selectedHeight,
        'bodyFat': currentBodyFat?.toStringAsFixed(1),
        'muscleMass': currentMuscleMass?.toStringAsFixed(1),
        'measurements': {
          'chest': currentChest?.toStringAsFixed(1),
          'waist': currentWaist?.toStringAsFixed(1),
          'hips': currentHips?.toStringAsFixed(1),
          'biceps': currentBiceps?.toStringAsFixed(1),
          'thighs': currentThighs?.toStringAsFixed(1),
          'calves': currentCalves?.toStringAsFixed(1),
        },
        'notes': _notesController.text,
        if (progressPhotos.isNotEmpty) 'progressPhotos': progressPhotos,
      };

      // Save progress log
      final progressLogRef = await FirebaseFirestore.instance
          .collection('progress_logs')
          .doc(userId)
          .collection('all_progress_logs')
          .add(progressData);

      // Update user data with new weight and height
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      await userRef.update({
        'weight': _selectedWeight,
        'height': _selectedHeight,
      });

      // Calculate changes for achievements
      double? weightLoss;
      double? bodyFatReduction;
      double? muscleGain;
      int daysSinceLastProgress = 0;
      

      if (previousMeasurements.docs.isNotEmpty) {
        final lastMeasurement = previousMeasurements.docs.first.data();
        final lastMeasurementDate =
            (lastMeasurement['date'] as Timestamp).toDate();

        // Calculate days since last progress
        daysSinceLastProgress =
            DateTime.now().difference(lastMeasurementDate).inDays;

        // Calculate weight loss (positive value means weight was lost)
        if (previousWeight != null && currentWeight != null) {
          weightLoss = previousWeight - currentWeight;
        }

        // Calculate body fat reduction (positive value means fat was lost)
        if (previousBodyFat != null && currentBodyFat != null) {
          bodyFatReduction =
              double.parse(previousBodyFat.toString()) - currentBodyFat;
        }

        // Calculate muscle gain (positive value means muscle was gained)
        if (previousMuscleMass != null && currentMuscleMass != null) {
          muscleGain =
              currentMuscleMass - double.parse(previousMuscleMass.toString());
        }

        debugPrint('Progress Changes:');
        debugPrint('Weight Loss: $weightLoss kg');
        debugPrint('Body Fat Reduction: $bodyFatReduction %');
        debugPrint('Muscle Gain: $muscleGain kg');
        debugPrint('Days Since Last Progress: $daysSinceLastProgress');
      }

      // Check achievements with all tracking data
      final achievementService = AchievementService(
        userProvider: context.read<UserProvider>(),
        userId: userId,
      );

      await achievementService.checkProgressAchievements(
        weightLoss: weightLoss,
        bodyFatReduction: bodyFatReduction,
        muscleGain: muscleGain,
        hasProgressPhotos: _frontPhotoFile != null ||
            _backPhotoFile != null ||
            _leftSidePhotoFile != null ||
            _rightSidePhotoFile != null,
        daysSinceLastProgress: daysSinceLastProgress,
      );

      // Update UserProvider
      final updatedUserData = {
        ...(userData ?? {})
      }; // Create a copy of current userData
      updatedUserData['weight'] = _selectedWeight;
      updatedUserData['height'] = _selectedHeight;
      context.read<UserProvider>().setUserData(updatedUserData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
                                    title: l10n.progress,
                                    message: l10n.progress_saved,
                                    type: SnackBarType.success,
                                  ),
          
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
                                    title: l10n.progress,
                                    message: l10n.error_saving_progress(e.toString()),
                                    type: SnackBarType.error,
                                  ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _selectedIndex = 0;
  void _onOptionSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    // Remove listeners
    _bodyFatController.removeListener(_checkForChanges);
    _chestController.removeListener(_checkForChanges);
    _waistController.removeListener(_checkForChanges);
    _hipsController.removeListener(_checkForChanges);
    _bicepsController.removeListener(_checkForChanges);
    _thighsController.removeListener(_checkForChanges);
    _calvesController.removeListener(_checkForChanges);
    _notesController.removeListener(_checkForChanges);
    _muscleMassController.removeListener(_checkForChanges);

    _weightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _bicepsController.dispose();
    _thighsController.dispose();
    _calvesController.dispose();
    _notesController.dispose();
    _muscleMassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Add options list here
    final options = [
      TopSelectorOption(title: l10n.basic_measurements),
      TopSelectorOption(title: l10n.body_measurements),
      TopSelectorOption(title: l10n.progress_photos),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.log_progress_title,
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
                color: theme.brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.chevron_left,
                color: theme.brightness == Brightness.light
                    ? Colors.black
                    : Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _hasChanges
                ? () {
                    debugPrint('Save');
                    _saveProgress();
                  }
                : null,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _hasChanges ? myBlue30 : myGrey30,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _hasChanges ? myBlue60 : myGrey50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.save,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: myBlue60))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: theme.brightness == Brightness.light
                                        ? myGrey70
                                        : Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd MMMM yyyy')
                                        .format(DateTime.now()),
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            theme.brightness == Brightness.light
                                                ? myGrey70
                                                : Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              CustomTopSelector(
                                options: options,
                                selectedIndex: _selectedIndex,
                                onOptionSelected: _onOptionSelected,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedIndex == 0) ...[
                        // Basic Measurements Section
                        const SizedBox(height: 24),
                        CustomMeasurePicker(
                          title: l10n.height,
                          initialUnit: _heightUnit,
                          units: ['cm', 'ft'],
                          initialValue: _selectedHeight,
                          onChanged: (value, unit) {
                            setState(() {
                              _selectedHeight = value;
                              _heightUnit = unit;
                              _heightController.text = value.toStringAsFixed(0);
                              _checkForChanges();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomMeasurePicker(
                          title: l10n.weight,
                          initialUnit: _weightUnit,
                          units: ['kg', 'lbs'],
                          initialValue: _selectedWeight,
                          onChanged: (value, unit) {
                            setState(() {
                              _selectedWeight = value;
                              _weightUnit = unit;
                              _weightController.text = value.toStringAsFixed(1);
                              _checkForChanges();
                            });
                          },
                        ),
                      ] else if (_selectedIndex == 1) ...[
                        // Body Measurements Section

                        Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Column(
                              children: [
                                const SizedBox(height: 24),
                                Text(l10n.composition,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18, fontWeight: FontWeight.w600)),
                                CustomFocusTextField(
                                  label: '',
                                  hintText: l10n.body_fat_percentage,
                                  prefixIcon: Icons.speed,
                                  controller: _bodyFatController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                ),
                                const SizedBox(height: 12),
                                CustomFocusTextField(
                                  label: '',
                                  hintText:
                                      l10n.muscle_mass(_unitForMuscleMassSection),
                                  prefixIcon: Icons.fitness_center,
                                  controller: _muscleMassController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                ),
                                const SizedBox(height: 12),
                                Text(l10n.measurements,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18, fontWeight: FontWeight.w600)),
                                CustomFocusTextField(
                                    label: '',
                                    hintText: l10n.chest(_unitForBodySection),
                                    prefixIcon: Icons.accessibility_new,
                                    controller: _chestController),
                                const SizedBox(height: 12),
                                CustomFocusTextField(
                                    label: '',
                                    hintText: l10n.waist(_unitForBodySection),
                                    prefixIcon: Icons.straighten,
                                    controller: _waistController),
                                const SizedBox(height: 12),
                                CustomFocusTextField(
                                    label: '',
                                    hintText: l10n.hips(_unitForBodySection),
                                    prefixIcon: Icons.height,
                                    controller: _hipsController),
                                const SizedBox(height: 12),
                                CustomFocusTextField(
                                    label: '',
                                    hintText: l10n.biceps(_unitForBodySection),
                                    prefixIcon: Icons.fitness_center,
                                    controller: _bicepsController),
                                const SizedBox(height: 12),
                                CustomFocusTextField(
                                    label: '',
                                    hintText: l10n.calves(_unitForBodySection),
                                    prefixIcon: Icons.directions_walk,
                                    controller: _calvesController),
                                const SizedBox(height: 12),
                                CustomFocusTextField(
                                    label: '',
                                    hintText: l10n.thighs(_unitForBodySection),
                                    prefixIcon: Icons.directions_run,
                                    controller: _thighsController),
                              ],
                            ),
                          ),
                        ),
                      ] else if (_selectedIndex == 2) ...[
                        // Progress Photo Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
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
                                    _checkForChanges();
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
                                    _checkForChanges();
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
                                    _checkForChanges();
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
                                    _checkForChanges();
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMeasurementField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            final number = double.tryParse(value);
            if (number == null) {
              return 'Please enter a valid number';
            }
          }
          return null;
        },
      ),
    );
  }
}
