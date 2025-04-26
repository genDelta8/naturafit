import 'package:naturafit/views/shared_side/create_meal_plan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/widgets/meal_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Events
abstract class TrainerMealPlanDetailsEvent {}

class LoadTrainerMealPlanDetails extends TrainerMealPlanDetailsEvent {
  final Map<String, dynamic> planData;
  LoadTrainerMealPlanDetails({required this.planData});
}

// States
abstract class TrainerMealPlanDetailsState {}

class TrainerMealPlanDetailsInitial extends TrainerMealPlanDetailsState {}

class TrainerMealPlanDetailsLoading extends TrainerMealPlanDetailsState {}

class TrainerMealPlanDetailsLoaded extends TrainerMealPlanDetailsState {
  final Map<String, dynamic> planData;
  TrainerMealPlanDetailsLoaded({required this.planData});
}

class TrainerMealPlanDetailsError extends TrainerMealPlanDetailsState {
  final String message;
  TrainerMealPlanDetailsError({required this.message});
}

// BLoC
class TrainerMealPlanDetailsBloc extends Bloc<TrainerMealPlanDetailsEvent, TrainerMealPlanDetailsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TrainerMealPlanDetailsBloc() : super(TrainerMealPlanDetailsInitial()) {
    on<LoadTrainerMealPlanDetails>((event, emit) async {
      try {
        emit(TrainerMealPlanDetailsLoading());
        emit(TrainerMealPlanDetailsLoaded(planData: event.planData));
      } catch (e) {
        emit(TrainerMealPlanDetailsError(message: e.toString()));
      }
    });
  }
}

// Main widget
class TrainerMealPlanDetailsPage extends StatelessWidget {
  final Map<String, dynamic> planData;

  const TrainerMealPlanDetailsPage({
    Key? key,
    required this.planData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrainerMealPlanDetailsBloc()
        ..add(LoadTrainerMealPlanDetails(planData: planData)),
      child: const TrainerMealPlanDetailsView(),
    );
  }
}

class TrainerMealPlanDetailsView extends StatefulWidget {
  const TrainerMealPlanDetailsView({Key? key}) : super(key: key);

  @override
  State<TrainerMealPlanDetailsView> createState() => _TrainerMealPlanDetailsViewState();
}

class _TrainerMealPlanDetailsViewState extends State<TrainerMealPlanDetailsView> {
  String _selectedView = 'schedule'; // 'overview', 'schedule', 'notes'
  String _selectedDay = 'Monday';
  final Set<String> _expandedMealIds = {}; // Add this line to track expanded state

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get current theme

