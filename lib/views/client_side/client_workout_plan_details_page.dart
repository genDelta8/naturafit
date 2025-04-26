// File: lib/views/client_side/workout_plan_details_page.dart

import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/widgets/workout_cards.dart';
import 'package:naturafit/widgets/focus_area_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Events
abstract class ClientWorkoutPlanDetailsEvent {}

class LoadClientWorkoutPlanDetails extends ClientWorkoutPlanDetailsEvent {
  final Map<String, dynamic> planData;
  LoadClientWorkoutPlanDetails({required this.planData});
}

// States
abstract class ClientWorkoutPlanDetailsState {}

class ClientWorkoutPlanDetailsInitial extends ClientWorkoutPlanDetailsState {}

class ClientWorkoutPlanDetailsLoading extends ClientWorkoutPlanDetailsState {}

class ClientWorkoutPlanDetailsLoaded extends ClientWorkoutPlanDetailsState {
  final Map<String, dynamic> planData;
  ClientWorkoutPlanDetailsLoaded({required this.planData});
}

class ClientWorkoutPlanDetailsError extends ClientWorkoutPlanDetailsState {
  final String message;
  ClientWorkoutPlanDetailsError({required this.message});
}

// BLoC
class ClientWorkoutPlanDetailsBloc extends Bloc<ClientWorkoutPlanDetailsEvent, ClientWorkoutPlanDetailsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ClientWorkoutPlanDetailsBloc() : super(ClientWorkoutPlanDetailsInitial()) {
    on<LoadClientWorkoutPlanDetails>((event, emit) async {
      try {
        emit(ClientWorkoutPlanDetailsLoading());
        emit(ClientWorkoutPlanDetailsLoaded(planData: event.planData));
      } catch (e) {
        emit(ClientWorkoutPlanDetailsError(message: e.toString()));
      }
    });
  }
}

// Main widget classes
class ClientWorkoutPlanDetailsPage extends StatelessWidget {
  final Map<String, dynamic> planData;

  const ClientWorkoutPlanDetailsPage({
    Key? key,
    required this.planData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ClientWorkoutPlanDetailsBloc()
        ..add(LoadClientWorkoutPlanDetails(planData: planData)),
        child: const ClientWorkoutPlanDetailsView(),
    );
  }
}



class ClientWorkoutPlanDetailsView extends StatefulWidget {
  const ClientWorkoutPlanDetailsView({Key? key}) : super(key: key);

  @override
  State<ClientWorkoutPlanDetailsView> createState() => _ClientWorkoutPlanDetailsViewState();
}

class _ClientWorkoutPlanDetailsViewState extends State<ClientWorkoutPlanDetailsView> {
  String _selectedView = 'schedule'; // 'overview', 'schedule', 'notes'
  int _selectedDay = 1;
  bool _isUpdatingStatus = false;

