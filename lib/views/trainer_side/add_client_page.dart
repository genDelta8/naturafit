
import 'package:naturafit/services/invitation/invitation_bloc.dart';
import 'package:naturafit/services/trainer_services/add_client_bloc.dart';
import 'package:naturafit/services/unit_preferences.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/widgets/custom_available_hours_selector.dart';
import 'package:naturafit/widgets/custom_date_spinner.dart';
import 'package:naturafit/widgets/custom_fitness_level_slider.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_gender_picker.dart';
import 'package:naturafit/widgets/custom_measure_picker.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naturafit/widgets/avatar_picker_dialog.dart';
import 'package:naturafit/widgets/custom_step_indicator.dart';
import 'package:naturafit/widgets/custom_select_multiple_textfield.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddClientPage extends StatefulWidget {
  const AddClientPage({Key? key}) : super(key: key);

  @override
  State<AddClientPage> createState() => _AddClientPageState();
}

class _AddClientPageState extends State<AddClientPage> {
  int _selectedDay = DateTime.now().day;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year - 25; // Default to 25 years ago

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AddClientBloc()),
        BlocProvider(create: (context) => InvitationBloc()),
      ],
      child: _AddClientPageContent(),
    );
  }
}

class _AddClientPageContent extends StatefulWidget {
  @override
  State<_AddClientPageContent> createState() => _AddClientPageContentState();
}