    return BlocBuilder<TrainerMealPlanDetailsBloc, TrainerMealPlanDetailsState>(
      builder: (context, state) {
        if (state is TrainerMealPlanDetailsLoading) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator(color: theme.primaryColor)),
          );
        }

        if (state is TrainerMealPlanDetailsLoaded) {
          final plan = state.planData;
          final mealDays = plan['mealDays'] as List<dynamic>;

          return Stack(
            children: [
              Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                appBar: _buildAppBar(plan),
                body: Column(
                  children: [
                    _buildViewSelector(theme),
                    if (_selectedView == 'schedule') _buildDaySelector(mealDays, theme),
                    Expanded(
                      child: _buildSelectedView(plan, theme),
                    ),
                  ],
                ),
              ),

              if (plan['status'] == 'template')
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          //mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            //const Spacer(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 16),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CreateMealPlanPage(
                                        isEditing: false,
                                        existingPlan: plan,
                                        isUsingTemplate: true,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  //padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: myBlue30,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(3),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 32),
                                    decoration: BoxDecoration(
                                      color: myBlue60,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'USE',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            decoration: TextDecoration.none,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            //const SizedBox(height: 100),
                          ],
                        ),
                      ],
                    )
                  ],
                )
            ],
          );
        }

        return Scaffold(
          body: Center(
            child: Text(
              'Error loading meal plan details',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> plan) {
    final l10n = AppLocalizations.of(context)!;
    final planName = plan['planName'] != null 
      ? (plan['planName'] != '' ? plan['planName'] : l10n.meal_plan_details) 
      : l10n.meal_plan_details;
    
    return AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          planName,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateMealPlanPage(
                    isEditing: true,
                    existingPlan: plan,
                  ),
                ),
              );
            },
          ),
        ],
        backgroundColor: myBlue60,
        elevation: 0,
      );
    
    
  }

  Widget _buildViewSelector(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: myBlue60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildViewTypeButton('overview', l10n.overview, Icons.description_outlined, theme),
          const SizedBox(width: 8),
          _buildViewTypeButton('schedule', l10n.meal_schedule, Icons.restaurant_menu, theme),
          const SizedBox(width: 8),
          _buildViewTypeButton('notes', l10n.additional_notes, Icons.notes_outlined, theme),
        ],
      ),
    );
  }

  Widget _buildViewTypeButton(String type, String label, IconData icon, ThemeData theme) {
    bool isSelected = _selectedView == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = type;
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
          color: isSelected ? Colors.white : myBlue50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? myGrey80 : Colors.white,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(width: isSelected ? 8 : 0),
            ),
            if (isSelected)
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: myGrey80,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedDayInitial(String day) {
    final l10n = AppLocalizations.of(context)!;
    switch (day) {
      case 'Monday':
        return l10n.monday.substring(0, 1);
      case 'Tuesday':
        return l10n.tuesday.substring(0, 1);
      case 'Wednesday':
        return l10n.wednesday.substring(0, 1);
      case 'Thursday':
        return l10n.thursday.substring(0, 1);
      case 'Friday':
        return l10n.friday.substring(0, 1);
      case 'Saturday':
        return l10n.saturday.substring(0, 1);
      case 'Sunday':
        return l10n.sunday.substring(0, 1);
      default:
        return day.substring(0, 1);
    }
  }

  Widget _buildDaySelector(List<dynamic> mealDays, ThemeData theme) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: days.map((day) {
              final isSelected = _selectedDay == day;
              final dayData = mealDays.firstWhere(
                (d) => d['dayName'] == day,
                orElse: () => {'dayName': day, 'meals': []},
              );
              final hasMeals = (dayData['meals'] as List?)?.isNotEmpty ?? false;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? myBlue30 : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 45,
                    margin: const EdgeInsets.all(3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? myBlue60 : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? myBlue60 : theme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getLocalizedDayInitial(day),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasMeals
                                ? (isSelected ? myBlue40 : theme.dividerColor)
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.restaurant_menu,
                              size: 14,
                              color: isSelected ? Colors.white : theme.iconTheme.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedView(Map<String, dynamic> plan, ThemeData theme) {
    switch (_selectedView) {
      case 'schedule':
        return _buildScheduleView(plan, theme);
      case 'notes':
        return _buildNotesView(plan, theme);
      case 'overview':
      default:
        return _buildOverviewView(plan, theme);
    }
  }

  Widget _buildOverviewView(Map<String, dynamic> plan, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    // Helper function to check if a value is meaningful
    bool hasMeaningfulValue(dynamic value) {
      return value != null && 
             value.toString().isNotEmpty && 
             value.toString() != 'N/A' &&
             value.toString() != '';
    }

    // Create a list of overview items that have meaningful values
    List<Widget> overviewItems = [];

    if (hasMeaningfulValue(plan['clientFullName'] ?? plan['clientUsername'])) {
      overviewItems.add(_buildOverviewItem(
        plan['status'] == 'template' ? l10n.template : l10n.client,
        plan['status'] == 'template' ?  plan['templateName'] : (plan['clientFullName'] ?? plan['clientUsername']!),
        Icons.person_outline,
        theme,
      ));
      overviewItems.add(const SizedBox(height: 16));
    }

    if (hasMeaningfulValue(plan['goal'])) {
      overviewItems.add(_buildOverviewItem(
        l10n.goal,
        plan['goal']!,
        Icons.track_changes_outlined,
        theme,
      ));
      overviewItems.add(const SizedBox(height: 16));
    }

    if (hasMeaningfulValue(plan['duration'])) {
      overviewItems.add(_buildOverviewItem(
        l10n.duration,
        plan['duration']!,
        Icons.calendar_today_outlined,
        theme,
      ));
      overviewItems.add(const SizedBox(height: 16));
    }

    if (hasMeaningfulValue(plan['dietType'])) {
      overviewItems.add(_buildOverviewItem(
        l10n.diet_type,
        plan['dietType']!,
        Icons.restaurant_menu_outlined,
        theme,
      ));
      overviewItems.add(const SizedBox(height: 16));
    }

    if (hasMeaningfulValue(plan['caloriesTarget'])) {
      overviewItems.add(_buildOverviewItem(
        l10n.daily_calories,
        '${plan['caloriesTarget']} kcal',
        Icons.local_fire_department_outlined,
        theme,
      ));
      overviewItems.add(const SizedBox(height: 16));
    }

    final macros = plan['macros'] as Map<String, dynamic>?;
    if (macros != null && 
        hasMeaningfulValue(macros['protein']) && 
        hasMeaningfulValue(macros['carbs']) && 
        hasMeaningfulValue(macros['fats'])) {
      overviewItems.add(_buildMacrosOverviewItem(macros, theme));
    }

    // Remove the last SizedBox if it exists
    if (overviewItems.isNotEmpty && overviewItems.last is SizedBox) {
      overviewItems.removeLast();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusCard(plan, theme),
        const SizedBox(height: 16),
        Card(
          color: theme.cardColor,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: myGrey70,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(
                    bottom: BorderSide(color: myGrey30),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.plan_overview,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: myGrey10,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: myGrey30,
                    ),
                  ],
                ),
              ),
              
              // Content
              if (overviewItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: overviewItems,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      l10n.no_plan_details,
                      style: GoogleFonts.plusJakartaSans(
                        color: myGrey60,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? myGrey20 : myGrey70,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.brightness == Brightness.light ? myGrey60 : myGrey30,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: theme.brightness == Brightness.light ? myGrey60 : myGrey30,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacrosOverviewItem(Map<String, dynamic> macros, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: myGrey20,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.pie_chart_outline,
            color: myGrey80,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.macros_distribution,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: myGrey60,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMacroIndicator('P', macros['protein'] ?? '0', theme),
                  const SizedBox(width: 8),
                  _buildMacroIndicator('C', macros['carbs'] ?? '0', theme),
                  const SizedBox(width: 8),
                  _buildMacroIndicator('F', macros['fats'] ?? '0', theme),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroIndicator(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: myBlue60.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value%',
        style: GoogleFonts.plusJakartaSans(
          color: myBlue70,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getLocalizedDayName(String day) {
    final l10n = AppLocalizations.of(context)!;
    switch (day) {
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
        return day;
    }
  }

  Widget _buildScheduleView(Map<String, dynamic> plan, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final mealDays = plan['mealDays'] as List<dynamic>;
    final selectedDayData = mealDays.firstWhere(
      (day) => day['dayName'] == _selectedDay,
      orElse: () => {'dayName': _selectedDay, 'meals': []},
    );
    final meals = selectedDayData['meals'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getLocalizedDayName(_selectedDay),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...meals.map((meal) => _buildMealCard(meal, theme)).toList(),
              if (meals.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.no_meals_planned,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, ThemeData theme) {
    // Create a unique identifier for each meal
    final mealId = '${_selectedDay}_${meal['name']}_${meal['mealType']}';
    
    return CustomMealCard(
      meal: meal,
      weightUnit: 'kg', // You might want to get this from user preferences
      isExpanded: _expandedMealIds.contains(mealId),
      onToggleExpand: () {
        setState(() {
          if (_expandedMealIds.contains(mealId)) {
            _expandedMealIds.remove(mealId);
          } else {
            _expandedMealIds.add(mealId);
          }
        });
      },
    );
  }

  Widget _buildNotesView(Map<String, dynamic> plan, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final hasHydrationGuidelines = plan['hydrationGuidelines']?.isNotEmpty ?? false;
    final hasSupplements = plan['supplements']?.isNotEmpty ?? false;
    final hasShoppingList = plan['shoppingList']?.isNotEmpty ?? false;
    final hasAdditionalNotes = plan['additionalNotes']?.isNotEmpty ?? false;
    
    if (!hasHydrationGuidelines && !hasSupplements && !hasShoppingList && !hasAdditionalNotes) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notes_outlined,
                size: 48,
                color: theme.brightness == Brightness.light ? myGrey40 : myGrey60,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.no_notes_available,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hasHydrationGuidelines)
          _buildNoteCard(l10n.hydration_guidelines, plan['hydrationGuidelines'], theme),
        if (hasSupplements)
          _buildNoteCard(l10n.supplements, plan['supplements'], theme),
        if (hasShoppingList)
          _buildNoteCard(l10n.shopping_list, plan['shoppingList'], theme),
        if (hasAdditionalNotes)
          _buildNoteCard(l10n.additional_notes, plan['additionalNotes'], theme),
      ],
    );
  }

  Widget _buildNoteCard(String title, String content, ThemeData theme) {
    return Card(
      color: theme.cardColor,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: myGrey20,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNoteIcon(title),
                    color: myGrey80,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNoteIcon(String title) {
    switch (title.toLowerCase()) {
      case 'hydration guidelines':
        return Icons.water_drop_outlined;
      case 'supplements':
        return Icons.medication_outlined;
      case 'shopping list':
        return Icons.shopping_cart_outlined;
      case 'additional notes':
        return Icons.notes_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getLocalizedStatus(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'confirmed':
        return l10n.confirmed;
      case 'current':
        return l10n.current;
      case 'active':
        return l10n.active;
      case 'pending':
        return l10n.pending;
      case 'template':
        return l10n.template;
      default:
        return status;
    }
  }

  Widget _buildStatusCard(Map<String, dynamic> plan, ThemeData theme) {
    final status = plan['status'] ?? 'active';
    final statusColor = _getStatusColor(status);
    debugPrint('myPlanCreatedAt: ${plan['createdAt']}');
    
    
    return Card(
      color: theme.cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Status indicator and text
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getLocalizedStatus(status).toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Creation date
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: myGrey60,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTimestamp(plan['createdAt']),
                  style: GoogleFonts.plusJakartaSans(
                    color: myGrey60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    if (timestamp is Timestamp) {
      final l10n = AppLocalizations.of(context)!;
      final date = timestamp.toDate();
      final months = [
        l10n.january_date, l10n.february_date, l10n.march_date, l10n.april_date, l10n.may_date, l10n.june_date,
        l10n.july_date, l10n.august_date, l10n.september_date, l10n.october_date, l10n.november_date, l10n.december_date
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
    
    return 'N/A';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'current':
        return const Color(0xFF2196F3); // Bright Blue
      case 'active':
      case 'confirmed':
        return const Color(0xFF4CAF50); // Vibrant Green
      case 'pending':
        return const Color(0xFFFFC107); // Warm Yellow
      case 'template':
        return const Color(0xFF9C27B0); // Rich Purple
      default:
        return const Color(0xFF9E9E9E); // Neutral Grey
    }
  }
}