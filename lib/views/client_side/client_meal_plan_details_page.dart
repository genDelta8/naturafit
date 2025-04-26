import 'package:naturafit/services/unit_preferences.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/views/client_side/client_meal/client_meal_plans_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/widgets/meal_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Events
abstract class ClientMealPlanDetailsEvent {}

class LoadClientMealPlanDetails extends ClientMealPlanDetailsEvent {
  final Map<String, dynamic> planData;
  LoadClientMealPlanDetails({required this.planData});
}

// States
abstract class ClientMealPlanDetailsState {}

class ClientMealPlanDetailsInitial extends ClientMealPlanDetailsState {}

class ClientMealPlanDetailsLoading extends ClientMealPlanDetailsState {}

class ClientMealPlanDetailsLoaded extends ClientMealPlanDetailsState {
  final Map<String, dynamic> planData;
  ClientMealPlanDetailsLoaded({required this.planData});
}

class ClientMealPlanDetailsError extends ClientMealPlanDetailsState {
  final String message;
  ClientMealPlanDetailsError({required this.message});
}

// BLoC
class ClientMealPlanDetailsBloc
    extends Bloc<ClientMealPlanDetailsEvent, ClientMealPlanDetailsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ClientMealPlanDetailsBloc() : super(ClientMealPlanDetailsInitial()) {
    on<LoadClientMealPlanDetails>((event, emit) async {
      try {
        emit(ClientMealPlanDetailsLoading());
        emit(ClientMealPlanDetailsLoaded(planData: event.planData));
      } catch (e) {
        emit(ClientMealPlanDetailsError(message: e.toString()));
      }
    });
  }
}

// Main widget
class ClientMealPlanDetailsPage extends StatelessWidget {
  final Map<String, dynamic> planData;

  const ClientMealPlanDetailsPage({
    Key? key,
    required this.planData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ClientMealPlanDetailsBloc()
        ..add(LoadClientMealPlanDetails(planData: planData)),
      child: const ClientMealPlanDetailsView(),
    );
  }
}

class ClientMealPlanDetailsView extends StatefulWidget {
  const ClientMealPlanDetailsView({Key? key}) : super(key: key);

  @override
  State<ClientMealPlanDetailsView> createState() =>
      _ClientMealPlanDetailsViewState();
}

