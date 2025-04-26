import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CompletedWorkoutDetailPage extends StatelessWidget {
  final Map<String, dynamic> workoutData;

  const CompletedWorkoutDetailPage({
    super.key,
    required this.workoutData,
  });

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedAt = (workoutData['completedAt'] as Timestamp).toDate();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.workout_details,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.chevron_left,
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkoutSummary(theme, completedAt, context),
            const SizedBox(height: 24),
            _buildWorkoutFeedback(theme),
            const SizedBox(height: 24),
            _buildPhasesList(theme, context),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutSummary(ThemeData theme, DateTime completedAt, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workoutData['planName'] ?? l10n.completed_workout,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM d, yyyy').format(completedAt),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
              ),
              const SizedBox(width: 4),
              Text(
                _formatDuration(workoutData['totalDuration'] ?? 0),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: myBlue60.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Difficulty: ${workoutData['finishDifficulty'] ?? 'Not rated'}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: myBlue60,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutFeedback(ThemeData theme) {
    final notes = workoutData['finishNotes'];
    if (notes == null || notes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Notes',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhasesList(ThemeData theme, BuildContext context) {
    final phases = workoutData['phases'] as List<dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercises',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...phases.map((phase) => _buildPhaseCard(theme, phase, context)),
      ],
    );
  }

  Widget _buildPhaseCard(ThemeData theme, Map<String, dynamic> phase, BuildContext context) {
    final exercises = phase['exercises'] as List<dynamic>;
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phase['phaseName'] ?? l10n.unnamed_phase,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...exercises.map((exercise) => _buildExerciseCard(theme, exercise, context)),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ThemeData theme, Map<String, dynamic> exercise, BuildContext context) {
    final sets = exercise['sets'] as List<dynamic>;
    final completedSets = sets.where((set) => set['isCompleted'] == true).length;
    final feedback = workoutData['exerciseFeedbacks']?[exercise['exerciseId']];
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? myGrey10 : myGrey90,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise['name'] ?? l10n.unnamed_exercise,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                  ),
                ),
              ),
              if (exercise['isBookmarked'] == true)
                Icon(Icons.bookmark, color: myBlue60, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Equipment: ${exercise['equipment'] ?? l10n.none}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.sets_completed}: $completedSets/${sets.length}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
            ),
          ),
          if (sets.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSetsTable(theme, sets),
          ],
          if (feedback != null) ...[
            const SizedBox(height: 12),
            _buildExerciseFeedback(theme, feedback, context),
          ],
        ],
      ),
    );
  }

  Widget _buildSetsTable(ThemeData theme, List<dynamic> sets) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          children: [
            _buildTableHeader(theme, 'Set'),
            _buildTableHeader(theme, 'Reps'),
            _buildTableHeader(theme, 'Weight'),
            _buildTableHeader(theme, 'Rest'),
          ],
        ),
        ...sets.map((set) => TableRow(
          children: [
            _buildTableCell(theme, '${set['setNumber']}'),
            _buildTableCell(theme, '${set['actual']['reps']} / ${set['assigned']['reps']}'),
            _buildTableCell(theme, '${set['actual']['weight']} / ${set['assigned']['weight']}'),
            _buildTableCell(theme, set['actual']['rest']),
          ],
        )),
      ],
    );
  }

  Widget _buildTableHeader(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildTableCell(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  Widget _buildExerciseFeedback(ThemeData theme, Map<String, dynamic> feedback, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: myGrey20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.feedback,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            ),
          ),
          if (feedback['areas']?.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: (feedback['areas'] as List<dynamic>).map((area) => Chip(
                label: Text(
                  area,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: myBlue60,
                  ),
                ),
                backgroundColor: myBlue60.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              )).toList(),
            ),
          ],
          if (feedback['comment']?.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              feedback['comment'],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
              ),
            ),
          ],
        ],
      ),
    );
  }
} 