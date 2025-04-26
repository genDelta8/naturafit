import 'package:naturafit/widgets/custom_fitness_level_slider.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_phone_number_field.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/notification_service.dart';

class AssessmentFormPage extends StatefulWidget {
  final String clientId;
  final String clientName;
  final bool isEnteredByTrainer;
  final bool dontShowRequestButton;
  final Map<String, dynamic>? existingForm;

  const AssessmentFormPage({
    Key? key,
    required this.clientId,
    required this.clientName,
    this.isEnteredByTrainer = false,
    this.existingForm,
    this.dontShowRequestButton = false,
  }) : super(key: key);

  @override
  State<AssessmentFormPage> createState() => _AssessmentFormPageState();
}

class _WalkingManSliderThumb extends SliderComponentShape {
  final double thumbRadius;
  final Color iconColor;
  final Color backgroundColor;

  const _WalkingManSliderThumb({
    required this.thumbRadius,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(PaintingContext context, Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = iconColor.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, thumbRadius + 2, shadowPaint);

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius, backgroundPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = iconColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, thumbRadius, borderPaint);

    // Draw walking man icon
    final icon = Icons.directions_walk;
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: thumbRadius * 1.2,
          fontFamily: icon.fontFamily,
          color: iconColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }
}

class _AssessmentFormPageState extends State<AssessmentFormPage> {
  int _currentStep = 0;
  final int _totalSteps = 6;
  double _waterIntake = 2.0;
  double _dailySteps = 5000;
  double _sleepHours = 7.0;
  String _selectedDietType = 'balanced';
  String _selectedFrequency = 'moderate';
  final Map<String, IconData> _dietIcons = {
    'balanced': Icons.restaurant_menu,
    'processed': Icons.fastfood,
    'protein': Icons.egg_alt,
    'other': Icons.more_horiz,
  };
  final Map<String, IconData> _frequencyIcons = {
    'rarely': Icons.calendar_month,
    'beginner': Icons.looks_one,
    'moderate': Icons.looks_3,
    'active': Icons.looks_5,
  };

  String _selectedMotivation = 'strength';
  final Map<String, IconData> _motivationIcons = {
    'strength': Icons.fitness_center,
    'aesthetics': Icons.sentiment_satisfied_alt,
    'health': Icons.favorite,
    'performance': Icons.speed,
    'lifestyle': Icons.psychology,
  };

  String _selectedLocation = 'gym';
  final Map<String, IconData> _locationIcons = {
    'gym': Icons.fitness_center,
    'home': Icons.home,
    'outdoor': Icons.park,
    'online': Icons.laptop,
    'hybrid': Icons.sync_alt,
    'studio': Icons.apartment,
  };

  final Map<String, TextEditingController> _detailsControllers = {};

  String _selectedDifficulty = 'Level 3';
  String _selectedDescription = '2-3× Exercise/Week';
  Map<String, bool> _exerciseComfort = {
    'Squats': false,
    'Push-ups': false,
    'Plank': false,
    'Pull-ups': false,
    'Running': false,
    'Lunges': false,
    'Deadlift': false,
    'Burpees': false,
  };

  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  String _phoneNumber = '';
  String _instagram = '';
  String _email = '';
  String _profession = '';

  final Map<String, bool> _yesNoAnswers = {};

  // Use a constant string key
  static const String DIFFICULT_EXERCISES_KEY = 'Any specific movements or exercises you struggle with?';
  static const String ADDITIONAL_COMMENTS_KEY = 'Any other comments or concerns?';

