import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/views/client_side/client_workout/workout_in_progress_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SelectWorkoutToStartPage extends StatefulWidget {
  const SelectWorkoutToStartPage({super.key});

  @override
  State<SelectWorkoutToStartPage> createState() => _SelectWorkoutToStartPageState();
}

class _SelectWorkoutToStartPageState extends State<SelectWorkoutToStartPage> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, int?> selectedDays = {}; // Store selected day for each workout

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final workoutPlans = context.watch<UserProvider>().workoutPlans ?? [];
    
    // Filter only current and active plans
    final availableWorkouts = workoutPlans
        .where((plan) => plan['status'] == 'current' || plan['status'] == 'active' || plan['status'] == 'confirmed')
        .where((plan) => 
          _searchController.text.isEmpty ||
          plan['planName'].toString().toLowerCase().contains(_searchController.text.toLowerCase())
        )
        .toList();

    // Sort to put current plan first
    availableWorkouts.sort((a, b) {
      if (a['status'] == 'current') return -1;
      if (b['status'] == 'current') return 1;
      return 0;
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
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
          l10n.select_workout,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: myBlue60,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: myBlue60,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CustomFocusTextField(
                label: '',
                controller: _searchController,
                hintText: l10n.search_workouts,
                prefixIcon: Icons.search,
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
          Expanded(
            child: availableWorkouts.isEmpty
                ? Center(
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
                          l10n.no_workouts_found,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.brightness == Brightness.light 
                              ? Colors.grey[600]
                              : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: availableWorkouts.length,
                    itemBuilder: (context, index) {
                      final workout = availableWorkouts[index];
                      return _buildWorkoutCard(workout);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    final theme = Theme.of(context);
    final status = workout['status'] ?? 'active';
    final workoutDays = workout['workoutDays'] as List<dynamic>? ?? [];
    final selectedDay = selectedDays[workout['planId']];
    final statusColor = _getStatusColor(status);

    // Helper function to check if a value is meaningful
    bool hasMeaningfulValue(dynamic value) {
      return value != null && 
             value.toString().isNotEmpty && 
             value.toString() != 'N/A' &&
             value.toString() != '';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 1,
      color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light ? myGrey70 : myGrey90,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(
                  color: theme.brightness == Brightness.light ? myGrey30 : myGrey70
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    workout['planName'] == '' ? 'Workout Plan' : workout['planName'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasMeaningfulValue(workout['trainerName']))
                  _buildPlanDetail(
                    Icons.person_outline,
                    'Trainer',
                    workout['trainerName']!,
                  ),
                if (hasMeaningfulValue(workout['duration'])) ...[
                  const SizedBox(height: 12),
                  _buildPlanDetail(
                    Icons.calendar_today_outlined,
                    'Duration',
                    workout['duration']!,
                  ),
                ],
                if (hasMeaningfulValue(workout['goal'])) ...[
                  const SizedBox(height: 12),
                  _buildPlanDetail(
                    Icons.track_changes_outlined,
                    'Goal',
                    workout['goal']!,
                  ),
                ],
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: workoutDays.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _buildDayChip(workoutDays[index], index, workout),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanDetail(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? myGrey20 : myGrey70,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: theme.brightness == Brightness.light ? myGrey70 : Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
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
      default:
        return const Color(0xFF9E9E9E); // Neutral Grey
    }
  }

  Widget _buildDayChip(Map<String, dynamic> day, int index, Map<String, dynamic> workout) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isSelected = selectedDays[workout['planId']] == index;
    final baseColor = myRed50;
    final baseColorDay = myRed40;
    final baseColorFaded = myRed30;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDays[workout['planId']] = isSelected ? null : index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? baseColorFaded : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.all(4),
          color: isSelected ? baseColor : (theme.brightness == Brightness.light ? Colors.white : myGrey80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? baseColor : (theme.brightness == Brightness.light ? myGrey30 : myGrey70),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Day Number
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? baseColorDay 
                      : (theme.brightness == Brightness.light ? myGrey20 : myGrey70),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Day ${index + 1}',
                    style: GoogleFonts.plusJakartaSans(
                      color: isSelected 
                        ? Colors.white 
                        : (theme.brightness == Brightness.light ? myGrey80 : Colors.white),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                // Focus Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      day['focusArea'] ?? l10n.no_focus_area,
                      style: GoogleFonts.plusJakartaSans(
                        color: isSelected 
                          ? Colors.white 
                          : (theme.brightness == Brightness.light ? myGrey80 : Colors.white),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                // Start Button
                IconButton(
                  onPressed: isSelected ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutInProgressPage(
                          workout: workout,
                          selectedDay: index,
                        ),
                      ),
                    );
                  } : null,
                  icon: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? Colors.white 
                        : (theme.brightness == Brightness.light ? myGrey20 : myGrey70),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      isSelected ? Icons.play_arrow : Icons.pause,
                      color: isSelected 
                        ? baseColor 
                        : (theme.brightness == Brightness.light ? Colors.white : Colors.grey[400]),
                      size: 36,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 