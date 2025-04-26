import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/ingredients_data.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/client_selection_sheet.dart';
import 'package:naturafit/widgets/custom_loading_view.dart';
import 'package:naturafit/widgets/custom_select_exercise_textfield.dart';
import 'package:naturafit/widgets/custom_select_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:naturafit/widgets/custom_step_indicator.dart'; // Add this import
import 'package:naturafit/widgets/custom_top_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/models/selected_ingredient.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/services/notification_service.dart'; // Add this import
import 'package:flutter/gestures.dart';

class CreateMealPlanPage extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? existingPlan;
  final bool isUsingTemplate;

  const CreateMealPlanPage({
    Key? key,
    this.isEditing = false,
    this.existingPlan,
    this.isUsingTemplate = false,
  }) : super(key: key);

  @override
  State<CreateMealPlanPage> createState() => _CreateMealPlanPageState();
}

class _CreateMealPlanPageState extends State<CreateMealPlanPage> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => MealPlanBloc(context)),
      ],
      child: _CreateMealPlanContent(
        isEditing: widget.isEditing,
        existingPlan: widget.existingPlan,
        isUsingTemplate: widget.isUsingTemplate,
      ),
    );
  }
}

class _CreateMealPlanContent extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? existingPlan;
  final bool isUsingTemplate;
  const _CreateMealPlanContent({
    this.isEditing = false,
    this.existingPlan,
    this.isUsingTemplate = false,
  });

  @override
  _CreateMealPlanContentState createState() => _CreateMealPlanContentState();
}