class _ClientMealPlanDetailsViewState extends State<ClientMealPlanDetailsView> {
  String _selectedView = 'schedule'; // 'overview', 'schedule', 'notes'
  String _selectedDay = 'Monday';
  bool _isUpdatingStatus = false;
  bool _isMarkingAsCompleted = false;
  final Set<String> _expandedMealIds = {};
  late UserProvider _userProvider;
  late ScaffoldMessengerState _scaffoldMessenger;
  late BuildContext _rootContext;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    _rootContext = context; // Store the root context
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitPrefs = context.read<UnitPreferences>();
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    final weightUnit = userData?['weightUnit'] ?? 'kg';
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ClientMealPlanDetailsBloc, ClientMealPlanDetailsState>(
      builder: (context, state) {
        if (state is ClientMealPlanDetailsLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: myBlue60)),
          );
        }

        if (state is ClientMealPlanDetailsLoaded) {
          final plan = state.planData;
          final mealDays = plan['mealDays'] as List<dynamic>;

          return Stack(
            children: [
              Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                appBar: _buildAppBar(plan),
                body: Column(
                  children: [
                    _buildViewSelector(),
                    if (_selectedView == 'schedule')
                      _buildDaySelector(mealDays),
                    Expanded(
                      child: _buildSelectedView(plan, weightUnit, unitPrefs),
                    ),
                  ],
                ),
              ),
              if (_isMarkingAsCompleted)
                Scaffold(
                  backgroundColor: myGrey60.withOpacity(0.3),
                  body: const Center(
                    child: CircularProgressIndicator(color: myBlue60),
                  ),
                )
            ],
          );
        }

        return const Scaffold(
          body: Center(child: Text('Error loading meal plan details')),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> plan) {
    final l10n = AppLocalizations.of(context)!;
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
        plan['planName'] ?? l10n.meal_plan_details,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: _isUpdatingStatus
                  ? null
                  : () async {
                      final notCurrentStatus = 'confirmed';

                      if (plan['status'] != 'current') {
                        // Show loading state
                        setState(() {
                          _isUpdatingStatus = true;
                        });

                        try {
                          debugPrint(
                              'Updating status of current plan ${plan['planId']}');
                          // Get current meal plans
                          final userProvider = context.read<UserProvider>();
                          final mealPlans = userProvider.mealPlans ?? [];
                          final confirmedMealPlans = mealPlans
                              .where((plan) => plan['status'] == 'current')
                              .toList();

                          for (var currentPlan in confirmedMealPlans) {
                            if (currentPlan['planId'] != null) {
                              // Add null check
                              try {
                                // First check if document exists
                                final docSnapshot = await FirebaseFirestore
                                    .instance
                                    .collection('meals')
                                    .doc('clients')
                                    .collection(currentPlan['clientId'])
                                    .doc(currentPlan['planId'])
                                    .get();

                                if (docSnapshot.exists) {
                                  await FirebaseFirestore.instance
                                      .collection('meals')
                                      .doc('clients')
                                      .collection(currentPlan['clientId'])
                                      .doc(currentPlan['planId'])
                                      .update({'status': notCurrentStatus});
                                } else {
                                  debugPrint(
                                      'Document ${currentPlan['planId']} not found');
                                }
                              } catch (e) {
                                debugPrint(
                                    'Error updating previous current plan: $e');
                              }
                            }
                          }

                          // Verify the current plan's document exists before updating
                          if (plan['planId'] != null) {
                            // Add null check
                            final docSnapshot = await FirebaseFirestore.instance
                                .collection('meals')
                                .doc('clients')
                                .collection(plan['clientId'])
                                .doc(plan['planId'])
                                .get();

                            if (docSnapshot.exists) {
                              // Update the selected plan to 'current'
                              setState(() {
                                plan['status'] = 'current';

                                //UPDATE MEAL PLANS
                                bool listChanged = false;
                                for (var i = 0; i < mealPlans.length; i++) {
                                  if (mealPlans[i]['planId'] ==
                                      plan['planId']) {
                                    // Update the selected plan to current
                                    mealPlans[i]['status'] = 'current';
                                    listChanged = true;
                                  } else if (mealPlans[i]['status'] ==
                                      'current') {
                                    // Update previously current plans to active
                                    mealPlans[i]['status'] = notCurrentStatus;
                                    listChanged = true;
                                  }
                                }

                                // Only update the provider if changes were made
                                if (listChanged) {
                                  userProvider.setMealPlans(mealPlans);
                                }
                              });

                              // Update the selected plan in Firestore
                              await FirebaseFirestore.instance
                                  .collection('meals')
                                  .doc('clients')
                                  .collection(plan['clientId'])
                                  .doc(plan['planId'])
                                  .update({'status': 'current'});
                              debugPrint('Plan made current successfully');

                              // Show success message
                              _scaffoldMessenger.showSnackBar(SnackBar(
                                content: Text(
                                    l10n.meal_plan_set_as_current_successfully),
                                backgroundColor: Colors.green,
                              ));
                            } else {
                              throw 'Selected plan document not found in database';
                            }
                          } else {
                            throw 'Plan ID is missing';
                          }
                        } catch (e) {
                          debugPrint('Error making plan current: $e');
                          // Show error message to user with more specific information
                          _scaffoldMessenger.showSnackBar(SnackBar(
                            content: Text('Unable to update plan status: ${e.toString().contains('not-found') ? l10n.plan_not_found_in_database : l10n.an_error_occurred}'),
                            backgroundColor: Colors.red,
                          ));
                        } finally {
                          // Hide loading state
                          if (mounted) {
                            setState(() {
                              _isUpdatingStatus = false;
                            });
                          }
                        }
                      }
                    },
              child: Row(
                children: [
                  Opacity(
                    opacity: _isUpdatingStatus ? 0.5 : 1.0,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        //color: myTeal40,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Row(
                        children: [
                          Text(
                            plan['status'] == 'current'
                                ? l10n.current
                                : l10n.make_current,
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12),
                          ),
                          if (plan['status'] == 'current') ...[ 
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16, left: 8),
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              _buildOptionsBottomSheet(context, plan),
                        );
                      },
                      child: Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isUpdatingStatus)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
      ],
      backgroundColor: myBlue60,
      elevation: 0,
    );
  }

  Widget _buildViewSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: myBlue60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildViewTypeButton(
            'overview',
            l10n.overview,
            Icons.description_outlined,
          ),
          const SizedBox(width: 8),
          _buildViewTypeButton(
            'schedule',
            l10n.meal_schedule,
            Icons.restaurant_menu,
          ),
          const SizedBox(width: 8),
          _buildViewTypeButton(
            'notes',
            l10n.additional_notes,
            Icons.notes_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildViewTypeButton(String type, String label, IconData icon) {
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

  Widget _buildDaySelector(List<dynamic> mealDays) {
    final theme = Theme.of(context);
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
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

              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: GestureDetector(
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
                        color: isSelected
                            ? myBlue60
                            : theme.brightness == Brightness.light
                                ? Colors.white
                                : myGrey80,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? myBlue60
                              : theme.brightness == Brightness.light
                                  ? myGrey20
                                  : myGrey70,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day.substring(0, 1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white
                                  : theme.brightness == Brightness.light
                                      ? Colors.black
                                      : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasMeals
                                  ? (isSelected
                                      ? myBlue40
                                      : theme.brightness == Brightness.light
                                          ? myGrey20
                                          : myGrey60)
                                  : Colors.transparent,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : theme.brightness == Brightness.light
                                        ? Colors.black
                                        : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSelectedView(
      Map<String, dynamic> plan, String weightUnit, UnitPreferences unitPrefs) {
    switch (_selectedView) {
      case 'schedule':
        return _buildScheduleView(plan, weightUnit, unitPrefs);
      case 'notes':
        return _buildNotesView(plan);
      case 'overview':
      default:
        return _buildOverviewView(plan);
    }
  }

  Widget _buildOverviewView(Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    // Helper function to check if a value is meaningful
    bool hasMeaningfulValue(dynamic value) {
      return value != null &&
          value.toString().isNotEmpty &&
          value.toString() != 'N/A' &&
          value.toString() != '';
    }

    // Create a list of overview items that have meaningful values
    List<Widget> overviewItems = [];

    if (hasMeaningfulValue(
        plan['trainerFullName'] ?? plan['trainerUsername'])) {
      overviewItems.add(_buildOverviewItem(
        'Trainer',
        plan['trainerFullName'] ?? plan['trainerUsername']!,
        Icons.person_outline,
      ));
      overviewItems.add(const SizedBox(height: 16));
    }

    if (hasMeaningfulValue(plan['goal'])) {
      overviewItems.add(_buildOverviewItem(
        'Goal',
        plan['goal']!,
        Icons.track_changes_outlined,
      ));
      overviewItems.add(const SizedBox(height: 16));
    }

    if (hasMeaningfulValue(plan['duration'])) {
      overviewItems.add(_buildOverviewItem(
        'Duration',
        plan['duration']!,
        Icons.calendar_today_outlined,
      ));
      overviewItems.add(const SizedBox(height: 16));
    }

    if (hasMeaningfulValue(plan['dietType'])) {
      overviewItems.add(_buildOverviewItem(
        'Diet Type',
        plan['dietType']!,
        Icons.restaurant_menu_outlined,
      ));
      overviewItems.add(const SizedBox(height: 16));
    }

    if (hasMeaningfulValue(plan['caloriesTarget'])) {
      overviewItems.add(_buildOverviewItem(
        'Daily Calories',
        '${plan['caloriesTarget']} kcal',
        Icons.local_fire_department_outlined,
      ));
      overviewItems.add(const SizedBox(height: 16));
    }

    final macros = plan['macros'] as Map<String, dynamic>?;
    if (macros != null &&
        hasMeaningfulValue(macros['protein']) &&
        hasMeaningfulValue(macros['carbs']) &&
        hasMeaningfulValue(macros['fats'])) {
      overviewItems.add(_buildMacrosOverviewItem(macros));
    }

    // Remove the last SizedBox if it exists
    if (overviewItems.isNotEmpty && overviewItems.last is SizedBox) {
      overviewItems.removeLast();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusCard(plan),
        const SizedBox(height: 16),
        Card(
          color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: myGrey70,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(
                    bottom: BorderSide(color: myGrey30),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'PLAN OVERVIEW',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: theme.brightness == Brightness.light
                            ? myGrey10
                            : myGrey10,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: theme.brightness == Brightness.light
                          ? myGrey30
                          : myGrey30,
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
                      'No plan details available',
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

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
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
            color: theme.brightness == Brightness.light ? myGrey80 : myGrey20,
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
                  color: theme.brightness == Brightness.light
                      ? myGrey60
                      : myGrey40,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: theme.brightness == Brightness.light
                      ? myGrey90
                      : myGrey10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacrosOverviewItem(Map<String, dynamic> macros) {
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
                'MACROS DISTRIBUTION',
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
                  _buildMacroIndicator('P', macros['protein'] ?? '0'),
                  const SizedBox(width: 8),
                  _buildMacroIndicator('C', macros['carbs'] ?? '0'),
                  const SizedBox(width: 8),
                  _buildMacroIndicator('F', macros['fats'] ?? '0'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroIndicator(String label, String value) {
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

  Widget _buildScheduleView(
      Map<String, dynamic> plan, String weightUnit, UnitPreferences unitPrefs) {
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
                _selectedDay,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...meals
                  .map((meal) => _buildMealCard(meal, weightUnit, unitPrefs))
                  .toList(),
              if (meals.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No meals planned for this day',
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

  Widget _buildMealCard(
      Map<String, dynamic> meal, String weightUnit, UnitPreferences unitPrefs) {
    // Create a unique identifier for each meal using day and index
    final mealId = '${_selectedDay}_${meal['name']}_${meal['mealType']}';
    
    return CustomMealCard(
      meal: meal,
      weightUnit: weightUnit,
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

  Widget _buildNotesView(Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    final bool hasNotes = (plan['hydrationGuidelines']?.isNotEmpty ?? false) ||
        (plan['supplements']?.isNotEmpty ?? false) ||
        (plan['shoppingList']?.isNotEmpty ?? false) ||
        (plan['additionalNotes']?.isNotEmpty ?? false);

    if (!hasNotes) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notes_outlined,
              size: 48,
              color: theme.brightness == Brightness.light
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No notes available',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: theme.brightness == Brightness.light
                    ? Colors.grey[600]
                    : Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (plan['hydrationGuidelines']?.isNotEmpty ?? false)
          _buildNoteCard('Hydration Guidelines', plan['hydrationGuidelines']),
        if (plan['supplements']?.isNotEmpty ?? false)
          _buildNoteCard('Supplements', plan['supplements']),
        if (plan['shoppingList']?.isNotEmpty ?? false)
          _buildNoteCard('Shopping List', plan['shoppingList']),
        if (plan['additionalNotes']?.isNotEmpty ?? false)
          _buildNoteCard('Additional Notes', plan['additionalNotes']),
      ],
    );
  }

  Widget _buildNoteCard(String title, String content) {
    return Card(
      color: Colors.white,
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
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey[800],
                height: 1.5,
              ),
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

  String getLocalizedStatus(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'current':
        return l10n.current;
      case 'active':
        return l10n.active;
      case 'confirmed':
        return l10n.confirmed;
      case 'pending':
        return l10n.pending;
      case 'template':
        return l10n.template;
      default:
        return status;
    }
  }

  Widget _buildStatusCard(Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    final status = plan['status'] ?? 'active';
    final localizedStatus = getLocalizedStatus(status);
    final statusColor = _getStatusColor(status);
    debugPrint('myPlanCreatedAt: ${plan['createdAt']}');

    return Card(
      color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      localizedStatus.toUpperCase(),
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
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: theme.brightness == Brightness.light
                      ? myGrey60
                      : myGrey40,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTimestamp(plan['createdAt']),
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.brightness == Brightness.light
                        ? myGrey60
                        : myGrey40,
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
      final date = timestamp.toDate();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
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

  Widget _buildOptionsBottomSheet(
      BuildContext context, Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: myGrey30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildOptionTile(
                icon: Icons.check_circle_outline,
                label: 'Mark as Completed',
                color: myBlue60,
                onTap: () async {
                  // Close bottom sheet first
                  Navigator.pop(context);

                  // Show confirmation dialog
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          'Mark as Completed',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to mark this meal plan as completed?',
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(
                                color: myGrey60,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Mark as Completed',
                              style: GoogleFonts.plusJakartaSans(
                                color: myRed50,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (shouldDelete != true || !mounted) return;

                  setState(() {
                    _isMarkingAsCompleted = true;
                  });

                  try {
                    final String? clientId = plan['clientId'];
                    final String? trainerId = plan['trainerId'];
                    final String? planId = plan['planId'];

                    if (clientId == null ||
                        trainerId == null ||
                        planId == null) {
                      throw 'Missing required plan information';
                    }

                    // Update client document
                    await FirebaseFirestore.instance
                        .collection('meals')
                        .doc('clients')
                        .collection(plan['clientId'])
                        .doc(plan['planId'])
                        .update({'status': 'completed'});

                    // Update trainer document
                    await FirebaseFirestore.instance
                        .collection('meals')
                        .doc('trainers')
                        .collection(plan['trainerId'])
                        .doc(plan['planId'])
                        .update({'status': 'completed'});

                    if (!mounted) return;

                    // Update local state
                    final mealPlans = _userProvider.mealPlans ?? [];
                    int planIndex = mealPlans
                        .indexWhere((mealPlan) => mealPlan['planId'] == planId);
                    if (planIndex != -1) {
                      mealPlans[planIndex]['status'] = 'completed';
                      _userProvider.setMealPlans(mealPlans);
                    }

                    // Navigate and show success message
                    if (mounted) {
                      // First pop the bottom sheet
                      Navigator.pop(_rootContext);

                      // Show success message after navigation completes
                      _scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Meal plan marked as completed successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }

                    debugPrint('Meal plan marked as completed successfully');
                  } catch (e) {
                    debugPrint(
                        'Error marking meal plan as completed: ${e.toString()}');

                    if (mounted) {
                      _scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                              'Error marking meal plan as completed: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isMarkingAsCompleted = false;
                      });
                    }
                  }
                },
              ),
              _buildOptionTile(
                icon: Icons.delete_outline,
                label: 'Delete Plan',
                color: myRed50,
                onTap: () async {
                  // Close bottom sheet first
                  Navigator.pop(context);

                  // Show confirmation dialog
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          'Delete Meal Plan',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to delete this meal plan? This action cannot be undone.',
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(
                                color: myGrey60,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Delete',
                              style: GoogleFonts.plusJakartaSans(
                                color: myRed50,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (shouldDelete != true || !mounted) return;

                  setState(() {
                    _isMarkingAsCompleted = true;
                  });

                  try {
                    final String? clientId = plan['clientId'];
                    final String? trainerId = plan['trainerId'];
                    final String? planId = plan['planId'];

                    if (clientId == null ||
                        trainerId == null ||
                        planId == null) {
                      throw 'Missing required plan information';
                    }

                    // Delete client document
                    await FirebaseFirestore.instance
                        .collection('meals')
                        .doc('clients')
                        .collection(clientId)
                        .doc(planId)
                        .update({'status': 'deleted'});

                    // Update trainer document status to 'deleted'
                    await FirebaseFirestore.instance
                        .collection('meals')
                        .doc('trainers')
                        .collection(trainerId)
                        .doc(planId)
                        .update({'status': 'deleted'});

                    if (!mounted) return;

                    // Update local state
                    final mealPlans = _userProvider.mealPlans ?? [];
                    mealPlans.removeWhere(
                        (mealPlan) => mealPlan['planId'] == planId);
                    _userProvider.setMealPlans(mealPlans);

                    // Navigate and show success message
                    if (mounted) {
                      // First pop the bottom sheet
                      Navigator.pop(_rootContext);

                      // Show success message after navigation completes
                      _scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Meal plan deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }

                    debugPrint('Meal plan deleted successfully');
                  } catch (e) {
                    debugPrint('Error deleting meal plan: ${e.toString()}');

                    if (mounted) {
                      _scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content:
                              Text('Error deleting meal plan: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isMarkingAsCompleted = false;
                      });
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
