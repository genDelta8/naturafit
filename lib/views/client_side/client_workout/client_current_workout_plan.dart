import 'dart:io';

import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/client_side/client_workout/client_workout_plans_page.dart';
import 'package:naturafit/views/client_side/client_workout/workout_in_progress_page.dart';
import 'package:naturafit/views/client_side/client_workout/widgets/client_exercise_card.dart';
import 'package:naturafit/views/web/web_client_side.dart';
import 'package:naturafit/widgets/workout_cards.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WorkoutDay {
  final String name;
  final String focus;
  final List<Exercise> exercises;
  final int dayNumber;

  WorkoutDay({
    required this.name,
    required this.focus,
    required this.exercises,
    required this.dayNumber,
  });
}

class CurrentWorkoutPlanPage extends StatefulWidget {
  const CurrentWorkoutPlanPage({super.key});

  @override
  State<CurrentWorkoutPlanPage> createState() => _CurrentWorkoutPlanPageState();
}

class _CurrentWorkoutPlanPageState extends State<CurrentWorkoutPlanPage> {
  late int _selectedDayNumber;
  final Map<int, bool> _workoutSelectedMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDayNumber = 1;
  }

  navigateToAncestor() {
    final myIsWebOrDektop = isWebOrDesktopCached;
    final webClientState = context.findAncestorStateOfType<WebClientSideState>();
    if (webClientState != null && myIsWebOrDektop) {
      webClientState.setState(() {
        webClientState.setCurrentPage(const ClientWorkoutPlansPage(), 'ClientWorkoutPlansPage');
      });
    }
    else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ClientWorkoutPlansPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final workoutPlans = context.watch<UserProvider>().workoutPlans ?? [];
    final currentPlan = workoutPlans.firstWhere(
      (plan) => plan['status'] == 'current',
      orElse: () => <String, dynamic>{},
    );

    final titleWorkoutDays = currentPlan['workoutDays'] as List<dynamic>? ?? [];
    if (titleWorkoutDays.isEmpty ||
        _selectedDayNumber > titleWorkoutDays.length) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            l10n.current_workout_plan,
            style: GoogleFonts.plusJakartaSans(
              color: theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                    width: 1),
              ),
              child: IconButton(
                icon: const Icon(Icons.fitness_center),
                color: theme.brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                onPressed: () => navigateToAncestor(),
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.no_current_plan_title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.no_current_plan_message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => navigateToAncestor(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: myBlue60,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.view_workout_plans,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }

    final titleSelectedDay = titleWorkoutDays[_selectedDayNumber - 1];
    final titlePhases = titleSelectedDay['phases'] as List<dynamic>? ?? [];

    final baseColor = myRed50;
    final baseColorFaded = myRed30;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        title: currentPlan.isEmpty
            ? Text(
                l10n.current_workout_plan,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentPlan['planName'] == ''
                        ? l10n.workout_plan
                        : (currentPlan['planName'] ?? l10n.workout_plan),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    l10n.created_by(currentPlan['trainerName'] ?? l10n.your_trainer),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.grey[600],
                      letterSpacing: -0.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.brightness == Brightness.light ? Colors.black : Colors.white, width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.fitness_center),
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
              onPressed: () => navigateToAncestor(),
            ),
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: currentPlan.isEmpty
          ? _buildNoCurrentPlan(context)
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDaySelector(currentPlan),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleSelectedDay['focusArea'] ?? l10n.workout,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            titlePhases.length == 1
                                ? '1 ${l10n.phase}'
                                : '${titlePhases.length} ${l10n.phases}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.grey[600],
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _workoutSelectedMap[_selectedDayNumber] =
                                !(_workoutSelectedMap[_selectedDayNumber] ??
                                    false);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: (_workoutSelectedMap[_selectedDayNumber] ??
                                    false)
                                ? baseColorFaded
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (_workoutSelectedMap[_selectedDayNumber] ??
                                      false)
                                  ? myRed50
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    (_workoutSelectedMap[_selectedDayNumber] ??
                                            false)
                                        ? myRed50
                                        : theme.brightness == Brightness.light ? myGrey30 : myGrey70,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              //mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.start_workout,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: (_workoutSelectedMap[
                                                _selectedDayNumber] ??
                                            false)
                                        ? Colors.white
                                        : myGrey60,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Start Button
                                GestureDetector(
                                  onTap: (_workoutSelectedMap[
                                              _selectedDayNumber] ??
                                          false)
                                      ? () {
                                          debugPrint(
                                              'Start workout for day $_selectedDayNumber');

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  WorkoutInProgressPage(
                                                workout: currentPlan,
                                                selectedDay:
                                                    (_selectedDayNumber - 1),
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: (_workoutSelectedMap[
                                                  _selectedDayNumber] ??
                                              false)
                                          ? Colors.white
                                          : theme.brightness == Brightness.light
                                              ? myGrey20
                                              : myGrey80,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      (_workoutSelectedMap[
                                                  _selectedDayNumber] ??
                                              false)
                                          ? Icons.play_arrow
                                          : Icons.pause,
                                      color: (_workoutSelectedMap[
                                                  _selectedDayNumber] ??
                                              false)
                                          ? baseColor
                                          : theme.brightness == Brightness.light
                                              ? Colors.white
                                              : Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildWorkoutContent(currentPlan),
                ),
              ],
            ),
    );
  }

  Widget _buildNoCurrentPlan(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 64,
            color: theme.brightness == Brightness.light
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.no_current_plan_title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.brightness == Brightness.light
                  ? Colors.grey[800]
                  : Colors.grey[200],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.no_current_plan_message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: theme.brightness == Brightness.light
                  ? Colors.grey[600]
                  : Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => navigateToAncestor(),
            style: ElevatedButton.styleFrom(
              backgroundColor: myBlue60,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.view_workout_plans,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDaySelector(Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    final workoutDays = plan['workoutDays'] as List<dynamic>? ?? [];
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: workoutDays.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final workout = entry.value;
          bool isSelected = index == _selectedDayNumber;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayNumber = index;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? myBlue30 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? myBlue60
                      : theme.brightness == Brightness.light
                          ? Colors.white
                          : myGrey80,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isSelected
                          ? myBlue60
                          : theme.brightness == Brightness.light
                              ? myGrey20
                              : myGrey70,
                      width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.day,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : theme.brightness == Brightness.light
                                ? Colors.black
                                : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      index.toString(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : theme.brightness == Brightness.light
                                ? Colors.black
                                : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWorkoutContent(Map<String, dynamic> plan) {
    final l10n = AppLocalizations.of(context)!;
    final workoutDays = plan['workoutDays'] as List<dynamic>? ?? [];
    if (workoutDays.isEmpty || _selectedDayNumber > workoutDays.length) {
      return Center(child: Text(l10n.no_exercises_found));
    }

    final selectedDay = workoutDays[_selectedDayNumber - 1];
    final phases = selectedDay['phases'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
      children: [
        const SizedBox(height: 16),
        ...phases.map((phase) => _buildPhaseCard(phase)).toList(),
      ],
    );
  }

  Widget _buildPhaseCard(Map<String, dynamic> phase) {
    return WorkoutPhaseCard(
      phase: phase,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  
}