class _CreateMealPlanContentState extends State<_CreateMealPlanContent>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final List<MealDay> mealDays = [
    MealDay.empty('Monday'),
    MealDay.empty('Tuesday'),
    MealDay.empty('Wednesday'),
    MealDay.empty('Thursday'),
    MealDay.empty('Friday'),
    MealDay.empty('Saturday'),
    MealDay.empty('Sunday'),
  ];
  String searchQuery = '';
  int _currentStep = 0;
  late AnimationController _animationController;

  String _selectedSpecificCategory = 'All';

  String? selectedClientId;
  String? selectedClientFullName;
  String? selectedClientUsername;
  String? selectedClientConnectionType;
  String? selectedClientProfileImageUrl;

  String selectedDay = 'Monday';

  // Plan Overview Controllers
  final _manualClientNameController = TextEditingController();
  final _templateNameController = TextEditingController();
  final _planNameController = TextEditingController();
  final _goalController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _dietTypeController = TextEditingController();
  final _specialConsiderationsController = TextEditingController();

  // Macronutrient Controllers
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();

  // Additional Details Controllers
  final _hydrationController = TextEditingController();
  final _supplementsController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  final _shoppingListController = TextEditingController();

  String selectedOption =
      'existing_client'; // Can be 'existing_client', 'manual_client', or 'template'

  // Add this variable to store trainer's exercises
  List<Map<String, dynamic>> trainerMeals = [];
  bool isLoadingMeals = true;

  // Add near other state variables
  int _currentPage = 0;
  static const int _pageSize = 20;
  List<Ingredient> _displayedIngredients = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Initialize with existing data if editing
    if ((widget.isEditing || widget.isUsingTemplate) &&
        widget.existingPlan != null) {
      final plan = widget.existingPlan!;

      // Set client data
      if (!widget.isUsingTemplate) {
        selectedClientId = plan['clientId'];
        selectedClientFullName = plan['clientFullName'];
        selectedClientUsername = plan['clientUsername'];
        selectedClientConnectionType = plan['connectionType'];
        selectedClientProfileImageUrl = plan['clientProfileImageUrl'];
      }

      selectedOption = widget.isUsingTemplate
          ? 'existing_client'
          : (plan['selectedOption'] ?? 'existing_client');

      // Initialize controllers with existing data
      _planNameController.text = plan['planName'] ?? '';
      _goalController.text = plan['goal'] ?? '';
      _durationController.text = plan['duration'] ?? '';
      _caloriesController.text = plan['caloriesTarget']?.toString() ?? '';
      _dietTypeController.text = plan['dietType'] ?? '';
      _specialConsiderationsController.text =
          plan['specialConsiderations'] ?? '';

      // Set macros
      final macros = plan['macros'] as Map<String, dynamic>?;
      if (macros != null) {
        _proteinController.text = macros['protein']?.toString() ?? '';
        _carbsController.text = macros['carbs']?.toString() ?? '';
        _fatsController.text = macros['fats']?.toString() ?? '';
      }

      // Set additional details
      _hydrationController.text = plan['hydrationGuidelines'] ?? '';
      _supplementsController.text = plan['supplements'] ?? '';
      _additionalNotesController.text = plan['additionalNotes'] ?? '';
      _shoppingListController.text = plan['shoppingList'] ?? '';

      // Initialize meal days
      if (plan['mealDays'] != null) {
        final List<dynamic> planMealDays = plan['mealDays'];
        for (var dayData in planMealDays) {
          final dayName = dayData['dayName'];
          final dayIndex = mealDays.indexWhere((d) => d.dayName == dayName);
          if (dayIndex != -1) {
            final meals = dayData['meals'] as List<dynamic>;
            for (var meal in meals) {
              mealDays[dayIndex].meals[meal['mealType']] = Meal(
                name: meal['name'],
                mealType: meal['mealType'],
                calories: meal['calories'],
                protein: meal['protein'],
                carbs: meal['carbs'],
                fats: meal['fats'],
                servingSize: meal['servingSize'],
                ingredients: meal['ingredients'],
                ingredientDetails:
                    meal['ingredientDetails']?.cast<Map<String, dynamic>>(),
                preparation: meal['preparation'],
                notes: meal['notes'],
                isManualNutrients: meal['isManualNutrients'] ?? false,
              );
            }
          }
        }
      }
    }
    _fetchTrainerMeals();
  }

  Future<void> _fetchTrainerMeals() async {
    final userProvider = context.read<UserProvider>();
    final trainerId = userProvider.userData?['userId'];

    if (trainerId == null) return;

    try {
      setState(() {
        isLoadingMeals = true;
      });

      final mealsSnapshot = await FirebaseFirestore.instance
          .collection('trainer_meals')
          .doc(trainerId)
          .collection('all_meals')
          .get();

      setState(() {
        trainerMeals = mealsSnapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'mealId': doc.id,
                })
            .toList();
        isLoadingMeals = false;
        debugPrint('Trainer meals fetched: ${trainerMeals.length}');
      });
    } catch (e) {
      debugPrint('Error fetching trainer meals: $e');
      setState(() {
        isLoadingMeals = false;
      });
    }
  }

  void _showClientSelectionModal(BuildContext context) {
    ClientSelectionSheet.show(
      context,
      (String clientId, String clientUsername, String clientFullName,
          String connectionType, String clientProfileImageUrl) {
        setState(() {
          selectedClientId = clientId;
          selectedClientUsername = clientUsername;
          selectedClientFullName = clientFullName;
          selectedClientConnectionType = connectionType;
          selectedClientProfileImageUrl = clientProfileImageUrl;

          // Get the client's connection type from the UserProvider
          final client =
              context.read<UserProvider>().partiallyTotalClients?.firstWhere(
                    (client) => client['clientId'] == clientId,
                    orElse: () => {},
                  );
          selectedClientConnectionType = client?['connectionType'];
        });
      },
    );
  }

  Widget _buildDaySelector() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        //color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDayButton('M', 'Monday'),
          _buildDayButton('T', 'Tuesday'),
          _buildDayButton('W', 'Wednesday'),
          _buildDayButton('T', 'Thursday'),
          _buildDayButton('F', 'Friday'),
          _buildDayButton('S', 'Saturday'),
          _buildDayButton('P', 'Sunday'),
        ],
      ),
    );
  }

  Widget _buildDayButton(String shortName, String fullName) {
    final isSelected = selectedDay == fullName;
    final hasContent = mealDays
        .firstWhere((day) => day.dayName == fullName)
        .meals
        .values
        .any((meal) => meal != null);

    String getLocalizedShortName(String fullName) {
      final l10n = AppLocalizations.of(context)!;
      switch (fullName) {
        case 'Monday':
          return l10n.monday_first_letter;
        case 'Tuesday':
          return l10n.tuesday_first_letter;
        case 'Wednesday':
          return l10n.wednesday_first_letter;
        case 'Thursday':
          return l10n.thursday_first_letter;
        case 'Friday':
          return l10n.friday_first_letter;
        case 'Saturday':
          return l10n.saturday_first_letter;
        case 'Sunday':
          return l10n.sunday_first_letter;
        default:
          return shortName;
      }
    }

    return InkWell(
      onTap: () {
        setState(() {
          selectedDay = fullName;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? myBlue60 : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? myBlue60 : Colors.grey[400]!,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                getLocalizedShortName(fullName),
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (hasContent)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: myBlue60,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClientSelection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      child: InkWell(
        onTap: () => _showClientSelectionModal(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                theme.brightness == Brightness.light ? Colors.white : myGrey80,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.person_outline, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.client} *',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      (selectedClientFullName ?? selectedClientUsername) ??
                          l10n.select_client,
                      style: GoogleFonts.plusJakartaSans(
                        color: (selectedClientFullName != null ||
                                selectedClientUsername != null)
                            ? theme.brightness == Brightness.light
                                ? Colors.black
                                : Colors.white
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final List<String> stepNames = [
      l10n.overview,
      l10n.schedule,
      l10n.details,
    ];

    return AppBar(
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
              color: theme.brightness == Brightness.light
                  ? Colors.black
                  : myGrey60,
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
      title: Row(
        children: [
          Text(
            widget.isEditing ? l10n.edit_plan : l10n.create_plan,
            style: GoogleFonts.plusJakartaSans(
              color: theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.restaurant_menu_outlined,
              color: theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
              size: 20),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: CustomStepIndicator(
            currentStep: _currentStep,
            totalSteps: stepNames.length,
            stepName: stepNames[_currentStep],
          ),
        ),
      ],
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
    );
  }

  Widget _buildCustomStepper() {
    return Container(
      decoration: const BoxDecoration(
        color: myGrey80,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      height: 80,
      //width: MediaQuery.of(context).size.width-32,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final buttonWidth = (availableWidth - 80) / 3;

          return Column(
            children: [
              // Top row with titles and connectors
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentStep = 0;
                      });
                      _animationController.forward(from: 0);
                    },
                    child: _buildStepTitle(
                        0, 'Overview', Icons.description_outlined, buttonWidth),
                  ),
                  _buildStepConnector(0),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentStep = 1;
                      });
                      _animationController.forward(from: 0);
                    },
                    child: _buildStepTitle(1, 'Schedule',
                        Icons.calendar_today_outlined, buttonWidth),
                  ),
                  _buildStepConnector(1),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentStep = 2;
                      });
                      _animationController.forward(from: 0);
                    },
                    child: _buildStepTitle(2, 'Details',
                        Icons.fitness_center_outlined, buttonWidth),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Bottom row with numbers
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepNumber(0, buttonWidth),
                  const SizedBox(width: 40),
                  _buildStepNumber(1, buttonWidth),
                  const SizedBox(width: 40),
                  _buildStepNumber(2, buttonWidth),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepTitle(int index, String label, IconData icon, double width) {
    final isSelected = _currentStep == index;
    final isCompleted = index < _currentStep;

    return Container(
      width: width,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: child,
              ),
            );
          },
          child: isSelected
              ? Text(
                  label,
                  key: ValueKey('text_$index'),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Icon(
                  icon,
                  key: ValueKey('icon_$index'),
                  size: 20,
                  color: isCompleted ? Colors.white : myGrey60,
                ),
        ),
      ),
    );
  }

  Widget _buildStepNumber(int index, double width) {
    final isSelected = _currentStep == index;
    final isCompleted = index < _currentStep;
    final showNumber = isSelected || isCompleted;

    return Container(
      width: width,
      child: Center(
        child: showNumber
            ? Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: isSelected || isCompleted ? Colors.white : myGrey60,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.plusJakartaSans(
                      color:
                          isSelected || isCompleted ? Colors.white : myGrey60,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            : SizedBox(height: 24), // Placeholder for spacing
      ),
    );
  }

  Widget _buildStepConnector(int beforeIndex) {
    final isActive = beforeIndex <= _currentStep - 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 24,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isActive ? Colors.white : myGrey60,
    );
  }

  Widget _buildStepButton(
      int index, String label, IconData icon, double width) {
    final isSelected = _currentStep == index;
    final isCompleted = index < _currentStep;
    final showNumber =
        isSelected || isCompleted; // Show number if selected or completed

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentStep = index;
        });
        _animationController.forward(from: 0);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: 40,
            width: width,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: isSelected
                    ? Text(
                        label,
                        key: ValueKey('text_$index'),
                        style: GoogleFonts.plusJakartaSans(
                          color: myBlue60,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Icon(
                        icon,
                        key: ValueKey('icon_$index'),
                        size: 20,
                        color: isCompleted ? myBlue60 : Colors.grey[400],
                      ),
              ),
            ),
          ),
          if (showNumber) // Only show number if selected or completed
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? myBlue60 : Colors.grey[300],
                border: Border.all(
                  color: isSelected ? myBlue60 : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      validator: required
          ? (value) => value?.isEmpty ?? true ? l10n.please_enter(label) : null
          : null,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      style: GoogleFonts.plusJakartaSans(
        letterSpacing: -0.2,
      ),
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: Colors.grey[600],
          letterSpacing: -0.2,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: Colors.grey[400],
          letterSpacing: -0.2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: myBlue60),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildMealScheduleStep() {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildDaySelector(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: _buildSelectedDayContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayContent() {
    final theme = Theme.of(context);
    final day = mealDays.firstWhere((day) => day.dayName == selectedDay);
    final l10n = AppLocalizations.of(context)!;

    String getLocalizedDayName(String fullName) {
      final l10n = AppLocalizations.of(context)!;
      switch (fullName) {
        case 'Monday':
          return l10n.monday;
        case 'Tuesday':
          return l10n.tuesday;
        case 'Wednesday':
          return l10n.wednesday;
        case 'Thursday':
          return l10n.thursday;
        case 'Friday':
          return l10n.friday;
        case 'Saturday':
          return l10n.saturday;
        case 'Sunday':
          return l10n.sunday;
        default:
          return fullName;
      }
    }

    return Container(
      color: theme.scaffoldBackgroundColor,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getLocalizedDayName(day.dayName),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...MealDay.getMealTypes(context).map((mealType) {
              final meal = day.meals[mealType];
              return Card(
                color: theme.brightness == Brightness.light
                    ? Colors.white
                    : myGrey80,
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        _getMealTypeIcon(mealType),
                        color: myBlue60,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mealType,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            if (meal != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                meal.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${meal.calories} kcal | P: ${meal.protein}g C: ${meal.carbs}g F: ${meal.fats}g',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ] else
                              Text(
                                l10n.no_meal_added,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (meal != null)
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: myRed40,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  day.meals[mealType] = null;
                                });
                              },
                            ),
                          IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: Icon(
                              meal == null ? Icons.add : Icons.edit,
                              color: myBlue60,
                              size: 20,
                            ),
                            onPressed: () => _showAddMealDialog(
                              mealDays.indexOf(day),
                              mealType,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            if (selectedDay != 'Sunday')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => _copyToNextDay(selectedDay),
                    icon: const Icon(
                      Icons.copy,
                      color: myBlue60,
                      size: 18,
                    ),
                    label: Text(
                      l10n.copy_to_next_day,
                      style: GoogleFonts.plusJakartaSans(
                        color: myBlue60,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _copyToNextDay(String currentDayName) {
    final l10n = AppLocalizations.of(context)!;
    final weekDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final currentIndex = weekDays.indexOf(currentDayName);
    if (currentIndex >= weekDays.length - 1) return;

    final nextDayName = weekDays[currentIndex + 1];
    final currentDay =
        mealDays.firstWhere((day) => day.dayName == currentDayName);
    final nextDay = mealDays.firstWhere((day) => day.dayName == nextDayName);

    setState(() {
      for (var mealType in MealDay.getMealTypes(context)) {
        if (currentDay.meals[mealType] != null) {
          final currentMeal = currentDay.meals[mealType]!;
          nextDay.meals[mealType] = Meal(
            name: currentMeal.name,
            mealType: currentMeal.mealType,
            calories: currentMeal.calories,
            protein: currentMeal.protein,
            carbs: currentMeal.carbs,
            fats: currentMeal.fats,
            notes: currentMeal.notes,
            servingSize: currentMeal.servingSize,
            ingredients: currentMeal.ingredients,
            ingredientDetails: currentMeal.ingredientDetails != null
                ? List<Map<String, dynamic>>.from(
                    currentMeal.ingredientDetails!)
                : null,
            preparation: currentMeal.preparation,
            isManualNutrients: currentMeal.isManualNutrients,
          );
        }
      }
      selectedDay = nextDayName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      CustomSnackBar.show(
        title: l10n.meal_plan,
        message: l10n.meals_copied(
            nextDayName), // Change from replaceAll to using a parameter
        type: SnackBarType.success,
      ),
    );
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.breakfast_dining;
      case 'Morning Snack':
        return Icons.apple;
      case 'Lunch':
        return Icons.lunch_dining;
      case 'Afternoon Snack':
        return Icons.cookie;
      case 'Dinner':
        return Icons.dinner_dining;
      case 'Evening Snack':
        return Icons.night_shelter;
      default:
        return Icons.restaurant;
    }
  }

  void _copyMealsToNextDay(int currentDayIndex) {
    if (currentDayIndex >= mealDays.length - 1) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      final currentDay = mealDays[currentDayIndex];
      final nextDay = mealDays[currentDayIndex + 1];

      for (var mealType in MealDay.getMealTypes(context)) {
        if (currentDay.meals[mealType] != null) {
          final currentMeal = currentDay.meals[mealType]!;
          nextDay.meals[mealType] = Meal(
            name: currentMeal.name,
            mealType: currentMeal.mealType,
            calories: currentMeal.calories,
            protein: currentMeal.protein,
            carbs: currentMeal.carbs,
            fats: currentMeal.fats,
            servingSize: currentMeal.servingSize,
            ingredients: currentMeal.ingredients,
            preparation: currentMeal.preparation,
          );
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      CustomSnackBar.show(
        title: l10n.meal_plan,
        message: l10n.meals_copied(
            mealDays[currentDayIndex + 1].dayName), // Change from replaceAll to using a parameter
        type: SnackBarType.success,
      ),
    );
  }

  void _showAddMealDialog(int dayIndex, String mealType) {
    final theme = Theme.of(context);
    String mealName = '';
    String? mealId;
    List<SelectedIngredient> selectedIngredients = [];
    List<String> preparationSteps = [];
    bool isManualNutrients = false;

    // Controllers for manual nutrient entry
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatsController = TextEditingController();
    final notesController = TextEditingController();

    // Pre-fill values if meal exists
    final existingMeal = mealDays[dayIndex].meals[mealType];
    if (existingMeal != null) {
      mealName = existingMeal.name;
      notesController.text = existingMeal.notes ?? '';
      isManualNutrients = existingMeal.isManualNutrients;

      // Pre-fill nutrient values
      if (isManualNutrients) {
        caloriesController.text = existingMeal.calories.toString();
        proteinController.text = existingMeal.protein.toString();
        carbsController.text = existingMeal.carbs.toString();
        fatsController.text = existingMeal.fats.toString();
      }

      // Reconstruct ingredients from stored details
      if (existingMeal.ingredientDetails != null) {
        selectedIngredients = existingMeal.ingredientDetails!.map((detail) {
          return SelectedIngredient(
            ingredient: Ingredient(
              name: detail['name'],
              category: 'Database', // or detail['category'] if stored
              calories: (detail['nutrients']['calories'] as num).toDouble(),
              protein: (detail['nutrients']['protein'] as num).toDouble(),
              carbs: (detail['nutrients']['carbs'] as num).toDouble(),
              fats: (detail['nutrients']['fats'] as num).toDouble(),
              servingSize: detail['quantity'].toString(),
              servingUnit: detail['servingUnit'],
              specificCategories: detail['specificCategories'],
            ),
            quantity: (detail['quantity'] as num).toDouble(),
          );
        }).toList();
      }

      // Load preparation steps
      if (existingMeal.preparation != null) {
        preparationSteps = existingMeal.preparation!
            .split('\n')
            .map((step) => step.replaceFirst(RegExp(r'Step \d+: '), ''))
            .toList();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final l10n = AppLocalizations.of(context)!;
          // Rename setState to setSheetState to avoid confusion
          // Calculate nutrients from ingredients
          int totalCalories = 0;
          int totalProtein = 0;
          int totalCarbs = 0;
          int totalFats = 0;

          if (!isManualNutrients) {
            for (var selected in selectedIngredients) {
              final nutrients = selected.nutrients;
              totalCalories += nutrients['calories']!.round();
              totalProtein += nutrients['protein']!.round();
              totalCarbs += nutrients['carbs']!.round();
              totalFats += nutrients['fats']!.round();
            }
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                top: BorderSide(
                  color: theme.brightness == Brightness.light
                      ? Colors.transparent
                      : myGrey80,
                ),
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(_getMealTypeIcon(mealType), color: myBlue60),
                      const SizedBox(width: 12),
                      Text(
                        l10n.add_meal_type(mealType),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomSelectExerciseMealTextField(
                          isExercise: false,
                          label: l10n.meal_name,
                          hintText: l10n.e_g_breakfast_lunch_etc,
                          controller: TextEditingController(text: mealName),
                          options: trainerMeals,
                          prefixIcon: Icons.restaurant,
                          isRequired: true,
                          onChanged: (name, id) {
                            mealName = name;
                            mealId = id;
                            //debugPrint('mealId: $mealId');
                            if (id != null) {
                              // Selected from list, update all fields
                              final selectedMeal = trainerMeals.firstWhere(
                                (e) => e['mealId'] == id,
                              );
                              debugPrint('selectedMeal: $selectedMeal');
                              setSheetState(() {
                                // Update basic info
                                mealName = selectedMeal['name'];
                                caloriesController.text =
                                    selectedMeal['calories'].toString();
                                proteinController.text =
                                    selectedMeal['protein'].toString();
                                carbsController.text =
                                    selectedMeal['carbs'].toString();
                                fatsController.text =
                                    selectedMeal['fats'].toString();
                                notesController.text =
                                    selectedMeal['notes'] ?? '';

                                // Update ingredients
                                selectedIngredients.clear();
                                if (selectedMeal['ingredientDetails'] != null) {
                                  selectedIngredients.addAll((selectedMeal[
                                          'ingredientDetails'] as List)
                                      .map((detail) => SelectedIngredient(
                                            ingredient: Ingredient(
                                              name: detail['name'],
                                              category: 'Database',
                                              calories: (detail['nutrients']
                                                      ['calories'] as num)
                                                  .toDouble(),
                                              protein: (detail['nutrients']
                                                      ['protein'] as num)
                                                  .toDouble(),
                                              carbs: (detail['nutrients']
                                                      ['carbs'] as num)
                                                  .toDouble(),
                                              fats: (detail['nutrients']['fats']
                                                      as num)
                                                  .toDouble(),
                                              servingSize:
                                                  detail['quantity'].toString(),
                                              servingUnit:
                                                  detail['servingUnit'],
                                              specificCategories:
                                                  detail['specificCategories'],
                                            ),
                                            quantity:
                                                (detail['quantity'] as num)
                                                    .toDouble(),
                                          )));
                                }

                                // Set manual nutrients mode
                                isManualNutrients =
                                    selectedMeal['isManualNutrients'] ?? false;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 1,
                          color: theme.brightness == Brightness.light
                              ? Colors.white
                              : myGrey80,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isManualNutrients
                                          ? l10n.total_nutrients_manual
                                          : l10n.total_nutrients_calculated,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color:
                                            theme.brightness == Brightness.light
                                                ? myBlue60
                                                : myGrey10,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isManualNutrients
                                            ? Icons.edit
                                            : Icons.edit_outlined,
                                        size: 20,
                                        color:
                                            theme.brightness == Brightness.light
                                                ? myBlue60
                                                : myGrey10,
                                      ),
                                      onPressed: () {
                                        setSheetState(() {
                                          isManualNutrients =
                                              !isManualNutrients;
                                          if (isManualNutrients) {
                                            caloriesController.text =
                                                totalCalories.toString();
                                            proteinController.text =
                                                totalProtein.toString();
                                            carbsController.text =
                                                totalCarbs.toString();
                                            fatsController.text =
                                                totalFats.toString();
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (isManualNutrients)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: caloriesController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: l10n.calories,
                                            labelStyle:
                                                GoogleFonts.plusJakartaSans(
                                                    fontSize: 12),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey[400]!),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide:
                                                  BorderSide(color: myBlue60),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey[400]!),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: proteinController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Protein (g)',
                                            labelStyle:
                                                GoogleFonts.plusJakartaSans(
                                                    fontSize: 12),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey[400]!),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide:
                                                  BorderSide(color: myBlue60),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey[400]!),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: carbsController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Carbs (g)',
                                            labelStyle:
                                                GoogleFonts.plusJakartaSans(
                                                    fontSize: 12),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey[400]!),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide:
                                                  BorderSide(color: myBlue60),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey[400]!),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: fatsController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Fats (g)',
                                            labelStyle:
                                                GoogleFonts.plusJakartaSans(
                                                    fontSize: 12),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey[400]!),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide:
                                                  BorderSide(color: myBlue60),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey[400]!),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildNutrientInfo(
                                          'Calories', totalCalories),
                                      _buildNutrientInfo(
                                          'Protein', totalProtein, 'g'),
                                      _buildNutrientInfo(
                                          'Carbs', totalCarbs, 'g'),
                                      _buildNutrientInfo(
                                          'Fats', totalFats, 'g'),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () {
                                setSheetState(() {
                                  _selectedSpecificCategory = 'All';
                                });
                                _showIngredientSelectionDialog(
                                  context,
                                  selectedIngredients,
                                  (updatedIngredients) {
                                    setSheetState(() {
                                      selectedIngredients = updatedIngredients;
                                    });
                                  },
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: Text(l10n.add_ingredients),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: myBlue60,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (selectedIngredients.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.light
                                  ? Colors.grey[50]
                                  : myGrey80,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: theme.brightness == Brightness.light
                                      ? Colors.grey[200]!
                                      : myGrey80),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.added_ingredients,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    color: theme.brightness == Brightness.light
                                        ? myBlue60
                                        : myGrey10,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...selectedIngredients.map((ingredient) =>
                                    ListTile(
                                      title: Text(ingredient.ingredient.name),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${ingredient.quantity}${ingredient.ingredient.servingUnit}'),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: theme.brightness ==
                                                          Brightness.light
                                                      ? Colors.grey[200]
                                                      : myGrey80,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Cal: ${ingredient.nutrients['calories']?.round() ?? 0}',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    color: theme.brightness ==
                                                            Brightness.light
                                                        ? Colors.grey[600]
                                                        : myGrey50,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: theme.brightness ==
                                                          Brightness.light
                                                      ? Colors.grey[200]
                                                      : myGrey80,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'P: ${ingredient.nutrients['protein']?.round() ?? 0}g',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    color: theme.brightness ==
                                                            Brightness.light
                                                        ? Colors.grey[600]
                                                        : myGrey50,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: theme.brightness ==
                                                          Brightness.light
                                                      ? Colors.grey[200]
                                                      : myGrey80,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'C: ${ingredient.nutrients['carbs']?.round() ?? 0}g',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    color: theme.brightness ==
                                                            Brightness.light
                                                        ? Colors.grey[600]
                                                        : myGrey50,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: theme.brightness ==
                                                          Brightness.light
                                                      ? Colors.grey[200]
                                                      : myGrey80,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'F: ${ingredient.nutrients['fats']?.round() ?? 0}g',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    color: theme.brightness ==
                                                            Brightness.light
                                                        ? Colors.grey[600]
                                                        : myGrey50,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        iconSize: 20,
                                        color: myRed50,
                                        onPressed: () {
                                          setSheetState(() {
                                            selectedIngredients
                                                .remove(ingredient);
                                          });
                                        },
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        CustomFocusTextField(
                          label: l10n.meal_notes,
                          hintText: l10n.meal_notes_hint,
                          controller: notesController,
                          prefixIcon: Icons.edit,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom actions
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[400]!),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l10n.cancel,
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.grey[600]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (mealName.isNotEmpty) {
                              // Update both the sheet state and the parent widget state
                              setSheetState(() {
                                mealDays[dayIndex].meals[mealType] = Meal(
                                  name: mealName,
                                  mealType: mealType,
                                  calories: isManualNutrients
                                      ? int.tryParse(caloriesController.text) ??
                                          0
                                      : totalCalories,
                                  protein: isManualNutrients
                                      ? int.tryParse(proteinController.text) ??
                                          0
                                      : totalProtein,
                                  carbs: isManualNutrients
                                      ? int.tryParse(carbsController.text) ?? 0
                                      : totalCarbs,
                                  fats: isManualNutrients
                                      ? int.tryParse(fatsController.text) ?? 0
                                      : totalFats,
                                  ingredients: selectedIngredients
                                      .map((i) =>
                                          '${i.ingredient.name}: ${i.quantity}${i.ingredient.servingUnit}')
                                      .join('\n'),
                                  ingredientDetails: selectedIngredients
                                      .map((i) => {
                                            'name': i.ingredient.name,
                                            'quantity': i.quantity,
                                            'servingUnit':
                                                i.ingredient.servingUnit,
                                            'nutrients': i.nutrients,
                                          })
                                      .toList(),
                                  preparation: preparationSteps
                                      .asMap()
                                      .entries
                                      .where((entry) => entry.value.isNotEmpty)
                                      .map((entry) =>
                                          'Step ${entry.key + 1}: ${entry.value}')
                                      .join('\n'),
                                  notes: notesController.text,
                                  isManualNutrients: isManualNutrients,
                                );
                              });

                              // Update parent widget state
                              setState(() {
                                mealDays[dayIndex].meals[mealType] = Meal(
                                  mealId: mealId,
                                  name: mealName,
                                  mealType: mealType,
                                  calories: isManualNutrients
                                      ? int.tryParse(caloriesController.text) ??
                                          0
                                      : totalCalories,
                                  protein: isManualNutrients
                                      ? int.tryParse(proteinController.text) ??
                                          0
                                      : totalProtein,
                                  carbs: isManualNutrients
                                      ? int.tryParse(carbsController.text) ?? 0
                                      : totalCarbs,
                                  fats: isManualNutrients
                                      ? int.tryParse(fatsController.text) ?? 0
                                      : totalFats,
                                  ingredients: selectedIngredients
                                      .map((i) =>
                                          '${i.ingredient.name}: ${i.quantity}${i.ingredient.servingUnit}')
                                      .join('\n'),
                                  ingredientDetails: selectedIngredients
                                      .map((i) => {
                                            'name': i.ingredient.name,
                                            'quantity': i.quantity,
                                            'servingUnit':
                                                i.ingredient.servingUnit,
                                            'nutrients': i.nutrients,
                                          })
                                      .toList(),
                                  preparation: preparationSteps
                                      .asMap()
                                      .entries
                                      .where((entry) => entry.value.isNotEmpty)
                                      .map((entry) =>
                                          'Step ${entry.key + 1}: ${entry.value}')
                                      .join('\n'),
                                  notes: notesController.text,
                                  isManualNutrients: isManualNutrients,
                                );
                              });
                              Navigator.pop(context);
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
                            existingMeal != null ? l10n.update : l10n.add,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutrientInfo(String label, int value, [String unit = '']) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value.toString() + unit,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: theme.brightness == Brightness.light ? myBlue60 : myGrey10,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: theme.brightness == Brightness.light
                ? Colors.grey[600]
                : myGrey50,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomFocusTextField(
                controller: _hydrationController,
                label: l10n.hydration_guidelines,
                hintText: l10n.water_intake_recommendations,
                prefixIcon: Icons.local_drink_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CustomFocusTextField(
                controller: _supplementsController,
                label: l10n.supplement_recommendations,
                hintText: l10n.supplements_hint,
                prefixIcon: Icons.local_drink_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CustomFocusTextField(
                controller: _additionalNotesController,
                label: l10n.additional_notes,
                hintText: l10n.other_important_info,
                prefixIcon: Icons.edit_note_outlined,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _currentStep == 0
          ? Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep++;
                    });
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
            )
          : Row(
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
                          fontWeight: FontWeight.w400,
                          color: theme.brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                if (_currentStep > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < 2) {
                          setState(() {
                            _currentStep++;
                          });
                        } else {
                          _submitForm(context, l10n);
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
                        _currentStep == 2
                            ? (widget.isEditing
                                ? l10n.save_changes
                                : l10n.create_plan)
                            : l10n.next,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: BlocConsumer<MealPlanBloc, MealPlanState>(
        listener: (context, state) {
          if (state is MealPlanSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar.show(
                title: l10n.meal_plan,
                message: l10n.meal_plan_created,
                type: SnackBarType.success,
              ),
            );
            Navigator.pop(context);
          } else if (state is MealPlanError) {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar.show(
                title: l10n.meal_plan,
                message: state.message,
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
                  // Remove or comment out the old stepper
                  // _buildCustomStepper(),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: [
                          _buildPlanOverviewStep(l10n),
                          _buildMealScheduleStep(),
                          _buildDetailsStep(),
                        ][_currentStep],
                      ),
                    ),
                  ),
                  _buildNavigationButtons(l10n),
                ],
              ),
              if (state is MealPlanLoading) const CustomLoadingView(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlanOverviewStep(AppLocalizations l10n) {
    final theme = Theme.of(context);

    // Add these lists near the other controller definitions
    final List<String> planNameSuggestions = [
      l10n.weight_loss_meal_plan,
      l10n.muscle_building_meal_plan,
      l10n.maintenance_meal_plan,
      l10n.keto_diet_plan,
      l10n.vegetarian_meal_plan,
      l10n.vegan_meal_plan,
      l10n.mediterranean_diet_plan,
      l10n.low_carb_meal_plan,
      l10n.bulking_meal_plan,
      l10n.cutting_meal_plan
    ];

    final List<String> goalSuggestions = [
      l10n.weight_loss,
      l10n.muscle_gain,
      l10n.maintenance,
      l10n.improved_energy,
      l10n.better_health,
      l10n.sports_performance,
      l10n.body_recomposition,
      l10n.balanced_nutrition,
      l10n.specific_diet_adherence,
      l10n.healthy_lifestyle
    ];

    final List<String> durationSuggestions = [
      l10n.one_week,
      l10n.two_weeks,
      l10n.four_weeks,
      l10n.six_weeks,
      l10n.eight_weeks,
      l10n.twelve_weeks,
      l10n.three_months,
      l10n.six_months,
      l10n.ongoing
    ];

    final List<String> dietTypeSuggestions = [
      l10n.balanced_diet,
      l10n.mediterranean_diet,
      l10n.ketogenic_diet,
      l10n.low_carb_diet,
      l10n.vegetarian,
      l10n.vegan,
      l10n.paleo_diet,
      l10n.gluten_free,
      l10n.dairy_free,
      l10n.high_protein_diet,
      l10n.plant_based,
      l10n.intermittent_fasting
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light
                        ? Colors.white
                        : myGrey80,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildClientTypeButton('existing_client',
                              'Existing Client', Icons.person_outline, l10n),
                          const SizedBox(width: 8),
                          _buildClientTypeButton('manual_client',
                              'Manual Client', Icons.person_add_outlined, l10n),
                          if (!widget.isUsingTemplate) ...[
                            const SizedBox(width: 8),
                            _buildClientTypeButton('template', 'Template',
                                Icons.save_outlined, l10n),
                          ]
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Client selection section
                      if (selectedOption == 'existing_client')
                        _buildClientSelection(l10n)
                      else if (selectedOption == 'manual_client')
                        CustomFocusTextField(
                          controller: _manualClientNameController,
                          label: l10n.client_name,
                          hintText: l10n.enter_client_name,
                          prefixIcon: Icons.person_outline,
                          isRequired: true,
                          onChanged: (value) {},
                        )
                      else if (selectedOption == 'template')
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.light
                                    ? myBlue60.withOpacity(0.1)
                                    : myGrey10.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: theme.brightness == Brightness.light
                                        ? myBlue60.withOpacity(0.2)
                                        : myGrey10.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 20,
                                      color:
                                          theme.brightness == Brightness.light
                                              ? myBlue60
                                              : myGrey10),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Create templates to reuse later. Access your templates in Resources to quickly create new meal plans with modifications.',
                                      style: GoogleFonts.plusJakartaSans(
                                        color:
                                            theme.brightness == Brightness.light
                                                ? myBlue60
                                                : myGrey10,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CustomFocusTextField(
                              controller: _templateNameController,
                              label: l10n.template_name,
                              hintText: l10n.enter_template_name,
                              prefixIcon: Icons.save_outlined,
                              isRequired: true,
                              onChanged: (value) {},
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              const SizedBox(height: 16),

              // Plan details section

              CustomSelectTextField(
                controller: _planNameController,
                label: l10n.plan_name,
                hintText: l10n.enter_plan_name,
                prefixIcon: Icons.edit_outlined,
                isRequired: false,
                options: planNameSuggestions,
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),

              CustomSelectTextField(
                controller: _goalController,
                label: l10n.goal,
                hintText: l10n.e_g_weight_loss_muscle_gain_maintenance,
                prefixIcon: Icons.track_changes_outlined,
                options: goalSuggestions,
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),

              CustomSelectTextField(
                controller: _durationController,
                label: l10n.duration,
                hintText: l10n.e_g_4_weeks,
                prefixIcon: Icons.calendar_today_outlined,
                options: durationSuggestions,
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),

              CustomFocusTextField(
                controller: _caloriesController,
                label: l10n.daily_caloric_target,
                hintText: l10n.e_g_2000_kcal,
                prefixIcon: Icons.local_fire_department_outlined,
                keyboardType: TextInputType.number,
                onChanged: (value) {},
              ),

              const SizedBox(height: 16),

              // Macronutrients section
              Row(
                children: [
                  Expanded(
                    child: CustomFocusTextField(
                      controller: _proteinController,
                      label: 'Protein %',
                      hintText: '30',
                      prefixIcon: Icons.percent_outlined,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomFocusTextField(
                      controller: _carbsController,
                      label: 'Carbs %',
                      hintText: '40',
                      prefixIcon: Icons.percent_outlined,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomFocusTextField(
                      controller: _fatsController,
                      label: 'Fats %',
                      hintText: '30',
                      prefixIcon: Icons.percent_outlined,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomSelectTextField(
                controller: _dietTypeController,
                label: l10n.diet_type,
                hintText: l10n.e_g_mediterranean_keto_vegan,
                prefixIcon: Icons.restaurant_menu_outlined,
                options: dietTypeSuggestions,
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),

              CustomFocusTextField(
                controller: _specialConsiderationsController,
                label: l10n.special_considerations,
                hintText: l10n.e_g_allergies_intolerances_preferences,
                prefixIcon: Icons.warning_amber_outlined,
                maxLines: 3,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm(BuildContext context, AppLocalizations l10n) async {


    
    // First check if any day has at least one meal
    bool hasAtLeastOneMeal = false;
    List<String> emptyDays = [];

    for (var day in mealDays) {
      bool dayHasMeal = false;
      for (var mealType in MealDay.getMealTypes(context)) {
        if (day.meals[mealType] != null) {
          dayHasMeal = true;
          hasAtLeastOneMeal = true;
          break;
        }
      }
      if (!dayHasMeal) {
        emptyDays.add(day.dayName);
      }
    }

    if (!hasAtLeastOneMeal) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.meal_plan,
          message: l10n.add_at_least_one_meal,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    if (selectedOption == 'existing_client' && selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.meal_plan,
          message: l10n.select_client_error,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    if (selectedOption == 'manual_client' &&
        _manualClientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.meal_plan,
          message: l10n.enter_client_name_error,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    if (selectedOption == 'template' && _templateNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.meal_plan,
          message: l10n.enter_template_name_error,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final userData = context.read<UserProvider>().userData;

      if (userData == null ||
          userData['userId'] == null ||
          userData[fbRandomName] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.meal_plan,
            message: l10n.user_data_incomplete,
            type: SnackBarType.error,
          ),
        );
        return;
      }


      final isClientSameAsTrainer = selectedClientId == userData['trainerClientId'];
    var shouldMarkMealPlanAsCurrent = false;


    if (isClientSameAsTrainer) {
      final currentMealPlanSnapshot = await FirebaseFirestore.instance
                    .collection('meal_plans')
                    .doc('clients')
                    .collection(selectedClientId!)
                    .where('status', isEqualTo: 'current')
                    .get();

      if (currentMealPlanSnapshot.docs.isEmpty) {
        debugPrint('Marking meal plan as current');
        shouldMarkMealPlanAsCurrent = true;
      }
    }

      final typedRandomId =
          'TYPED_${DateTime.now().millisecondsSinceEpoch}_${_manualClientNameController.text.replaceAll(' ', '_')}';
      final templateRandomId =
          'TEMPLATE_${DateTime.now().millisecondsSinceEpoch}_${_templateNameController.text.replaceAll(' ', '_')}';

      DateTime myNow = DateTime.now();
      Timestamp myTimestamp = Timestamp.fromDate(myNow);

      final mealPlanData = {
        'trainerId': userData['userId'].toString(),
        'trainerName': userData[fbRandomName].toString(),
        'trainerFullName':
            (userData[fbFullName] ?? userData[fbRandomName]).toString(),
        'trainerProfileImageUrl': userData[fbProfileImageURL].toString(),
        'professionalRole': 'trainer',
        'clientId': selectedOption == 'existing_client'
            ? selectedClientId.toString()
            : selectedOption == 'manual_client'
                ? typedRandomId
                : templateRandomId,
        'clientFullName': selectedOption == 'existing_client'
            ? ((selectedClientFullName ?? selectedClientUsername).toString())
            : selectedOption == 'manual_client'
                ? _manualClientNameController.text
                : templateRandomId,
        'clientUsername': selectedOption == 'existing_client'
            ? selectedClientUsername.toString()
            : selectedOption == 'manual_client'
                ? _manualClientNameController.text
                : templateRandomId,
        'clientProfileImageUrl': (selectedOption == 'existing_client' &&
                selectedClientConnectionType == fbAppConnectionType)
            ? selectedClientProfileImageUrl.toString()
            : '',
        'connectionType': selectedOption == 'existing_client'
            ? selectedClientConnectionType.toString()
            : selectedOption == 'manual_client'
                ? fbTypedConnectionType
                : fbTemplateConnectionType,
        'isTemplate': selectedOption == 'template' ? true : false,
        'templateName':
            selectedOption == 'template' ? _templateNameController.text : null,
        'selectedOption': selectedOption,
        'planName': _planNameController.text,
        'goal': _goalController.text,
        'duration': _durationController.text,
        'caloriesTarget': _caloriesController.text,
        'macros': {
          'protein': _proteinController.text,
          'carbs': _carbsController.text,
          'fats': _fatsController.text,
        },
        'dietType': _dietTypeController.text,
        'specialConsiderations': _specialConsiderationsController.text,
        'mealDays': mealDays
            .map((day) => {
                  'dayName': day.dayName,
                  'meals': MealDay.getMealTypes(context)
                      .map((mealType) {
                        final meal = day.meals[mealType];
                        if (meal == null) return null;

                        return {
                          'mealId': meal.mealId,
                          'name': meal.name,
                          'mealType': meal.mealType,
                          'calories': meal.calories,
                          'protein': meal.protein,
                          'carbs': meal.carbs,
                          'fats': meal.fats,
                          'servingSize': meal.servingSize ?? '',
                          'ingredients': meal.ingredients ?? '',
                          'ingredientDetails': meal.ingredientDetails ?? [],
                          'preparation': meal.preparation ?? '',
                          'notes': meal.notes ?? '',
                          'isManualNutrients': meal.isManualNutrients,
                        };
                      })
                      .whereType<Map<String, dynamic>>()
                      .toList(),
                })
            .toList(),
        'hydrationGuidelines': _hydrationController.text,
        'supplements': _supplementsController.text,
        'shoppingList': _shoppingListController.text,
        'additionalNotes': _additionalNotesController.text,
        'status': getMealStatus(selectedOption, shouldMarkMealPlanAsCurrent),
        'createdAt': myTimestamp,
        'updatedAt': myTimestamp,
      };

      if (widget.isEditing) {
        // Add the existing plan ID when updating
        mealPlanData['planId'] = widget.existingPlan!['planId'];
        context.read<MealPlanBloc>().add(
              UpdateMealPlan(data: mealPlanData),
            );
      } else {
        context.read<MealPlanBloc>().add(
              CreateMealPlan(data: mealPlanData),
            );
      }
    }
  }

  getMealStatus(String whichOption, bool shouldMarkMealPlanAsCurrent) {
    final userData = context.read<UserProvider>().userData;
    if (whichOption == 'existing_client') {
      if (selectedClientConnectionType == fbAppConnectionType) {
        if (selectedClientId == userData?['trainerClientId']) {
          return shouldMarkMealPlanAsCurrent ? 'current' : fbClientConfirmedStatus;
        } else {
          return fbCreatedStatusForAppUser;
        }
      } else {
        return fbCreatedStatusForNotAppUser;
      }
    } else if (whichOption == 'manual_client') {
      return fbCreatedStatusForNotAppUser;
    } else if (whichOption == 'template') {
      return fbCreatedStatusForTemplate;
    }
  }

  Widget _buildClientTypeButton(
      String type, String label, IconData icon, AppLocalizations l10n) {
    String getLocalizedLabel() {
      switch (type) {
        case 'existing_client':
          return l10n.existing_client;
        case 'manual_client':
          return l10n.manual_client;
        case 'template':
          return l10n.template;
        default:
          return label;
      }
    }

    bool isSelected = selectedOption == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOption = type;
          // Reset client selection when switching types
          selectedClientId = null;
          selectedClientFullName = null;
          selectedClientUsername = null;
          selectedClientConnectionType = null;
          selectedClientProfileImageUrl = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? myBlue20 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? myBlue60 : Colors.transparent,
                border: Border.all(
                  color: isSelected ? myBlue60 : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(width: isSelected ? 8 : 0),
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: isSelected ? null : 0,
                  child: Text(
                    getLocalizedLabel(),
                    style: GoogleFonts.plusJakartaSans(
                      color: myBlue60,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIngredientSelectionDialog(
    BuildContext context,
    List<SelectedIngredient> selectedIngredients,
    Function(List<SelectedIngredient>) onSave,
  ) {
    final theme = Theme.of(context);
    String searchQuery = '';
    bool isManualMode = false;
    // Create a persistent TextEditingController for search
    final searchController = TextEditingController();
    final List<SelectedIngredient> tempSelected =
        List.from(selectedIngredients);

    // Controllers for manual ingredient entry
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatsController = TextEditingController();
    final servingSizeController = TextEditingController();
    final userData = context.read<UserProvider>().userData;
    final weightUnit = userData?['weightUnit'] ?? 'kg';
    var manualSelectedServingUnit = '';
    final l10n = AppLocalizations.of(context)!;

    final specializationCategories = {
      'All': 'All',
      'Meat & Fish': 'Meat & Fish',
      'Plant-Based Protein': 'Plant-Based Protein',
      'Carbs': 'Carbs',
      'Healthy Fats': 'Healthy Fats',
      'Nuts & Seeds': 'Nuts & Seeds',
      'Fruits': 'Fruits',
      'Vegetables & Greens': 'Vegetables & Greens',
      'Dairy & Alternatives': 'Dairy & Alternatives',
      'Spices & Herbs': 'Spices & Herbs',
      'Condiments': 'Condiments',
    };

    // Initialize first 20 ingredients for 'All' category
    _selectedSpecificCategory = 'All';
    _currentPage = 0;
    _displayedIngredients.clear();
    final initialIngredients = IngredientsData.getIngredientsBySpecificCategory(context, 'All');
    _displayedIngredients = initialIngredients.take(_pageSize).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(
          color: theme.brightness == Brightness.light
              ? Colors.transparent
              : myGrey80,
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredIngredients = searchQuery.isEmpty
              ? _displayedIngredients // Show paginated results when not searching
              : IngredientsData.getIngredientsBySpecificCategory(
                      context, _selectedSpecificCategory)
                  .where((ingredient) => ingredient.name
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                  .toList();

          return Container(
            height: (MediaQuery.of(context).size.height * 0.85) - 56,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top section with mode selection
                CustomTopSelector(
                  options: [
                    TopSelectorOption(title: l10n.database),
                    TopSelectorOption(title: l10n.manual),
                  ],
                  selectedIndex: isManualMode ? 1 : 0,
                  onOptionSelected: (index) =>
                      setState(() => isManualMode = index == 1),
                ),

                const SizedBox(height: 12),

                // Search bar (only shown in database mode)
                if (!isManualMode) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? Colors.white
                          : myGrey80,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context).copyWith(
                                dragDevices: {
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.mouse,
                                },
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  ...specializationCategories.keys.map((category) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedSpecificCategory = category;
                                          _currentPage = 0;
                                          final categoryIngredients =
                                              IngredientsData
                                                  .getIngredientsBySpecificCategory(
                                                      context, category);
                                          _displayedIngredients =
                                              categoryIngredients
                                                  .take(_pageSize)
                                                  .toList();
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _selectedSpecificCategory ==
                                                    category
                                                ? myGrey30
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Container(
                                            margin: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: _selectedSpecificCategory ==
                                                      category
                                                  ? myGrey90
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: _selectedSpecificCategory ==
                                                        category
                                                    ? Colors.transparent
                                                    : theme.brightness ==
                                                            Brightness.light
                                                        ? myGrey60
                                                        : myGrey40,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            child: Text(
                                              category,
                                              style: GoogleFonts.plusJakartaSans(
                                                color: _selectedSpecificCategory ==
                                                        category
                                                    ? Colors.white
                                                    : theme.brightness ==
                                                            Brightness.light
                                                        ? myGrey90
                                                        : myGrey10,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ], // Add comma here
                              ), // Close Row
                            ), // Close ScrollConfiguration
                          ), // Close SingleChildScrollView
                        ), // Close Expanded
                      ], // Close Row children
                    ), // Close Row
                  ), // Close Container
                  CustomFocusTextField(
                    label: '',
                    hintText: l10n.search_ingredients,
                    controller:
                        searchController, // Use the persistent controller
                    prefixIcon: Icons.search,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ],

                const SizedBox(height: 12),

                // After the search bar and before bottom buttons
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isManualMode) ...[
                          const SizedBox(height: 12),
                          CustomFocusTextField(
                            label: l10n.ingredient_name,
                            hintText: l10n.ingredient_name_hint,
                            controller: nameController,
                            prefixIcon: Icons.restaurant_menu,
                            isRequired: true,
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.serving,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: theme.brightness == Brightness.light
                                      ? myGrey90
                                      : Colors.white,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: CustomFocusTextField(
                                      label: '',
                                      hintText: weightUnit == 'kg'
                                          ? l10n.serving_hint_metric
                                          : l10n.serving_hint_imperial,
                                      controller: servingSizeController,
                                      prefixIcon: Icons.monitor_weight_outlined,
                                      isRequired: false,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          title: Text(
                                            l10n.select_unit,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          content: IntrinsicHeight(
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ...[
                                                    weightUnit == 'kg'
                                                        ? 'g'
                                                        : 'oz',
                                                    'ml',
                                                    'pc',
                                                    'cup',
                                                    'tbsp',
                                                  ]
                                                      .map((unit) => ListTile(
                                                            contentPadding:
                                                                EdgeInsets.zero,
                                                            title: Text(
                                                              unit,
                                                              style: GoogleFonts
                                                                  .plusJakartaSans(),
                                                            ),
                                                            onTap: () {
                                                              setState(() {
                                                                manualSelectedServingUnit =
                                                                    unit;
                                                              });
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ))
                                                      .toList(),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      //width: 60,
                                      height: 59,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: myGrey20,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          Text(
                                            manualSelectedServingUnit,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: theme.brightness ==
                                                      Brightness.light
                                                  ? myGrey90
                                                  : Colors.white,
                                            ),
                                          ),
                                          const Icon(Icons.arrow_drop_down),
                                          const SizedBox(width: 4),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          CustomFocusTextField(
                            label: 'Calories (kcal)',
                            hintText: 'e.g., 100kcal',
                            controller: caloriesController,
                            prefixIcon: Icons.local_fire_department_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: CustomFocusTextField(
                                  label: 'Protein (g)',
                                  hintText: 'e.g., 100g',
                                  controller: proteinController,
                                  isRequired: false,
                                ),
                              ),
                              Expanded(
                                child: CustomFocusTextField(
                                  label: 'Carbs (g)',
                                  hintText: 'e.g., 100g',
                                  controller: carbsController,
                                  isRequired: false,
                                ),
                              ),
                              Expanded(
                                child: CustomFocusTextField(
                                  label: 'Fats (g)',
                                  hintText: 'e.g., 100g',
                                  controller: fatsController,
                                  isRequired: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (nameController.text.isNotEmpty &&
                                  servingSizeController.text.isNotEmpty &&
                                  manualSelectedServingUnit.isNotEmpty) {
                                final manualIngredient = Ingredient(
                                  name: nameController.text,
                                  category: 'Manual',
                                  calories: double.tryParse(
                                          caloriesController.text) ??
                                      0,
                                  protein:
                                      double.tryParse(proteinController.text) ??
                                          0,
                                  carbs:
                                      double.tryParse(carbsController.text) ??
                                          0,
                                  fats:
                                      double.tryParse(fatsController.text) ?? 0,
                                  servingSize: servingSizeController.text,
                                  servingUnit: manualSelectedServingUnit,
                                  specificCategories: ['All'],
                                );
                                setState(() {
                                  tempSelected.add(SelectedIngredient(
                                    ingredient: manualIngredient,
                                    quantity: double.parse(
                                        servingSizeController.text),
                                  ));
                                });
                                // Clear fields after adding
                                nameController.clear();
                                servingSizeController.clear();
                                caloriesController.clear();
                                proteinController.clear();
                                carbsController.clear();
                                fatsController.clear();
                                manualSelectedServingUnit = '';
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(
                                        color: myGrey20,
                                        width: 1,
                                      ),
                                    ),
                                    title: Text(
                                      'Error',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    content: Text(
                                      'Please fill ingredient name, serving size and serving unit',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: myBlue60,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              l10n.add_ingredient,
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white),
                            ),
                          ),
                        ] else ...[
                          // Food database list with quantity controls
                          ...filteredIngredients.map((ingredient) {
                            final isSelected = tempSelected.any(
                                (s) => s.ingredient.name == ingredient.name);
                            final selectedIngredient = tempSelected.firstWhere(
                              (s) => s.ingredient.name == ingredient.name,
                              orElse: () => SelectedIngredient(
                                ingredient: ingredient,
                                quantity: double.parse(ingredient.servingSize),
                              ),
                            );

                            return ListTile(
                              title: Text(ingredient.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${ingredient.servingSize}${ingredient.servingUnit}'),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.brightness ==
                                                  Brightness.light
                                              ? Colors.grey[300]
                                              : myGrey80,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Cal: ${ingredient.calories.round()}',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: theme.brightness ==
                                                    Brightness.light
                                                ? Colors.grey[600]
                                                : myGrey50,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.brightness ==
                                                  Brightness.light
                                              ? Colors.grey[300]
                                              : myGrey80,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'P: ${ingredient.protein.round()}g',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: theme.brightness ==
                                                    Brightness.light
                                                ? Colors.grey[600]
                                                : myGrey50,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.brightness ==
                                                  Brightness.light
                                              ? Colors.grey[300]
                                              : myGrey80,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'C: ${ingredient.carbs.round()}g',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: theme.brightness ==
                                                    Brightness.light
                                                ? Colors.grey[600]
                                                : myGrey50,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.brightness ==
                                                  Brightness.light
                                              ? Colors.grey[300]
                                              : myGrey80,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'F: ${ingredient.fats.round()}g',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: theme.brightness ==
                                                    Brightness.light
                                                ? Colors.grey[600]
                                                : myGrey50,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: isSelected
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline),
                                          iconSize: 20,
                                          color: myRed50,
                                          onPressed: () {
                                            setState(() {
                                              if (selectedIngredient.quantity <=
                                                  double.parse(
                                                      ingredient.servingSize)) {
                                                tempSelected
                                                    .remove(selectedIngredient);
                                              } else {
                                                final index =
                                                    tempSelected.indexOf(
                                                        selectedIngredient);
                                                tempSelected[index] =
                                                    SelectedIngredient(
                                                  ingredient: ingredient,
                                                  quantity: selectedIngredient
                                                          .quantity -
                                                      double.parse(ingredient
                                                          .servingSize),
                                                );
                                              }
                                            });
                                          },
                                        ),
                                        Text(
                                          '${(selectedIngredient.quantity).toStringAsFixed(0)}${ingredient.servingUnit}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          iconSize: 20,
                                          color: myBlue60,
                                          onPressed: () {
                                            setState(() {
                                              final index = tempSelected
                                                  .indexOf(selectedIngredient);
                                              if (index >= 0) {
                                                tempSelected[index] =
                                                    SelectedIngredient(
                                                  ingredient: ingredient,
                                                  quantity: selectedIngredient
                                                          .quantity +
                                                      double.parse(ingredient
                                                          .servingSize),
                                                );
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    )
                                  : IconButton(
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      iconSize: 20,
                                      color: myBlue60,
                                      onPressed: () {
                                        setState(() {
                                          tempSelected.add(SelectedIngredient(
                                            ingredient: ingredient,
                                            quantity: double.parse(
                                                ingredient.servingSize),
                                          ));
                                        });
                                      },
                                    ),
                            );
                          }),

                          if (searchQuery.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingMore ? null : () async {
                                  setState(() => _isLoadingMore = true); // Use StatefulBuilder's setState
                                  await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
                                  _loadMoreIngredients();
                                  setState(() => _isLoadingMore = false); // Use StatefulBuilder's setState
                                },
                                icon: _isLoadingMore 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add, color: Colors.white),
                                label: Text(
                                  _isLoadingMore ? l10n.loading : l10n.load_more,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: myTeal40,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),





                            
                        ],
                        if (tempSelected
                                .where((i) => i.ingredient.category == 'Manual')
                                .isNotEmpty &&
                            isManualMode) ...[
                          Divider(
                            height: 32,
                            color: theme.brightness == Brightness.light
                                ? myGrey20
                                : myGrey80,
                          ),
                          Text(
                            'Added Ingredients',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              color: theme.brightness == Brightness.light
                                  ? myBlue60
                                  : myGrey10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...tempSelected
                              .where((i) => i.ingredient.category == 'Manual')
                              .map((selected) => ListTile(
                                    title: Text(selected.ingredient.name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '${selected.quantity}${selected.ingredient.servingUnit}'),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: theme.brightness ==
                                                        Brightness.light
                                                    ? Colors.grey[300]
                                                    : myGrey80,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Cal: ${selected.nutrients['calories']?.round() ?? 0}',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color: theme.brightness ==
                                                          Brightness.light
                                                      ? Colors.grey[600]
                                                      : myGrey50,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: theme.brightness ==
                                                        Brightness.light
                                                    ? Colors.grey[300]
                                                    : myGrey80,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'P: ${selected.nutrients['carbs']?.round() ?? 0}g',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color: theme.brightness ==
                                                          Brightness.light
                                                      ? Colors.grey[600]
                                                      : myGrey50,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: theme.brightness ==
                                                        Brightness.light
                                                    ? Colors.grey[300]
                                                    : myGrey80,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'C: ${selected.nutrients['carbs']?.round() ?? 0}g',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color: theme.brightness ==
                                                          Brightness.light
                                                      ? Colors.grey[600]
                                                      : myGrey50,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: theme.brightness ==
                                                        Brightness.light
                                                    ? Colors.grey[300]
                                                    : myGrey80,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'F: ${selected.nutrients['fats']?.round() ?? 0}g',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color: theme.brightness ==
                                                          Brightness.light
                                                      ? Colors.grey[600]
                                                      : myGrey50,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      iconSize: 20,
                                      color: myRed50,
                                      onPressed: () {
                                        setState(() {
                                          tempSelected.remove(selected);
                                        });
                                      },
                                    ),
                                  )),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Bottom action buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.brightness == Brightness.light
                                ? Colors.grey[600]
                                : myGrey50,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onSave(tempSelected);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myBlue60,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _loadMoreIngredients() async {
    final allCategoryIngredients = IngredientsData.getIngredientsBySpecificCategory(context, _selectedSpecificCategory);
    
    final startIndex = _displayedIngredients.length;
    final endIndex = min(startIndex + _pageSize, allCategoryIngredients.length);
    
    if (startIndex < allCategoryIngredients.length) {
      _displayedIngredients.addAll(allCategoryIngredients.sublist(startIndex, endIndex));
    }
  }

  void _showPreparationStepsDialog(
    BuildContext context,
    List<String> existingSteps,
    Function(List<String>) onSave,
  ) {
    List<TextEditingController> stepControllers = existingSteps.isEmpty
        ? [TextEditingController()]
        : existingSteps
            .map((step) => TextEditingController(text: step))
            .toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              children: [
                Text(
                  'Add Preparation Steps',
                  style:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(stepControllers.length, (index) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /*
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: myBlue60.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Step ${index + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: myBlue60,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            */
                            Expanded(
                              child: TextField(
                                controller: stepControllers[index],
                                maxLines: 2,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Step ${index + 1}',
                                  labelStyle: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                  hintText: 'Describe...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                      color: Colors.grey[400]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: myBlue60),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              iconSize: 20,
                              color: myRed50,
                              onPressed: () {
                                if (stepControllers.length > 1) {
                                  setState(() {
                                    stepControllers.removeAt(index);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        stepControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add, size: 20, color: myBlue60),
                    label: Text(
                      'Add Step',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        //fontWeight: FontWeight.w600,
                        color: myBlue60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final steps = stepControllers
                      .where((controller) => controller.text.isNotEmpty)
                      .map((controller) => controller.text)
                      .toList();
                  onSave(steps);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: myBlue60,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Helper Classes
class MealDay {
  final String dayName;
  Map<String, Meal?> meals;

  MealDay({
    required this.dayName,
    required this.meals,
  });

  static List<String> getMealTypes(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.breakfast,
      l10n.morning_snack,
      l10n.lunch,
      l10n.afternoon_snack,
      l10n.dinner,
      l10n.evening_snack,
    ];
  }

  factory MealDay.empty(String dayName) {
    return MealDay(
      dayName: dayName,
      meals: {
        'Breakfast': null,
        'Morning Snack': null,
        'Lunch': null,
        'Afternoon Snack': null,
        'Dinner': null,
        'Evening Snack': null,
      },
    );
  }

  void dispose() {
    // Add any cleanup if needed
  }
}

class Meal {
  String? mealId;
  String name;
  String mealType;
  int calories;
  int protein;
  int carbs;
  int fats;
  String? servingSize;
  String? ingredients;
  List<Map<String, dynamic>>? ingredientDetails;
  String? preparation;
  String? notes;
  bool isManualNutrients;

  Meal({
    this.mealId,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.servingSize,
    this.ingredients,
    this.ingredientDetails,
    this.preparation,
    this.notes,
    this.isManualNutrients = false,
  });
}

// BLoC
abstract class MealPlanEvent {}

class CreateMealPlan extends MealPlanEvent {
  final Map<String, dynamic> data;
  CreateMealPlan({required this.data});
}

class UpdateMealPlan extends MealPlanEvent {
  final Map<String, dynamic> data;
  UpdateMealPlan({required this.data});
}

abstract class MealPlanState {}

class MealPlanInitial extends MealPlanState {}

class MealPlanLoading extends MealPlanState {}

class MealPlanSuccess extends MealPlanState {}

class MealPlanError extends MealPlanState {
  final String message;
  MealPlanError(this.message);
}

class MealPlanBloc extends Bloc<MealPlanEvent, MealPlanState> {
  final _firestore = FirebaseFirestore.instance;
  final BuildContext context;
  final _notificationService = NotificationService(); // Add this line

  MealPlanBloc(this.context) : super(MealPlanInitial()) {
    on<CreateMealPlan>(_createMealPlan);
    on<UpdateMealPlan>(_updateMealPlan);
  }

  Future<void> _createMealPlan(
    CreateMealPlan event,
    Emitter<MealPlanState> emit,
  ) async {
    try {
      emit(MealPlanLoading());
      final userProvider = context.read<UserProvider>();
      final l10n = AppLocalizations.of(context)!;

      final data = event.data;
      if (data['trainerId'] == null ||
          data['clientId'] == null ||
          data['planName'] == null) {
        throw Exception(l10n.required_fields_missing);
      }

      final String planId = _firestore.collection('meals').doc().id;
      final batch = _firestore.batch();

      // Add this section to store new meals
      final trainerMealsRef = _firestore
          .collection('trainer_meals')
          .doc(data['trainerId'])
          .collection('all_meals');

      // Process meals before creating plan
      for (var day in data['mealDays']) {
        for (var meal in day['meals']) {
          if (meal == null) continue;

          // Only store meal if it doesn't have an ID
          if (meal['mealId'] == null) {
            final mealId = trainerMealsRef.doc().id;
            final mealData = {
              'mealId': mealId,
              'name': meal['name'],
              'calories': meal['calories'],
              'protein': meal['protein'],
              'carbs': meal['carbs'],
              'fats': meal['fats'],
              'servingSize': meal['servingSize'],
              'ingredients': meal['ingredients'],
              'ingredientDetails': meal['ingredientDetails'],
              'preparation': meal['preparation'],
              'notes': meal['notes'],
              'isManualNutrients': meal['isManualNutrients'],
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'usageCount': 1,
            };

            batch.set(trainerMealsRef.doc(mealId), mealData);
            meal['mealId'] =
                mealId; // Update the meal's ID in the original data
          } else {
            // Increment usage count for existing meal
            batch.update(trainerMealsRef.doc(meal['mealId']), {
              'usageCount': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      final planData = {
        ...data,
        'planId': planId,
      };

      // Get the professional's role from userData
      final userData = data['trainerId'];
      final userDoc = await _firestore.collection('users').doc(userData).get();
      final userRole = userDoc.data()?['role'] as String?;

      if (userRole != 'trainer') {
        throw Exception('Invalid professional role');
      }

      debugPrint('Adding to professional\'s meals collection');
      // Add to professional's meals collection based on role
      final professionalMealRef = _firestore
          .collection('meals')
          .doc('trainers') // Changed from 'trainers'
          .collection(event.data['trainerId']) // Changed from trainerId
          .doc(planId);

      batch.set(professionalMealRef, planData);

      if (event.data['connectionType'] == fbAppConnectionType) {
        debugPrint('Adding to client\'s meals collection');
        // Add to client's meals collection
        final clientMealRef = _firestore
            .collection('meals')
            .doc('clients')
            .collection(event.data['clientId'])
            .doc(planId);

        batch.set(clientMealRef, planData);

        if (event.data['clientId'] !=
            userProvider.userData?['trainerClientId']) {
          // Replace notification creation with notification service
          await _notificationService.createMealPlanNotification(
            clientId: event.data['clientId'],
            trainerId: event.data['trainerId'],
            planId: planId,
            planData: planData,
          );
        }
      }

      await batch.commit();
      await userProvider.addMealPlan(
        event.data['trainerId'],
        event.data['professionalRole'],
        planData,
      );

      emit(MealPlanSuccess());
    } catch (e) {
      debugPrint('Error creating meal plan: $e');
      emit(MealPlanError('Failed to create meal plan: ${e.toString()}'));
    }
  }

  Future<void> _updateMealPlan(
    UpdateMealPlan event,
    Emitter<MealPlanState> emit,
  ) async {
    try {
      emit(MealPlanLoading());
      final userProvider = context.read<UserProvider>();

      final data = event.data;
      final planId = data['planId'];

      if (planId == null) {
        throw Exception('Plan ID is missing');
      }

      // Create batch write
      final batch = _firestore.batch();

      // Update professional's copy
      final professionalMealRef = _firestore
          .collection('meals')
          .doc('trainers')
          .collection(data['trainerId'])
          .doc(planId);

      batch.update(professionalMealRef, data);

      // Update client's copy if they're an app user
      if (data['connectionType'] == fbAppConnectionType) {
        final clientMealRef = _firestore
            .collection('meals')
            .doc('clients')
            .collection(data['clientId'])
            .doc(planId);

        batch.update(clientMealRef, data);
      }

      // Commit the batch
      await batch.commit();

      // Update the meal plan in UserProvider
      await userProvider.updateMealPlan(
        data['trainerId'],
        data['professionalRole'],
        data,
      );

      emit(MealPlanSuccess());
    } catch (e) {
      debugPrint('Error updating meal plan: $e');
      emit(MealPlanError('Failed to update meal plan: ${e.toString()}'));
    }
  }
}