class _AddClientPageContentState extends State<_AddClientPageContent>
    with SingleTickerProviderStateMixin {
  int _selectedDay = DateTime.now().day;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year - 25; // Default to 25 years ago

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _goalsController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _injuriesController = TextEditingController();
  final _fitnessHistoryController = TextEditingController();
  final _dietaryHabitsController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _exercisePreferencesController = TextEditingController();

  String _selectedGender = 'Not Specified';
  bool _isInvitation = true;
  int _currentStep = 0;
  late AnimationController _animationController;

  // Add to state class
  double _selectedHeight = 170.0; // Default height in cm
  double _selectedWeight = 70.0; // Default weight in kg
  // Add these state variables near other state variables
  double _displayHeight = 170.0; // To store display value
  double _displayWeight = 70.0; // To store display value
  // Add this to your state variables
  Map<String, List<TimeRange>> _availableHours = {};
  String _currentFitnessLevel = 'Level 3';



  List<String> genderOptions = ['Male', 'Female', 'Other', 'Not Specified'];
  String? _selectedAvatarPath;

  

  

  

  

  

  

  

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    _goalsController.dispose();
    _medicalHistoryController.dispose();
    _injuriesController.dispose();
    _fitnessHistoryController.dispose();
    _dietaryHabitsController.dispose();
    _availabilityController.dispose();
    _exercisePreferencesController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final List<String> stepNames = [
      l10n.basic_info,
      l10n.body,
      l10n.health,
      l10n.time
    ];

    return AppBar(
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            width: 1
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            Icons.chevron_left,
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        l10n.add_new_client,
        style: GoogleFonts.plusJakartaSans(
          color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: CustomStepIndicator(
            currentStep: _currentStep,
            totalSteps: stepNames.length,
            stepName: stepNames[_currentStep],
            activeColor: myBlue60,
            inactiveColor: theme.brightness == Brightness.light ? myGrey30 : myGrey60,
          ),
        ),
      ],
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
    );
  }

  Widget _buildSummaryCard(
      String label, IconData icon, Color color, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : myGrey70,
        borderRadius: BorderRadius.circular(16),
        //border: isSelected ? Border.all(color: color, width: 2) : null,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF1E293B) : Colors.white70,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isSelected ? const Color(0xFF1E293B) : Colors.white70,
              height: 1.2,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: BlocConsumer<AddClientBloc, AddClientState>(
        listener: (context, state) {
          if (state is AddClientSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar.show(
                title: l10n.add_client,
                message: l10n.client_added_successfully,
                type: SnackBarType.success,
              ),
            );
            Navigator.pop(context);
          } else if (state is AddClientError) {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar.show(
                title: l10n.add_client,
                message: l10n.error_adding_client(state.message),
                type: SnackBarType.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: [
                              _buildBasicInfoStep(),
                              _buildBodyMeasurementsStep(l10n),
                              _buildHealthGoalsStep(),
                              _buildAvailabilityStep(l10n),
                            ][_currentStep],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildNavigationButtons(),
                  ),
                ],
              ),
              if (state is AddClientLoading)
                Container(
                  color: Colors.black12,
                  child: const Center(
                    child: CircularProgressIndicator(color: myBlue60),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      validator: validator ??
          (required
              ? (value) => value?.isEmpty ?? true ? 'Please enter $label' : null
              : null),
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      style: GoogleFonts.plusJakartaSans(
        color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: theme.brightness == Brightness.light ? Colors.grey[400] : Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.brightness == Brightness.light ? Colors.grey[300]! : myGrey60),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.brightness == Brightness.light ? Colors.grey[300]! : myGrey60),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: myBlue60),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: myRed40),
        ),
        filled: true,
        fillColor: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: _buildAvatarSelector()),
            CustomFocusTextField(
              label: l10n.client_name,
              hintText: l10n.enter_client_name,
              controller: _nameController,
              prefixIcon: Icons.person_outline,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomFocusTextField(
              label: l10n.client_email,
              hintText: l10n.enter_client_email,
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              isRequired: false,
            ),
            const SizedBox(height: 16),
            CustomFocusTextField(
              label: l10n.phone_number,
              hintText: l10n.enter_phone_number,
              controller: _phoneController,
              prefixIcon: Icons.phone_outlined,
              isRequired: false,
            ),
            const SizedBox(height: 16),
            CustomDateSpinner(
              title: l10n.birthday,
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
              },
            ),
            const SizedBox(height: 16),
            CustomGenderPicker(
              selectedGender: _selectedGender,
              onGenderSelected: (gender) {
                setState(() {
                  _selectedGender = gender;
                });
              },
            ),
          ],
        ),
      ),
    );
  }



  void _updateBirthdayController() {
    _birthdayController.text =
        '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}';
  }


  Widget _buildBodyMeasurementsStep(AppLocalizations l10n) {
    final userData = context.read<UserProvider>().userData;
    String heightUnit = userData?['heightUnit'] ?? 'cm';
    String weightUnit = userData?['weightUnit'] ?? 'kg';
    final unitPrefs = context.read<UnitPreferences>();

    final initialValueHeight = heightUnit == 'cm' ? 170 : unitPrefs.cmToft(170);
    final initialValueWeight = weightUnit == 'kg' ? 70 : unitPrefs.kgToLbs(70);
    
    _displayHeight = initialValueHeight.toDouble();
    _displayWeight = initialValueWeight.toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          const SizedBox(height: 16),
          CustomMeasurePicker(
            title: l10n.height,
            initialUnit: heightUnit,
            units: const ['cm', 'ft'],
            initialValue: initialValueHeight.toDouble(),
            onChanged: (value, unit) {
              setState(() {
                heightUnit = unit;
                _displayHeight = value;
                // Convert to cm for storage
                if (unit == 'ft') {
                  _selectedHeight = value * 30.48; // 1 foot = 30.48 cm
                } else {
                  _selectedHeight = value;
                }
              });
            },
          ),
          const SizedBox(height: 12),
          CustomMeasurePicker(
            title: l10n.weight,
            initialUnit: weightUnit,
            units: const ['kg', 'lbs'],
            initialValue: initialValueWeight.toDouble(),
            onChanged: (value, unit) {
              setState(() {
                weightUnit = unit;
                _displayWeight = value;
                // Convert to kg for storage
                if (unit == 'lbs') {
                  _selectedWeight = value * 0.453592; // 1 lb = 0.453592 kg
                } else {
                  _selectedWeight = value;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHealthGoalsStep() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Add this list of fitness goals options
  final List<String> fitnessGoalsOptions = [
    l10n.weight_loss,
    l10n.muscle_gain,
    l10n.improve_strength,
    l10n.increase_flexibility,
    l10n.better_endurance,
    l10n.general_fitness,
    l10n.sports_performance,
    l10n.body_recomposition,
    l10n.injury_recovery,
    l10n.maintain_health,
    l10n.improve_posture,
    l10n.better_balance,
  ];


  // Add this list of medical history options
  final List<String> medicalHistoryOptions = [
    l10n.high_blood_pressure,
    l10n.heart_disease,
    l10n.diabetes,
    l10n.asthma,
    l10n.arthritis,
    l10n.back_problems,
    l10n.joint_issues,
    l10n.respiratory_conditions,
    l10n.chronic_pain,
    l10n.anxiety_depression,
    l10n.thyroid_conditions,
    l10n.digestive_issues,
    l10n.allergies,
    l10n.sleep_disorders,
    l10n.other_medical_conditions,
  ];


  // Add this list of injuries and surgeries options
  final List<String> injuriesOptions = [
    l10n.acl_surgery,
    l10n.knee_replacement,
    l10n.hip_replacement,
    l10n.shoulder_surgery,
    l10n.back_surgery,
    l10n.meniscus_repair,
    l10n.rotator_cuff_injury,
    l10n.tennis_elbow,
    l10n.plantar_fasciitis,
    l10n.herniated_disc,
    l10n.sprained_ankle,
    l10n.carpal_tunnel,
    l10n.sports_injury,
    l10n.fracture_recovery,
    l10n.other_injury_surgery,
  ];


  // Add this list of dietary habits options
  final List<String> dietaryHabitsOptions = [
    l10n.vegetarian,
    l10n.vegan,
    l10n.gluten_free,
    l10n.dairy_free,
    l10n.keto_diet,
    l10n.paleo_diet,
    l10n.mediterranean_diet,
    l10n.low_carb,
    l10n.high_protein,
    l10n.food_allergies,
    l10n.intermittent_fasting,
    l10n.meal_prepping,
    l10n.calorie_tracking,
    l10n.no_dietary_restrictions,
    l10n.other_dietary_habits,
  ];


  // Add this list of exercise preferences options
  final List<String> exercisePreferencesOptions = [
    l10n.weight_training,
    l10n.cardio_running,
    l10n.hiit_workouts,
    l10n.yoga,
    l10n.pilates,
    l10n.swimming,
    l10n.cycling,
    l10n.boxing,
    l10n.martial_arts,
    l10n.group_classes,
    l10n.outdoor_activities,
    l10n.bodyweight_exercises,
    l10n.resistance_bands,
    l10n.crossfit_style,
    l10n.other_exercise_types,
  ];

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(0),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // Fitness Level Dropdown
              Text(
                l10n.current_fitness,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
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



            CustomSelectMultipleTextField(
              label: l10n.fitness_goals,
              hintText: l10n.what_achieve,
              controller: _goalsController,
              options: fitnessGoalsOptions,
              prefixIcon: Icons.fitness_center_outlined,
              onChanged: (List<String> selected) {
                _goalsController.text = selected.join(', ');
              },
              isRequired: false,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            CustomSelectMultipleTextField(
              label: l10n.medical_history,
              hintText: l10n.any_medical_conditions,
              controller: _medicalHistoryController,
              options: medicalHistoryOptions,
              prefixIcon: Icons.medical_services_outlined,
              onChanged: (List<String> selected) {
                _medicalHistoryController.text = selected.join(', ');
              },
              isRequired: false,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            CustomSelectMultipleTextField(
              label: l10n.injuries_surgeries,
              hintText: l10n.past_current_injuries,
              controller: _injuriesController,
              options: injuriesOptions,
              prefixIcon: Icons.personal_injury_outlined,
              onChanged: (List<String> selected) {
                _injuriesController.text = selected.join(', ');
              },
              isRequired: false,
              maxLines: 2,
            ),

            const SizedBox(height: 16),
            CustomSelectMultipleTextField(
              label: l10n.dietary_habits,
              hintText: l10n.special_diets,
              controller: _dietaryHabitsController,
              options: dietaryHabitsOptions,
              prefixIcon: Icons.restaurant_menu_outlined,
              onChanged: (List<String> selected) {
                _dietaryHabitsController.text = selected.join(', ');
              },
              isRequired: false,
              maxLines: 3,
            ),
            
            
            const SizedBox(height: 16),
            CustomSelectMultipleTextField(
              label: l10n.exercise_preferences,
              hintText: l10n.preferred_exercises,
              controller: _exercisePreferencesController,
              options: exercisePreferencesOptions,
              prefixIcon: Icons.fitness_center_outlined,
              onChanged: (List<String> selected) {
                _exercisePreferencesController.text = selected.join(', ');
              },
              isRequired: false,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAvailabilityStep(AppLocalizations l10n) {
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


  Widget _buildNavigationButtons() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.back,
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          if (_currentStep == 0)
            Expanded(
              // Add this to make it take the available width
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  width: double.infinity,
                  //alignment: Alignment.center, // This centers the content
                  child: SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < 3) {
                          setState(() {
                            _currentStep++;
                          });
                        } else {
                          _submitForm(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: myBlue60,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.next,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_currentStep < 3) {
                    setState(() {
                      _currentStep++;
                    });
                  } else {
                    _submitForm(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 102, 255),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep == 3 ? l10n.submit : l10n.next,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _submitForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState?.validate() ?? false) {
      final userData = context.read<UserProvider>().userData;
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.add_client,
            message: l10n.professional_data_not_found,
            type: SnackBarType.error,
          ),
        );
        return;
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

      final clientData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'birthday': _birthdayController.text,
        'gender': _selectedGender,
        'height': _selectedHeight,
        'weight': _selectedWeight,
        'goals': _goalsController.text,
        'currentFitnessLevel': _currentFitnessLevel.isEmpty ? 'Beginner' : _currentFitnessLevel,
        'availableHours': formattedAvailableHours.isEmpty ? {} : formattedAvailableHours,
        'medicalHistory': _medicalHistoryController.text,
        'injuries': _injuriesController.text,
        'dietaryHabits': _dietaryHabitsController.text,
        'exercisePreferences': _exercisePreferencesController.text,
        'connectionType': fbAddedManuallyConnectionType,
        'timestamp': DateTime.now().toIso8601String(),
        'status': fbCreatedStatusForNotAppUser,
        if (_selectedAvatarPath != null)
          'clientProfileImageUrl': _selectedAvatarPath,
      };

      context.read<AddClientBloc>().add(
            AddManualClient(
              data: clientData,
              professionalId: userData['userId'] ?? '',
              professionalRole: userData['role'] ?? '',
              context: context,
            ),
          );
    }
  }

  Widget _buildAvatarSelector() {
    //final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showImageSourceDialog(),
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _selectedAvatarPath != null 
            ? theme.brightness == Brightness.light ? const Color(0xFFFEF2ED) : myGrey70
            : theme.brightness == Brightness.light ? myGrey20 : myGrey80,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.brightness == Brightness.light ? myGrey40 : myGrey60),
        ),
        child: _selectedAvatarPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  _selectedAvatarPath!,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(
                Icons.add_a_photo_outlined,
                size: 40,
                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
              ),
      ),
    );
  }

  void _showImageSourceDialog() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb)
            ListTile(
              leading: Icon(Icons.photo_library, 
                color: theme.brightness == Brightness.light ? Colors.black : Colors.white),
              title: Text(
                l10n.choose_from_gallery,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  setState(() {
                    // Handle the selected image
                    // You might want to upload this to storage
                  });
                }
              },
            ),
            if (!isWebOrDesktopCached)
            ListTile(
              leading: Icon(Icons.camera_alt, 
                color: theme.brightness == Brightness.light ? Colors.black : Colors.white),
              title: Text(
                l10n.take_photo,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (photo != null) {
                  setState(() {
                    // Handle the taken photo
                    // You might want to upload this to storage
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.face, 
                color: theme.brightness == Brightness.light ? Colors.black : Colors.white),
              title: Text(
                l10n.select_avatar,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAvatarPicker();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarPicker() {
    //final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AvatarPickerDialog(
        onAvatarSelected: (String avatarPath) {
          setState(() {
            _selectedAvatarPath = avatarPath;
          });
        },
      ),
    );
  }

}