  // Add loading state variables
  bool _isSubmitting = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingForm != null) {
      _initializeWithExistingData();
    }
  }

  void _initializeWithExistingData() {
    final form = widget.existingForm!;
    
    // Basic Information
    final basicInfo = form['basicInformation'];
    if (basicInfo['phoneNumber'] != null) {
      final parts = basicInfo['phoneNumber'].toString().split('|');
      if (parts.length == 3) {
        // Format is "flagCode|countryCode|phoneNumber"
        _phoneNumberController.text = basicInfo['phoneNumber'];  // Pass the full string
      } else {
        _phoneNumberController.text = basicInfo['phoneNumber'];  // Fallback
      }
    }
    _instagramController.text = basicInfo['instagram'] ?? '';
    _emailController.text = basicInfo['email'] ?? '';
    _professionController.text = basicInfo['profession'] ?? '';

    // Health History
    final healthHistory = form['healthHistory'];
    
    // First initialize all controllers
    _detailsControllers.putIfAbsent('Do you have any medical conditions?', () => TextEditingController());
    _detailsControllers.putIfAbsent('Do you have any past injuries or surgeries?', () => TextEditingController());
    _detailsControllers.putIfAbsent('Are you currently taking any medications?', () => TextEditingController());
    _detailsControllers.putIfAbsent('Do you experience any pain or discomfort during physical activity?', () => TextEditingController());
    _detailsControllers.putIfAbsent('Do you have any allergies or dietary restrictions?', () => TextEditingController());

    setState(() {
      // Initialize yes/no answers
      _yesNoAnswers['Do you have any medical conditions?'] = healthHistory['hasMedicalConditions'] ?? false;
      _yesNoAnswers['Do you have any past injuries or surgeries?'] = healthHistory['hasInjuries'] ?? false;
      _yesNoAnswers['Are you currently taking any medications?'] = healthHistory['hasMedications'] ?? false;
      _yesNoAnswers['Do you experience any pain or discomfort during physical activity?'] = healthHistory['hasPain'] ?? false;
      _yesNoAnswers['Do you have any allergies or dietary restrictions?'] = healthHistory['hasAllergies'] ?? false;
      
      // Set text values
      _detailsControllers['Do you have any medical conditions?']!.text = healthHistory['medicalConditions'] ?? '';
      _detailsControllers['Do you have any past injuries or surgeries?']!.text = healthHistory['injuries'] ?? '';
      _detailsControllers['Are you currently taking any medications?']!.text = healthHistory['medications'] ?? '';
      _detailsControllers['Do you experience any pain or discomfort during physical activity?']!.text = healthHistory['painDetails'] ?? '';
      _detailsControllers['Do you have any allergies or dietary restrictions?']!.text = healthHistory['allergies'] ?? '';
    });

    // Lifestyle Activity
    final lifestyle = form['lifestyleActivity'];
    setState(() {
      _sleepHours = lifestyle['sleepHours']?.toDouble() ?? 7.0;
      _waterIntake = lifestyle['waterIntake']?.toDouble() ?? 2.0;
      _dailySteps = lifestyle['dailySteps']?.toDouble() ?? 5000;
      _selectedDietType = lifestyle['dietType'] ?? 'balanced';
    });
    _detailsControllers['Diet details']?.text = lifestyle['dietDetails'] ?? '';

    // Fitness Strength
    final fitness = form['fitnessStrength'];
    
    // Initialize controller for difficult exercises
    _detailsControllers.putIfAbsent(DIFFICULT_EXERCISES_KEY, () => TextEditingController());
    
    setState(() {
      _selectedFrequency = fitness['exerciseFrequency'] ?? 'moderate';
      _selectedDifficulty = fitness['fitnessLevel'] ?? 'Level 3';
      _exerciseComfort = Map<String, bool>.from(fitness['exerciseComfort'] ?? {});
      _yesNoAnswers[DIFFICULT_EXERCISES_KEY] = fitness['hasDifficultExercises'] ?? false;
      
      // Set text inside setState
      _detailsControllers[DIFFICULT_EXERCISES_KEY]!.text = fitness['difficultExercises'] ?? '';
    });

    // Additional Notes
    final notes = form['additionalNotes'];
    
    // Initialize controllers for goals and comments
    _detailsControllers.putIfAbsent('What are your short-term (3-month) goals?', () => TextEditingController());
    _detailsControllers.putIfAbsent('What are your long-term (6-12 month) goals?', () => TextEditingController());
    _detailsControllers.putIfAbsent(ADDITIONAL_COMMENTS_KEY, () => TextEditingController());  // Add this line
    
    setState(() {
      _selectedMotivation = notes['primaryMotivation'] ?? 'strength';
      _selectedLocation = notes['preferredLocation'] ?? 'gym';
      
      // Set text values for goals and comments
      _detailsControllers['What are your short-term (3-month) goals?']!.text = notes['shortTermGoals'] ?? '';
      _detailsControllers['What are your long-term (6-12 month) goals?']!.text = notes['longTermGoals'] ?? '';
      _detailsControllers[ADDITIONAL_COMMENTS_KEY]!.text = notes['additionalComments'] ?? '';
    });
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
        ),
      ),
    );
  }

  Widget _buildYesNoQuestion(String question, {String? details}) {
    final theme = Theme.of(context);
    
    // Initialize controller if it doesn't exist
    _detailsControllers.putIfAbsent(question, () => TextEditingController());
    if (!_yesNoAnswers.containsKey(question)) {
      _yesNoAnswers[question] = false;  // Default to No
    }

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnswerOption(
                  label: 'No',
                  icon: Icons.close_rounded,
                  color: myRed50,
                  isSelected: !_yesNoAnswers[question]!,
                  onTap: () => setState(() => _yesNoAnswers[question] = false),
                ),
                _buildAnswerOption(
                  label: 'Yes',
                  icon: Icons.check_rounded,
                  color: myGreen50,
                  isSelected: _yesNoAnswers[question]!,
                  onTap: () => setState(() => _yesNoAnswers[question] = true),
                ),
              ],
            ),
            if (details != null && _yesNoAnswers[question]!) ...[
              const SizedBox(height: 12),
              CustomFocusTextField(
                label: '',
                prefixIcon: Icons.info_outline,
                hintText: details,
                controller: _detailsControllers[question]!,
                shouldDisable: widget.isEnteredByTrainer,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOption({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: widget.isEnteredByTrainer ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : myGrey40,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : myGrey40,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : myGrey40,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label) {
    final theme = Theme.of(context);
    
    // Initialize controller if not exists
    _detailsControllers.putIfAbsent(label, () => TextEditingController());

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 0,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Add this
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4), // Add this to align icon with first line
                    child: Icon(
                      Icons.edit_note,
                      color: myBlue60,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded( // Add this
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CustomFocusTextField(
                label: '',
                hintText: 'Enter details...',
                controller: _detailsControllers[label]!,
                maxLines: 3,
                shouldDisable: widget.isEnteredByTrainer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceCard({
    required String question,
    required List<String> options,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.brightness == Brightness.light
                    ? myGrey90
                    : Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...options
                .map((option) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light
                            ? myGrey20.withOpacity(0.5)
                            : myGrey80,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.brightness == Brightness.light
                              ? myGrey30
                              : myGrey70,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.brightness == Brightness.light
                                    ? myGrey40
                                    : myGrey60,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            option,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.brightness == Brightness.light
                                  ? myGrey90
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCheckList() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: myBlue60,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Exercise Experience',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Select exercises you feel uncomfortable performing:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.brightness == Brightness.light ? myGrey60 : myGrey40,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _exerciseComfort.length,
              itemBuilder: (context, index) {
                final exercise = _exerciseComfort.keys.elementAt(index);
                final isSelected = _exerciseComfort[exercise] ?? false;

                return GestureDetector(
                  onTap: widget.isEnteredByTrainer ? null : () {
                    setState(() {
                      _exerciseComfort[exercise] = !isSelected;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? myRed50.withOpacity(0.1)
                          : theme.brightness == Brightness.light
                              ? myGrey20.withOpacity(0.5)
                              : myGrey80,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? myRed50
                            : theme.brightness == Brightness.light
                                ? myGrey30
                                : myGrey70,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _getExerciseIcon(exercise),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  exercise,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isSelected
                                        ? myRed50
                                        : theme.brightness == Brightness.light
                                            ? myGrey90
                                            : Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: myRed50,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Icon _getExerciseIcon(String exercise) {
    switch (exercise.toLowerCase()) {
      case 'squats':
        return Icon(Icons.accessibility_new, color: myRed50, size: 20);
      case 'push-ups':
        return Icon(Icons.fitness_center, color: myRed50, size: 20);
      case 'plank':
        return Icon(Icons.horizontal_rule, color: myRed50, size: 20);
      case 'pull-ups':
        return Icon(Icons.trending_up, color: myRed50, size: 20);
      case 'running':
        return Icon(Icons.directions_run, color: myRed50, size: 20);
      case 'lunges':
        return Icon(Icons.accessibility, color: myRed50, size: 20);
      case 'deadlift':
        return Icon(Icons.fitness_center, color: myRed50, size: 20);
      case 'burpees':
        return Icon(Icons.swap_vert, color: myRed50, size: 20);
      default:
        return Icon(Icons.sports_gymnastics, color: myRed50, size: 20);
    }
  }

  Widget _preferredTrainingLocationCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: myBlue60,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Preferred Training Location',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _locationIcons.length,
              itemBuilder: (context, index) {
                final type = _locationIcons.keys.elementAt(index);
                final isSelected = _selectedLocation == type;

                return GestureDetector(
                  onTap: widget.isEnteredByTrainer ? null : () {
                    setState(() {
                      _selectedLocation = type;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? myBlue60.withOpacity(0.1)
                          : theme.brightness == Brightness.light
                              ? myGrey20.withOpacity(0.5)
                              : myGrey80,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? myBlue60
                            : theme.brightness == Brightness.light
                                ? myGrey30
                                : myGrey70,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: myBlue60,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? myBlue60.withOpacity(0.2)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _locationIcons[type],
                                  color: isSelected
                                      ? myBlue60
                                      : theme.brightness == Brightness.light
                                          ? myGrey60
                                          : myGrey40,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getLocationLabel(type),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isSelected
                                      ? myBlue60
                                      : theme.brightness == Brightness.light
                                          ? myGrey90
                                          : Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (_selectedLocation == 'hybrid')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  '* Hybrid training combines multiple locations based on your preferences and schedule',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.brightness == Brightness.light
                        ? myGrey60
                        : myGrey40,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getLocationLabel(String type) {
    switch (type) {
      case 'gym':
        return 'Gym';
      case 'home':
        return 'Home';
      case 'outdoor':
        return 'Outdoor';
      case 'online':
        return 'Online';
      case 'hybrid':
        return 'Hybrid';
      case 'studio':
        return 'Studio';
      default:
        return 'Select Location';
    }
  }

  Widget _motivationCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.stars_outlined,
                  color: myBlue60,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Primary Motivation',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          children: [
                            // Animated background
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.brightness == Brightness.light
                                    ? myGrey20
                                    : myGrey80,
                                border: Border.all(
                                  color: myBlue60,
                                  width: 2,
                                ),
                              ),
                            ),
                            // Animated icon
                            Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return RotationTransition(
                                    turns: animation,
                                    child: ScaleTransition(
                                      scale: animation,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    ),
                                  );
                                },
                                child: Icon(
                                  _motivationIcons[_selectedMotivation],
                                  key: ValueKey(_selectedMotivation),
                                  color: myBlue60,
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getMotivationLabel(_selectedMotivation),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: myBlue60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMotivationDescription(_selectedMotivation),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.brightness == Brightness.light
                              ? myGrey60
                              : myGrey40,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildMotivationOption('strength', 'Strength & Power'),
                      const SizedBox(height: 8),
                      _buildMotivationOption('aesthetics', 'Body Aesthetics'),
                      const SizedBox(height: 8),
                      _buildMotivationOption('health', 'Health & Wellness'),
                      const SizedBox(height: 8),
                      _buildMotivationOption(
                          'performance', 'Sports Performance'),
                      const SizedBox(height: 8),
                      _buildMotivationOption('lifestyle', 'Lifestyle Change'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationOption(String type, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedMotivation == type;

    return GestureDetector(
      onTap: widget.isEnteredByTrainer ? null : () {
        setState(() {
          _selectedMotivation = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? myBlue60.withOpacity(0.1)
              : theme.brightness == Brightness.light
                  ? myGrey20.withOpacity(0.5)
                  : myGrey80,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? myBlue60
                : theme.brightness == Brightness.light
                    ? myGrey30
                    : myGrey70,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _motivationIcons[type],
              color: isSelected
                  ? myBlue60
                  : theme.brightness == Brightness.light
                      ? myGrey60
                      : myGrey40,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? myBlue60
                      : theme.brightness == Brightness.light
                          ? myGrey90
                          : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMotivationLabel(String type) {
    switch (type) {
      case 'strength':
        return 'Strength & Power';
      case 'aesthetics':
        return 'Body Aesthetics';
      case 'health':
        return 'Health & Wellness';
      case 'performance':
        return 'Sports Performance';
      case 'lifestyle':
        return 'Lifestyle Change';
      default:
        return 'Select Motivation';
    }
  }

  String _getMotivationDescription(String type) {
    switch (type) {
      case 'strength':
        return 'Focus on building strength and muscle power';
      case 'aesthetics':
        return 'Improve physical appearance and body composition';
      case 'health':
        return 'Enhance overall health and well-being';
      case 'performance':
        return 'Improve athletic performance and skills';
      case 'lifestyle':
        return 'Create lasting healthy habits and lifestyle changes';
      default:
        return '';
    }
  }

  Widget _howOftenCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: myBlue60,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Exercise Frequency',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          children: [
                            // Background circle
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.brightness == Brightness.light
                                    ? myGrey20
                                    : myGrey80,
                                border: Border.all(
                                  color: theme.brightness == Brightness.light
                                      ? myGrey30
                                      : myGrey70,
                                  width: 2,
                                ),
                              ),
                            ),
                            // Animated frequency icon
                            Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  key: ValueKey(_selectedFrequency),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _frequencyIcons[_selectedFrequency] ??
                                          Icons.calendar_month,
                                      color: myBlue60,
                                      size: 32,
                                    ),
                                    Text(
                                      _getFrequencyShortLabel(
                                          _selectedFrequency),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: myBlue60,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getFrequencyLabel(_selectedFrequency),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: myBlue60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildFrequencyOption('rarely', 'Rarely'),
                      const SizedBox(height: 8),
                      _buildFrequencyOption('beginner', '1-2x/week'),
                      const SizedBox(height: 8),
                      _buildFrequencyOption('moderate', '3-4x/week'),
                      const SizedBox(height: 8),
                      _buildFrequencyOption('active', '5+ times/week'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(String type, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedFrequency == type;

    return GestureDetector(
      onTap: widget.isEnteredByTrainer ? null : () {
        setState(() {
          _selectedFrequency = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? myBlue60.withOpacity(0.1)
              : theme.brightness == Brightness.light
                  ? myGrey20.withOpacity(0.5)
                  : myGrey80,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? myBlue60
                : theme.brightness == Brightness.light
                    ? myGrey30
                    : myGrey70,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _frequencyIcons[type] ?? Icons.calendar_month,
              color: isSelected
                  ? myBlue60
                  : theme.brightness == Brightness.light
                      ? myGrey60
                      : myGrey40,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? myBlue60
                      : theme.brightness == Brightness.light
                          ? myGrey90
                          : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFrequencyLabel(String type) {
    switch (type) {
      case 'rarely':
        return 'Rarely';
      case 'beginner':
        return '1-2 times/week';
      case 'moderate':
        return '3-4 times/week';
      case 'active':
        return '5+ times/week';
      default:
        return 'Select Frequency';
    }
  }

  String _getFrequencyShortLabel(String type) {
    switch (type) {
      case 'rarely':
        return '0x';
      case 'beginner':
        return '1-2x';
      case 'moderate':
        return '3-4x';
      case 'active':
        return '5+x';
      default:
        return '';
    }
  }

  Widget _dietCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.restaurant_outlined,
                  color: myBlue60,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Diet Description',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDietOption('balanced', 'Balanced', Icons.restaurant_menu),
                _buildDietOption('protein', 'High Protein', Icons.egg_alt),
                _buildDietOption('processed', 'Processed', Icons.fastfood),
                _buildDietOption('other', 'Other', Icons.more_horiz),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietOption(String value, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _selectedDietType == value;
    
    return GestureDetector(
      onTap: widget.isEnteredByTrainer ? null : () {
        setState(() {
          _selectedDietType = value;
        });
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected 
                  ? myBlue60.withOpacity(0.1)
                  : theme.brightness == Brightness.light 
                      ? myGrey20.withOpacity(0.5)
                      : myGrey80,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? myBlue60
                    : theme.brightness == Brightness.light 
                        ? myGrey30 
                        : myGrey70,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? myBlue60 : theme.brightness == Brightness.light ? myGrey60 : myGrey40,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected 
                  ? myBlue60
                  : theme.brightness == Brightness.light ? myGrey90 : Colors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sleepHoursCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bedtime_outlined,
                  color: myBlue60,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sleep Hours',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.light
                        ? myGrey90
                        : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background gradient circle
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  myBlue60.withOpacity(0.1),
                                  theme.brightness == Brightness.light
                                      ? myGrey20
                                      : myGrey80,
                                ],
                              ),
                              border: Border.all(
                                color: theme.brightness == Brightness.light
                                    ? myGrey30
                                    : myGrey70,
                                width: 2,
                              ),
                            ),
                          ),
                          // Progress circle
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: _sleepHours / 12,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                myBlue60,
                              ),
                              strokeWidth: 10,
                            ),
                          ),
                          // Moon icon with glow effect
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: myBlue60.withOpacity(0.1),
                              boxShadow: [
                                BoxShadow(
                                  color: myBlue60.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.nightlight_round,
                              color: myBlue60,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _sleepHours.toStringAsFixed(1),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: myBlue60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'hours',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.brightness == Brightness.light
                                  ? myGrey60
                                  : myGrey40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 48),
                Container(
                  width: 120,
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light
                        ? myGrey20.withOpacity(0.5)
                        : myGrey80,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.brightness == Brightness.light
                          ? myGrey30
                          : myGrey70,
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimeLabel('12h', _sleepHours >= 11),
                          _buildTimeLabel(
                              '8h', _sleepHours >= 7 && _sleepHours < 9),
                          _buildTimeLabel('4h', _sleepHours <= 5),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: myBlue60,
                              inactiveTrackColor:
                                  theme.brightness == Brightness.light
                                      ? myGrey30
                                      : myGrey70,
                              thumbColor: Colors.white,
                              overlayColor: myBlue60.withOpacity(0.2),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                                elevation: 4,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                            ),
                            child: Slider(
                              value: _sleepHours,
                              min: 4,
                              max: 12,
                              divisions: 16,
                              onChanged: widget.isEnteredByTrainer ? null : (value) {
                                setState(() {
                                  _sleepHours = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeLabel(String label, bool isHighlighted) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? myBlue60 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isHighlighted
              ? Colors.white
              : theme.brightness == Brightness.light
                  ? myGrey60
                  : myGrey40,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _dailyStepsCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_walk_outlined,
                  color: myBlue60,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Daily Steps',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Container(
                      width: 120,
                      alignment: Alignment.center,
                      child: Text(
                        _dailySteps.toStringAsFixed(0),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: myBlue60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'steps',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light 
                          ? myGrey20.withOpacity(0.5)
                          : myGrey80,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.brightness == Brightness.light 
                            ? myGrey30 
                            : myGrey70,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStepsLabel('1K', _dailySteps <= 2000),
                            _buildStepsLabel('7.5K', _dailySteps >= 7000 && _dailySteps <= 8000),
                            _buildStepsLabel('15K', _dailySteps >= 14000),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: myBlue60,
                            inactiveTrackColor: theme.brightness == Brightness.light 
                                ? myGrey30 
                                : myGrey70,
                            trackHeight: 4,
                            thumbShape: _WalkingManSliderThumb(
                              thumbRadius: 16,
                              iconColor: myBlue60,
                              backgroundColor: Colors.white,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 24,
                            ),
                            overlayColor: myBlue60.withOpacity(0.1),
                          ),
                          child: Slider(
                            value: _dailySteps,
                            min: 1000,
                            max: 15000,
                            divisions: 140,
                            onChanged: widget.isEnteredByTrainer ? null : (value) {
                              setState(() {
                                _dailySteps = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsLabel(String label, bool isHighlighted) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? myBlue60 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isHighlighted 
              ? Colors.white
              : theme.brightness == Brightness.light ? myGrey60 : myGrey40,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _waterIntakeCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  color: myBlue60,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Daily Water Intake',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    _buildWaterCup(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _waterIntake >= 5 ? '5.0+' : _waterIntake.toStringAsFixed(1),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: myBlue60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'L',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 48),
                Container(
                  width: 120,
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light 
                        ? myGrey20.withOpacity(0.5)
                        : myGrey80,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.brightness == Brightness.light 
                          ? myGrey30 
                          : myGrey70,
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildWaterLabel('5L+', _waterIntake >= 5),
                          _buildWaterLabel('3L', _waterIntake >= 2.5 && _waterIntake < 3.5),
                          _buildWaterLabel('0L', _waterIntake <= 0.5),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: myBlue60,
                              inactiveTrackColor: theme.brightness == Brightness.light 
                                  ? myGrey30 
                                  : myGrey70,
                              thumbColor: Colors.white,
                              overlayColor: myBlue60.withOpacity(0.2),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                                elevation: 4,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                            ),
                            child: Slider(
                              value: _waterIntake,
                              min: 0,
                              max: 5,
                              divisions: 50,
                              onChanged: widget.isEnteredByTrainer ? null : (value) {
                                setState(() {
                                  _waterIntake = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterLabel(String label, bool isHighlighted) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? myBlue60 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isHighlighted 
              ? Colors.white
              : theme.brightness == Brightness.light ? myGrey60 : myGrey40,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildWaterCup() {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(
          color: myBlue60,
          width: 3,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: (74 * (_waterIntake / 5)).clamp(0.0, 74.0),
            child: Container(
              decoration: BoxDecoration(
                color: myBlue60.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
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
            icon: Icon(
              Icons.chevron_left,
              color: theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          l10n.assessment_form,
          style: GoogleFonts.plusJakartaSans(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: (!widget.isEnteredByTrainer || widget.dontShowRequestButton) ? [] : [
          TextButton(
            onPressed: _isRequesting ? null : _handleAssessmentRequest,
            child: Container(
              decoration: BoxDecoration(
                color: myBlue40,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: myBlue60,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isRequesting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.request,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalSteps,
                (index) => Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index <= _currentStep ? myBlue60 : myGrey30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStepTitle(_currentStep),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.light
                              ? myGrey90
                              : Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildStepContent(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: theme.brightness == Brightness.light
                      ? myGrey30
                      : myGrey80,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: myBlue60,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chevron_left,
                            color: myBlue60,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.back,
                            style: GoogleFonts.plusJakartaSans(
                              color: myBlue60,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 80),
                Text(
                  '${_currentStep + 1}/$_totalSteps',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.light
                        ? myGrey60
                        : myGrey40,
                  ),
                ),
                if ((_currentStep < _totalSteps - 1 && widget.isEnteredByTrainer) || (_currentStep < _totalSteps && !widget.isEnteredByTrainer))
                  GestureDetector(
                    onTap: _isSubmitting ? null : () {
                      if (_currentStep == _totalSteps - 1 && !widget.isEnteredByTrainer) {
                        _handleAssessmentSubmit();
                      } else {
                        setState(() {
                          _currentStep++;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: myBlue60,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSubmitting && _currentStep == _totalSteps - 1 && !widget.isEnteredByTrainer)
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(myBlue60),
                              ),
                            )
                          else
                            Text(
                              (_currentStep == _totalSteps - 1 && !widget.isEnteredByTrainer) ? l10n.submit : l10n.next,
                              style: GoogleFonts.plusJakartaSans(
                                color: myBlue60,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          if (!(_currentStep == _totalSteps - 1 && !widget.isEnteredByTrainer))
                            Icon(
                              Icons.chevron_right,
                              color: myBlue60,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    final l10n = AppLocalizations.of(context)!;
    switch (step) {
      case 0:
        return l10n.basic_information;
      case 1:
        return l10n.health_medical_history;
      case 2:
        return l10n.lifestyle_activity;
      case 3:
        return l10n.fitness_strength;
      case 4:
        return l10n.additional_notes;
      default:
        return '';
    }
  }

  Future<void> _handleAssessmentSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    
    final l10n = AppLocalizations.of(context)!;
    try {
      // Get the assessment form for this client
      final clientAssessmentQuery = await FirebaseFirestore.instance
          .collection('assessment_forms')
          .doc(widget.clientId)
          .collection('all_forms')
          .where('status', isEqualTo: 'pending')
          .get();

      if (clientAssessmentQuery.docs.isEmpty) {
        throw 'Assessment form not found';
      }

      final formId = clientAssessmentQuery.docs.first.id;
      final trainerId = clientAssessmentQuery.docs.first.data()['trainerId'];

      // Prepare the updated form data
      final updatedForm = {
        'status': 'completed',
        'isCompleted': true,
        'lastUpdated': FieldValue.serverTimestamp(),
        'completedDate': FieldValue.serverTimestamp(),
        'clientId': widget.clientId,  // Make sure we store this
        
        'basicInformation': {
          'phoneNumber': _phoneNumberController.text,
          'instagram': _instagramController.text,
          'email': _emailController.text,
          'profession': _professionController.text,
        },
        
        'healthHistory': {
          'hasMedicalConditions': _yesNoAnswers['Do you have any medical conditions?'] ?? false,
          'medicalConditions': _detailsControllers['Do you have any medical conditions?']?.text ?? '',
          'hasInjuries': _yesNoAnswers['Do you have any past injuries or surgeries?'] ?? false,
          'injuries': _detailsControllers['Do you have any past injuries or surgeries?']?.text ?? '',
          'hasMedications': _yesNoAnswers['Are you currently taking any medications?'] ?? false,
          'medications': _detailsControllers['Are you currently taking any medications?']?.text ?? '',
          'hasPain': _yesNoAnswers['Do you experience any pain or discomfort during physical activity?'] ?? false,
          'painDetails': _detailsControllers['Do you experience any pain or discomfort during physical activity?']?.text ?? '',
          'hasAllergies': _yesNoAnswers['Do you have any allergies or dietary restrictions?'] ?? false,
          'allergies': _detailsControllers['Do you have any allergies or dietary restrictions?']?.text ?? '',
        },
        
        'lifestyleActivity': {
          'sleepHours': _sleepHours,
          'waterIntake': _waterIntake,
          'dailySteps': _dailySteps,
          'dietType': _selectedDietType,
          'dietDetails': _detailsControllers['Diet details']?.text ?? '',
        },
        
        'fitnessStrength': {
          'exerciseFrequency': _selectedFrequency,
          'fitnessLevel': _selectedDifficulty,
          'exerciseComfort': _exerciseComfort,
          'hasDifficultExercises': _yesNoAnswers[DIFFICULT_EXERCISES_KEY] ?? false,
          'difficultExercises': _detailsControllers[DIFFICULT_EXERCISES_KEY]?.text ?? '',
        },
        
        'additionalNotes': {
          'shortTermGoals': _detailsControllers['What are your short-term (3-month) goals?']?.text ?? '',
          'longTermGoals': _detailsControllers['What are your long-term (6-12 month) goals?']?.text ?? '',
          'primaryMotivation': _selectedMotivation,
          'preferredLocation': _selectedLocation,
          'additionalComments': _detailsControllers[ADDITIONAL_COMMENTS_KEY]?.text ?? '',
        },
      };

      // Update both client and trainer copies
      final batch = FirebaseFirestore.instance.batch();

      // Update client's copy
      final clientRef = FirebaseFirestore.instance
          .collection('assessment_forms')
          .doc(widget.clientId)
          .collection('all_forms')
          .doc(formId);

      // Update trainer's copy
      final trainerRef = FirebaseFirestore.instance
          .collection('assessment_forms')
          .doc(trainerId)
          .collection('all_forms')
          .doc(formId);

      batch.update(clientRef, updatedForm);
      batch.update(trainerRef, updatedForm);

      await batch.commit();

      // Delete the assessment request notification
      final notificationsQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.clientId)
          .collection('allNotifications')
          .where('type', isEqualTo: 'assessment_request')
          .where('relatedDocId', isEqualTo: formId)
          .get();

      if (notificationsQuery.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(widget.clientId)
            .collection('allNotifications')
            .doc(notificationsQuery.docs.first.id)
            .delete();
      }

      // Send notification to trainer
      await NotificationService().createAssessmentSubmittedNotification(
        userId: trainerId,
        title: l10n.assessment_form,
        message: l10n.has_submitted_assessment(widget.clientName),
        data: {
          'clientId': widget.clientId,
          'clientName': widget.clientName,
          'formId': formId,
          'status': 'completed',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.assessment_form,
            message: l10n.assessment_submitted,
            type: SnackBarType.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error submitting assessment form: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.assessment_form,
            message: l10n.error_submitting_assessment,
            type: SnackBarType.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleAssessmentRequest() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    try {
      // Get trainer data from UserProvider
      final userData = context.read<UserProvider>().userData;
      if (userData == null) return;

      // Create a unique form ID
      final formId = FirebaseFirestore.instance.collection('assessment_forms').doc().id;

      // Create assessment form document
      final assessmentForm = {
        'formId': formId,
        'clientId': widget.clientId,
        'trainerId': userData['userId'],
        'clientName': widget.clientName,
        'trainerName': userData['fullName'] ?? userData['name'],
        //'clientProfileImageUrl': widget.client['clientProfileImageUrl'] ?? '',
        'trainerProfileImageUrl': userData['profileImageUrl'] ?? '',
        'requestedDate': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, completed, rejected
        'isCompleted': false,
        
        // Form fields (initially empty)
        'basicInformation': {
          'phoneNumber': '',
          'instagram': '',
          'email': '',
          'profession': '',
        },
        
        'healthHistory': {
          'hasMedicalConditions': false,
          'medicalConditions': '',
          'hasInjuries': false,
          'injuries': '',
          'hasMedications': false,
          'medications': '',
          'hasPain': false,
          'painDetails': '',
          'hasAllergies': false,
          'allergies': '',
        },
        
        'lifestyleActivity': {
          'sleepHours': 0.0,
          'waterIntake': 0.0,
          'dailySteps': 0,
          'dietType': '',
          'dietDetails': '',
        },
        
        'fitnessStrength': {
          'exerciseFrequency': '',
          'fitnessLevel': '',
          'exerciseComfort': {
            'Squats': false,
            'Push-ups': false,
            'Plank': false,
            'Pull-ups': false,
            'Running': false,
            'Lunges': false,
            'Deadlift': false,
            'Burpees': false,
          },
          'difficultExercises': '',
        },
        
        'additionalNotes': {
          'shortTermGoals': '',
          'longTermGoals': '',
          'primaryMotivation': '',
          'preferredLocation': '',
          'additionalComments': '',
        },
      };

      // Store for client
      await FirebaseFirestore.instance
          .collection('assessment_forms')
          .doc(widget.clientId)
          .collection('all_forms')
          .doc(formId)
          .set(assessmentForm);

      // Store for trainer
      await FirebaseFirestore.instance
          .collection('assessment_forms')
          .doc(userData['userId'])
          .collection('all_forms')
          .doc(formId)
          .set(assessmentForm);

      // Send notification to client
      await NotificationService().createAssessmentRequestNotification(
        clientId: widget.clientId,
        trainerId: userData['userId'],
        assessmentId: formId,
        trainerData: userData,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.assessment_form,
            message: l10n.assessment_request_sent,
            type: SnackBarType.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error sending assessment request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.error_sending_assessment,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
              ),
            ),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  Widget _buildStepContent() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomPhoneNumberField(
              controller: _phoneNumberController,
              passedHintText: 'Client\'s phone number',
              shouldDisable: widget.isEnteredByTrainer,
              onChanged: (value) {
                setState(() {
                  _phoneNumber = value;
                });
              },
            ),
            const SizedBox(height: 12),
            CustomFocusTextField(
              label: 'Instagram',
              hintText: 'Name or Link',
              prefixIcon: Icons.camera_alt_outlined,
              controller: _instagramController,
              shouldDisable: widget.isEnteredByTrainer,
              onChanged: (value) {
                setState(() {
                  _instagram = value;
                });
              },
            ),
            const SizedBox(height: 12),
            CustomFocusTextField(
              label: 'Email',
              hintText: 'Email',
              prefixIcon: Icons.email_outlined,
              controller: _emailController,
              shouldDisable: widget.isEnteredByTrainer,
              onChanged: (value) {
                setState(() {
                  _email = value;
                });
              },
            ),
            const SizedBox(height: 12),
            CustomFocusTextField(
              label: 'Main Activities',
              hintText: 'e.g. Work, Study, etc.',
              prefixIcon: Icons.work_outline,
              controller: _professionController,
              shouldDisable: widget.isEnteredByTrainer,
              onChanged: (value) {
                setState(() {
                  _profession = value;
                });
              },
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildYesNoQuestion(
              l10n.medical_conditions_question,
              details: l10n.if_yes_specify,
            ),
            const SizedBox(height: 16),
            _buildYesNoQuestion(
              l10n.injuries_question,
              details: l10n.if_yes_specify,
            ),
            const SizedBox(height: 16),
            _buildYesNoQuestion(
              l10n.medications_question,
              details: l10n.if_yes_specify,
            ),
            const SizedBox(height: 16),
            _buildYesNoQuestion(
              l10n.pain_during_activity,
              details: l10n.if_yes_specify,
            ),
            const SizedBox(height: 16),
            _buildYesNoQuestion(
              l10n.allergies_question,
              details: l10n.if_yes_specify,
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _sleepHoursCard(),
            const SizedBox(height: 12),
            _dietCard(),
            const SizedBox(height: 12),
            _dailyStepsCard(),
            const SizedBox(height: 12),
            _waterIntakeCard(),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _howOftenCard(),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: myBlue60,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Fitness Level',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CustomFitnessLevelSlider(
                      initialLevel: _selectedDifficulty,
                      shouldDisable: widget.isEnteredByTrainer,
                      onLevelChanged: (String description) {
                        setState(() {
                          _selectedDescription = description;
                          if (description == '0-1× Exercise/Week') {
                            _selectedDifficulty = 'Level 1';
                          } else if (description == '1-2× Exercise/Week') {
                            _selectedDifficulty = 'Level 2';
                          } else if (description == '2-3× Exercise/Week') {
                            _selectedDifficulty = 'Level 3';
                          } else if (description == '3-4× Exercise/Week') {
                            _selectedDifficulty = 'Level 4';
                          } else if (description == '4-5× Exercise/Week') {
                            _selectedDifficulty = 'Level 5';
                          }
                        });
                      },
                      isDifficultySlider: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildExerciseCheckList(),
            const SizedBox(height: 12),
            _buildYesNoQuestion(
              l10n.difficult_exercises,
              details: l10n.if_yes_specify,
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _motivationCard(),
            const SizedBox(height: 12),
            _buildTextField(l10n.short_term_goals),
            const SizedBox(height: 12),
            _buildTextField(l10n.long_term_goals),
            
            /*
            _buildMultipleChoiceCard(
              question: l10n.motivation,
              options: [
                l10n.strength,
                l10n.aesthetics,
                l10n.health,
                l10n.sports_performance,
                l10n.other,
              ],
            ),
            */
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _preferredTrainingLocationCard(),
            const SizedBox(height: 12),
            _buildTextField(l10n.additional_comments),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}