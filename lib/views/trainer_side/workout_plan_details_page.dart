// File: lib/views/trainer_side/workout_plan_details_page.dart

import 'package:naturafit/views/client_side/client_workout/workout_in_progress_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/widgets/workout_cards.dart';
import 'package:naturafit/widgets/focus_area_card.dart';
import 'package:naturafit/views/trainer_side/create_workout_plan_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Events
abstract class TrainerWorkoutPlanDetailsEvent {}

class LoadTrainerWorkoutPlanDetails extends TrainerWorkoutPlanDetailsEvent {
  final Map<String, dynamic> planData;
  LoadTrainerWorkoutPlanDetails({required this.planData});
}

// States
abstract class TrainerWorkoutPlanDetailsState {}

class TrainerWorkoutPlanDetailsInitial extends TrainerWorkoutPlanDetailsState {}

class TrainerWorkoutPlanDetailsLoading extends TrainerWorkoutPlanDetailsState {}

class TrainerWorkoutPlanDetailsLoaded extends TrainerWorkoutPlanDetailsState {
  final Map<String, dynamic> planData;
  TrainerWorkoutPlanDetailsLoaded({required this.planData});
}

class TrainerWorkoutPlanDetailsError extends TrainerWorkoutPlanDetailsState {
  final String message;
  TrainerWorkoutPlanDetailsError({required this.message});
}

// BLoC
class TrainerWorkoutPlanDetailsBloc extends Bloc<TrainerWorkoutPlanDetailsEvent,
    TrainerWorkoutPlanDetailsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TrainerWorkoutPlanDetailsBloc() : super(TrainerWorkoutPlanDetailsInitial()) {
    on<LoadTrainerWorkoutPlanDetails>((event, emit) async {
      try {
        emit(TrainerWorkoutPlanDetailsLoading());
        emit(TrainerWorkoutPlanDetailsLoaded(planData: event.planData));
      } catch (e) {
        emit(TrainerWorkoutPlanDetailsError(message: e.toString()));
      }
    });
  }
}

// Main widget classes
class TrainerWorkoutPlanDetailsPage extends StatelessWidget {
  final Map<String, dynamic> planData;

  const TrainerWorkoutPlanDetailsPage({
    Key? key,
    required this.planData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrainerWorkoutPlanDetailsBloc()
        ..add(LoadTrainerWorkoutPlanDetails(planData: planData)),
      child: const TrainerWorkoutPlanDetailsView(),
    );
  }
}

class TrainerWorkoutPlanDetailsView extends StatefulWidget {
  const TrainerWorkoutPlanDetailsView({Key? key}) : super(key: key);

  @override
  State<TrainerWorkoutPlanDetailsView> createState() =>
      _TrainerWorkoutPlanDetailsViewState();
}