  bool _isMarkingAsCompleted = false;
  late UserProvider _userProvider;
  late ScaffoldMessengerState _scaffoldMessenger;
  late BuildContext _rootContext;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    _rootContext = context;  // Store the root context
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ClientWorkoutPlanDetailsBloc, ClientWorkoutPlanDetailsState>(
      builder: (context, state) {
        if (state is ClientWorkoutPlanDetailsLoading) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: theme.brightness == Brightness.light ? myBlue60 : myBlue40,
              ),
            ),
          );
        }
        
        if (state is ClientWorkoutPlanDetailsLoaded) {
          final plan = state.planData;
          final workoutDays = plan['workoutDays'] as List<dynamic>;

          return Stack(
            children: [
              Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                appBar: _buildAppBar(plan, l10n),
                body: Column(
                  children: [
                    _buildViewSelector(),
                    if (_selectedView == 'schedule') _buildDaySelector(workoutDays),
                    Expanded(
                      child: _buildSelectedView(plan),
                    ),
                  ],
                ),
              ),

              if (_isMarkingAsCompleted)
              Container(
                color: theme.brightness == Brightness.light 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.brightness == Brightness.light ? myBlue60 : myBlue40,
                  ),
                ),
              )
            ],
          );
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Center(
            child: Text(
              'Error loading workout plan details',
              style: TextStyle(color: theme.brightness == Brightness.light ? Colors.black : Colors.white),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> plan, AppLocalizations l10n) {
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
          plan['planName'] ?? l10n.workout_plan_details,
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
                onTap: _isUpdatingStatus ? null : () async {
                  final notCurrentStatus = 'confirmed';


                  if (plan['status'] != 'current') {
                    // Show loading state
                    setState(() {
                      _isUpdatingStatus = true;
                    });

                    try {
                      debugPrint('Updating status of current plan ${plan['planId']}');
                      // Get current workout plans
                      final userProvider = context.read<UserProvider>();
                      final workoutPlans = userProvider.workoutPlans ?? [];
                      final confirmedWorkoutPlans = workoutPlans.where(
                        (plan) => plan['status'] == 'current'
                      ).toList();

                      for (var currentPlan in confirmedWorkoutPlans) {
                        if (currentPlan['planId'] != null) {  // Add null check
                          try {
                            // First check if document exists
                            final docSnapshot = await FirebaseFirestore.instance
                                .collection('workouts')
                                .doc('clients')
                                .collection(currentPlan['clientId'])
                                .doc(currentPlan['planId'])
                                .get();

                            if (docSnapshot.exists) {
                              await FirebaseFirestore.instance
                                  .collection('workouts')
                                  .doc('clients')
                                  .collection(currentPlan['clientId'])
                                  .doc(currentPlan['planId'])
                                  .update({'status': notCurrentStatus});
                            } else {
                              debugPrint('Document ${currentPlan['planId']} not found');
                            }
                          } catch (e) {
                            debugPrint('Error updating previous current plan: $e');
                          }
                        }
                      }

                      // Verify the current plan's document exists before updating
                      if (plan['planId'] != null) {  // Add null check
                        final docSnapshot = await FirebaseFirestore.instance
                            .collection('workouts')
                            .doc('clients')
                            .collection(plan['clientId'])
                            .doc(plan['planId'])
                            .get();

                        if (docSnapshot.exists) {
                          // Update the selected plan to 'current'
                          setState(() {
                            plan['status'] = 'current';
                            
                            //UPDATE WORKOUT PLANS
                            bool listChanged = false;
                            for (var i = 0; i < workoutPlans.length; i++) {
                              if (workoutPlans[i]['planId'] == plan['planId']) {
                                // Update the selected plan to current
                                workoutPlans[i]['status'] = 'current';
                                listChanged = true;
                              } else if (workoutPlans[i]['status'] == 'current') {
                                // Update previously current plans to active
                                workoutPlans[i]['status'] = notCurrentStatus;
                                listChanged = true;
                              }
                            }
                            
                            // Only update the provider if changes were made
                            if (listChanged) {
                              userProvider.setWorkoutPlans(workoutPlans);
                            }
                          });

                          // Update the selected plan in Firestore
                          await FirebaseFirestore.instance
                              .collection('workouts')
                              .doc('clients')
                              .collection(plan['clientId'])
                              .doc(plan['planId'])
                              .update({'status': 'current'});
                          debugPrint('Plan made current successfully');

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            CustomSnackBar.show(
                              title: l10n.workout_plan,
                              message: l10n.workout_plan_set_as_current_successfully,
                              type: SnackBarType.success,
                            )
                          );
                        } else {
                          throw 'Selected plan document not found in database';
                        }
                      } else {
                        throw 'Plan ID is missing';
                      }
                    } catch (e) {
                      debugPrint('Error making plan current: $e');
                      // Show error message to user with more specific information
                      ScaffoldMessenger.of(context).showSnackBar(
                        CustomSnackBar.show(
                          title: l10n.workout_plan,
                          message: l10n.unable_to_update_plan_status(e.toString()),
                          type: SnackBarType.error,
                        )
                      );
                      
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          //color: myTeal40,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Row(
                          children: [
                            Text(
                              plan['status'] == 'current' ? 'CURRENT' : 'MAKE CURRENT',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12
                              ),
                            ),
                            if (plan['status'] == 'current')
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 16,
                              ),
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
                            builder: (context) => _buildOptionsBottomSheet(context, plan),
                          );
                        },
                        child: Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
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
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: myBlue60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildViewTypeButton(
            'overview',
            'Overview',
            Icons.description_outlined,
          ),
          const SizedBox(width: 8),
          _buildViewTypeButton(
            'schedule',
            'Schedule',
            Icons.calendar_today_outlined,
          ),
          const SizedBox(width: 8),
          _buildViewTypeButton(
            'notes',
            'Additional Notes',
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


Widget _buildDaySelector(List<dynamic> workoutDays) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),  // Removed horizontal padding
      
      child: Center( // Added Center widget
        child: SingleChildScrollView( // Changed to SingleChildScrollView
          scrollDirection: Axis.horizontal,
          child: Row( // Using Row instead of ListView.builder
            mainAxisAlignment: MainAxisAlignment.center, // Center the days
            children: List.generate(workoutDays.length, (index) {
              final dayNumber = index + 1;
              final isSelected = _selectedDay == dayNumber;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = dayNumber;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? myBlue30 : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.all(3),  // Equal margins on both sides
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? myBlue60 :myGrey10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? myBlue60 : myGrey30, width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.day,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayNumber.toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedView(Map<String, dynamic> plan) {
    switch (_selectedView) {
      case 'schedule':
        return _buildScheduleView(plan);
      case 'notes':
        return _buildNotesView(plan);
      case 'overview':
      default:
        return _buildOverviewView(plan);
    }
  }


  Widget _buildOverviewView(Map<String, dynamic> plan) {
    final theme = Theme.of(context);
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

    if (hasMeaningfulValue(plan['trainerFullName'] ?? plan['trainerUsername'])) {
      overviewItems.add(_buildOverviewItem(
        l10n.trainer,
        plan['trainerFullName'] ?? plan['trainerUsername']!,
        Icons.person_outline,
      ));
      overviewItems.add(const SizedBox(height: 16));
    }

    if (hasMeaningfulValue(plan['goal'])) {
      overviewItems.add(_buildOverviewItem(
        l10n.goal,
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

    if (hasMeaningfulValue(plan['workoutType'])) {
      overviewItems.add(_buildOverviewItem(
        'Type',
        plan['workoutType']!,
        Icons.fitness_center_outlined,
      ));
      overviewItems.add(const SizedBox(height: 16));
    }

    if (hasMeaningfulValue(plan['equipment'])) {
      overviewItems.add(_buildOverviewItem(
        'Equipment',
        plan['equipment']!,
        Icons.sports_gymnastics_outlined,
      ));
      overviewItems.add(const SizedBox(height: 16));
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
                      'PLAN OVERVIEW',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: myGrey10,
                      ),
                    ),
                    const Spacer(),
                    Icon(
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
    final l10n = AppLocalizations.of(context)!;
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
            color: theme.brightness == Brightness.light ? myGrey80 : Colors.white,
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
                  color: theme.brightness == Brightness.light ? myGrey60 : Colors.white,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleView(Map<String, dynamic> plan) {
    final workoutDays = plan['workoutDays'] as List<dynamic>;
    if (_selectedDay > workoutDays.length) return const SizedBox();

    final selectedDayData = workoutDays[_selectedDay - 1];
    final phases = selectedDayData['phases'] as List<dynamic>;

    return Column(
      children: [
        if (selectedDayData['focusArea']?.isNotEmpty ?? false)
          FocusAreaCard(
            focusArea: selectedDayData['focusArea'],
          ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0),
            children: [
              
              const SizedBox(height: 16),
              ...phases.map((phase) => _buildPhaseCard(phase)).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseCard(Map<String, dynamic> phase) {
    return WorkoutPhaseCard(
      phase: phase,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildNotesView(Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bool hasNotes = (plan['hydrationGuidelines']?.isNotEmpty ?? false) ||
                         (plan['supplements']?.isNotEmpty ?? false) ||
                         (plan['additionalNotes']?.isNotEmpty ?? false);

    if (!hasNotes) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notes_outlined,
              size: 48,
              color: theme.brightness == Brightness.light ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.no_notes_available,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
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
        if (plan['additionalNotes']?.isNotEmpty ?? false)
          _buildNoteCard('Additional Notes', plan['additionalNotes']),
      ],
    );
  }

  Widget _buildNoteCard(String title, String content) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: theme.brightness == Brightness.light ? Colors.grey[800] : Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final status = plan['status'] ?? 'active';
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
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
                  color: theme.brightness == Brightness.light ? myGrey60 : Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTimestamp(plan['createdAt']),
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.brightness == Brightness.light ? myGrey60 : Colors.white,
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


  Widget _buildOptionsBottomSheet(BuildContext context, Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
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
              color: theme.brightness == Brightness.light ? myGrey30 : myGrey60,
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
                          'Are you sure you want to mark this workout plan as completed?',
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

                    if (clientId == null || trainerId == null || planId == null) {
                      throw 'Missing required plan information';
                    }

                     // Update client document
                    await FirebaseFirestore.instance
                        .collection('workouts')
                        .doc('clients')
                        .collection(plan['clientId'])
                        .doc(plan['planId'])
                        .update({'status': 'completed'});

                    // Update trainer document
                    await FirebaseFirestore.instance
                        .collection('workouts')
                        .doc('trainers')
                        .collection(plan['trainerId'])
                        .doc(plan['planId'])
                        .update({'status': 'completed'});

                    if (!mounted) return;

                    // Update local state
                    final workoutPlans = _userProvider.workoutPlans ?? [];
                    int planIndex = workoutPlans.indexWhere((workoutPlan) => workoutPlan['planId'] == planId);
                    if (planIndex != -1) {
                      workoutPlans[planIndex]['status'] = 'completed';
                      _userProvider.setWorkoutPlans(workoutPlans);
                    }

                    // Navigate and show success message
                    if (mounted) {
                      // First pop the bottom sheet
                      Navigator.pop(_rootContext);
                      
                      // Show success message after navigation completes
                        _scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(l10n.plan_completed),
                            backgroundColor: Colors.green,
                          ),
                        );
                    }
                    
                    debugPrint('Workout plan marked as completed successfully');
                  } catch (e) {
                    debugPrint('Error marking workout plan as completed: ${e.toString()}');
                    
                    if (mounted) {
                      _scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.error_completing_plan(e.toString())),
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
                          l10n.delete_plan_title,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          l10n.delete_plan_message,
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
                              l10n.delete,
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

                    if (clientId == null || trainerId == null || planId == null) {
                      throw 'Missing required plan information';
                    }

                    // Delete client document
                    await FirebaseFirestore.instance
                        .collection('workouts')
                        .doc('clients')
                        .collection(clientId)
                        .doc(planId)
                        .update({'status': 'deleted'});

                    // Update trainer document status to 'deleted'
                    await FirebaseFirestore.instance
                        .collection('workouts')
                        .doc('trainers')
                        .collection(trainerId)
                        .doc(planId)
                        .update({'status': 'deleted'});

                    if (!mounted) return;

                    // Update local state
                    final workoutPlans = _userProvider.workoutPlans ?? [];
                    workoutPlans.removeWhere((workoutPlan) => workoutPlan['planId'] == planId);
                    _userProvider.setWorkoutPlans(workoutPlans);

                    // Navigate and show success message
                    if (mounted) {
                      // First pop the bottom sheet
                      Navigator.pop(_rootContext);
                      
                      // Show success message after navigation completes
                        _scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(l10n.plan_deleted),
                            backgroundColor: Colors.green,
                          ),
                        );
                    }
                    
                    debugPrint('Workout plan deleted successfully');
                  } catch (e) {
                    debugPrint('Error deleting workout plan: ${e.toString()}');
                    
                    if (mounted) {
                      _scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.error_deleting_plan(e.toString())),
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
    
    return 'N/A';
  }
}