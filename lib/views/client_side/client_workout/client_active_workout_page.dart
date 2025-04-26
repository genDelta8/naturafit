import 'package:naturafit/views/client_side/client_workout/client_short_time_workout_plan.dart';
import 'package:naturafit/views/client_side/client_workout/client_current_workout_plan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum WorkoutPlanType {
  weekly,
  transformation
}

class ActiveWorkoutPlanPage extends StatefulWidget {
  final WorkoutPlanType activePlanType;

  const ActiveWorkoutPlanPage({
    super.key,
    required this.activePlanType,
  });

  @override
  State<ActiveWorkoutPlanPage> createState() => _ActiveWorkoutPlanPageState();
}

class _ActiveWorkoutPlanPageState extends State<ActiveWorkoutPlanPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: Color.fromARGB(128, 255, 255, 255),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          l10n.active_workout_plan,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.more_horiz),
              color: const Color.fromARGB(128, 255, 255, 255),
              onPressed: () {
                /*
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutPlansListPage(),
                  ),
                );
                */
              },
            ),
          ),
        ],
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _buildActivePlanContent(),
    );
  }

  Widget _buildActivePlanContent() {
    final l10n = AppLocalizations.of(context)!;
    
    switch (widget.activePlanType) {
      case WorkoutPlanType.weekly:
        return const CurrentWorkoutPlanPage();
      case WorkoutPlanType.transformation:
        return const ShortTimeWorkoutPage();
    }
  }
}

class WeeklyWorkoutPlanContent extends StatelessWidget {
  const WeeklyWorkoutPlanContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return const CurrentWorkoutPlanPage();
  }
}

class TransformationWorkoutPlanContent extends StatelessWidget {
  const TransformationWorkoutPlanContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return const ShortTimeWorkoutPage();
  }
}