class _TrainerWorkoutPlanDetailsViewState
    extends State<TrainerWorkoutPlanDetailsView> {
  String _selectedView = 'schedule'; // 'overview', 'schedule', 'notes'
  int _selectedDay = 1;
  final Map<int, bool> _workoutSelectedMap = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<TrainerWorkoutPlanDetailsBloc,
        TrainerWorkoutPlanDetailsState>(
      builder: (context, state) {
        if (state is TrainerWorkoutPlanDetailsLoading) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator(color: theme.primaryColor)),
          );
        }

        if (state is TrainerWorkoutPlanDetailsLoaded) {
          final plan = state.planData;
          final workoutDays = plan['workoutDays'] as List<dynamic>;

          return Stack(
            children: [
              Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                appBar: _buildAppBar(plan, theme),
                body: Column(
                  children: [
                    _buildViewSelector(theme),
                    if (_selectedView == 'schedule')
                      _buildDaySelector(workoutDays, theme),
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
                                          CreateWorkoutPlanPage(
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
              l10n.error_loading_details,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> plan, ThemeData theme) {
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
        plan['planName'] ?? l10n.workout_plan_details,
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
                builder: (context) => CreateWorkoutPlanPage(
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
          _buildViewTypeButton(
            'overview',
            l10n.overview_tab,
            Icons.description_outlined,
          ),
          const SizedBox(width: 8),
          _buildViewTypeButton(
            'schedule',
            l10n.schedule_tab,
            Icons.calendar_today_outlined,
          ),
          const SizedBox(width: 8),
          _buildViewTypeButton(
            'notes',
            l10n.additional_notes_tab,
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

  Widget _buildDaySelector(List<dynamic> workoutDays, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                          l10n.day_label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayNumber.toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
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

  Widget _buildSelectedView(Map<String, dynamic> plan, ThemeData theme) {
    switch (_selectedView) {
      case 'schedule':
        return _buildScheduleView(plan);
      case 'notes':
        return _buildNotesView(plan, theme);
      case 'overview':
      default:
        return _buildOverviewView(plan, theme);
    }
  }

  Widget _buildOverviewView(Map<String, dynamic> plan, ThemeData theme) {
    // Helper function to check if a value is meaningful
    bool hasMeaningfulValue(dynamic value) {
      return value != null &&
          value.toString().isNotEmpty &&
          value.toString() != 'N/A' &&
          value.toString() != '';
    }

    // Create a list of overview items that have meaningful values
    List<Widget> overviewItems = [];

    final l10n = AppLocalizations.of(context)!;

    if (hasMeaningfulValue(plan['clientFullName'] ?? plan['clientUsername'])) {
      overviewItems.add(_buildOverviewItem(
        plan['status'] == 'template' ? l10n.template : l10n.client,
        plan['clientFullName'] ?? plan['clientUsername']!,
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

    if (hasMeaningfulValue(plan['workoutType'])) {
      overviewItems.add(_buildOverviewItem(
        l10n.type,
        plan['workoutType']!,
        Icons.fitness_center_outlined,
        theme,
      ));
      overviewItems.add(const SizedBox(height: 16));
    }

    if (hasMeaningfulValue(plan['equipment'])) {
      overviewItems.add(_buildOverviewItem(
        l10n.equipment,
        plan['equipment']!,
        Icons.sports_gymnastics_outlined,
        theme,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light ? myGrey70 : myGrey60,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
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
                        color: theme.brightness == Brightness.light ? myGrey10 : myGrey10,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: theme.brightness == Brightness.light ? myGrey30 : myGrey20,
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
                      l10n.no_plan_details_available,
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
            color: theme.brightness == Brightness.light ? myGrey80 : myGrey30,
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
                  color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
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

  Widget _buildScheduleView(Map<String, dynamic> plan) {
    final workoutDays = plan['workoutDays'] as List<dynamic>;
    if (_selectedDay > workoutDays.length) return const SizedBox();

    final selectedDayData = workoutDays[_selectedDay - 1];
    final phases = selectedDayData['phases'] as List<dynamic>;

    return Column(
      children: [
        _buildDayChip(
          selectedDayData,
          _selectedDay - 1,
          plan,
          selectedDayData['focusArea']?.isEmpty ?? true
              ? 'Workout'
              : selectedDayData['focusArea'],
        ),
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0),
            children: [
              const SizedBox(height: 16),
              ...phases.map((phase) => _buildPhaseCard(phase)).toList(),
              const SizedBox(height: 84),
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

  Widget _buildNotesView(Map<String, dynamic> plan, ThemeData theme) {
    final hasWarmUp = plan['warmUp']?.isNotEmpty ?? false;
    final hasCoolDown = plan['coolDown']?.isNotEmpty ?? false;
    final hasProgressionNotes = plan['progressionNotes']?.isNotEmpty ?? false;
    final hasDeloadWeek = plan['deloadWeek']?.isNotEmpty ?? false;
    final hasAdditionalNotes = plan['additionalNotes']?.isNotEmpty ?? false;
    final l10n = AppLocalizations.of(context)!;

    if (!hasWarmUp && !hasCoolDown && !hasProgressionNotes && 
        !hasDeloadWeek && !hasAdditionalNotes) {
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
        if (hasWarmUp)
          _buildNoteCard('Warm-Up Routine', plan['warmUp'], theme),
        if (hasCoolDown)
          _buildNoteCard('Cool-Down Routine', plan['coolDown'], theme),
        if (hasProgressionNotes)
          _buildNoteCard('Progression Notes', plan['progressionNotes'], theme),
        if (hasDeloadWeek)
          _buildNoteCard('Deload Strategy', plan['deloadWeek'], theme),
        if (hasAdditionalNotes)
          _buildNoteCard('Additional Notes', plan['additionalNotes'], theme),
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
                    color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNoteIcon(title),
                    color: theme.brightness == Brightness.light ? myGrey80 : myGrey30,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
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
      case 'warm-up routine':
        return Icons.whatshot_outlined;
      case 'cool-down routine':
        return Icons.ac_unit_outlined;
      case 'progression notes':
        return Icons.trending_up_outlined;
      case 'deload strategy':
        return Icons.refresh_outlined;
      case 'additional notes':
        return Icons.notes_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String getLocalizedStatus(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
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
                      getLocalizedStatus(status).toUpperCase(),
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
                  color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTimestamp(plan['createdAt']),
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
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

  Widget _buildDayChip(Map<String, dynamic> day, int index,
      Map<String, dynamic> workout, String focusArea) {
    final isSelected = _workoutSelectedMap[index] ?? false;
    const baseColor = myRed50;
    const baseColorDay = myRed40;
    const baseColorFaded = myRed30;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: () {
          workout['status'] == 'template'
              ? null
              : setState(() {
                  _workoutSelectedMap[index] =
                      !(_workoutSelectedMap[index] ?? false);
                });
        },
        child: Container(
          //width: 200,
          decoration: BoxDecoration(
            color: isSelected ? baseColorFaded : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.all(4),
            color: isSelected ? baseColor : theme.brightness == Brightness.light ? Colors.white : myGrey80,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? baseColor : theme.brightness == Brightness.light ? myGrey30 : myGrey60,
                width: 1,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? baseColorFaded : theme.brightness == Brightness.light ? myGrey20 : myGrey70,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.track_changes_outlined,
                        color: isSelected ? baseColor : theme.brightness == Brightness.light ? myGrey60 : myGrey30,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Focus Area
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.today_s_focus,
                            style: GoogleFonts.plusJakartaSans(
                              color: isSelected ? Colors.white : theme.brightness == Brightness.light ? myGrey60 : myGrey30,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Text(
                              focusArea,
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? Colors.white : theme.brightness == Brightness.light ? myGrey60 : myGrey30,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (workout['status'] != 'template')
                      GestureDetector(
                        onTap: isSelected
                            ? () {
                                // Get the full plan data from the BLoC state
                                final state = context
                                    .read<TrainerWorkoutPlanDetailsBloc>()
                                    .state;
                                if (state is TrainerWorkoutPlanDetailsLoaded) {
                                  final fullPlan = state.planData;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          WorkoutInProgressPage(
                                        workout:
                                            fullPlan, // Pass the full plan instead of just the day data
                                        selectedDay: index,
                                        isEnteredByTrainer: true,
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : theme.brightness == Brightness.light ? myGrey30 : myGrey60,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            isSelected ? Icons.play_arrow : Icons.pause,
                            color: isSelected ? baseColor : theme.brightness == Brightness.light ? Colors.white : myGrey30,
                            size: 30,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    if (timestamp is Timestamp) {
      final l10n = AppLocalizations.of(context)!;
      final date = timestamp.toDate();
      final months = [
        l10n.january_date,
        l10n.february_date,
        l10n.march_date,
        l10n.april_date,
        l10n.may_date,
        l10n.june_date,
        l10n.july_date,
        l10n.august_date,
        l10n.september_date,
        l10n.october_date,
        l10n.november_date,
        l10n.december_date
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    return 'N/A';
  }
}
