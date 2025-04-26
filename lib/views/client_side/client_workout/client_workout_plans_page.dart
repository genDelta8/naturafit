import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/client_side/client_workout_plan_details_page.dart';
import 'package:naturafit/views/trainer_side/create_workout_plan_page.dart';
import 'package:naturafit/views/trainer_side/workout_plan_details_page.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/widgets/custom_expandable_search.dart';

class ClientWorkoutPlansPage extends StatefulWidget {
  const ClientWorkoutPlansPage({Key? key}) : super(key: key);

  @override
  State<ClientWorkoutPlansPage> createState() => _ClientWorkoutPlansPageState();
}

class _ClientWorkoutPlansPageState extends State<ClientWorkoutPlansPage> {
  String _selectedFilter = 'active'; // 'all', 'active', 'pending', 'completed'
  final TextEditingController _searchController = TextEditingController();

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
    final myIsWebOrDektop = isWebOrDesktopCached;

    // Filter workout plans based on selection and search
    final filteredPlans = workoutPlans.where((plan) {
      final matchesFilter = _selectedFilter == 'all' || 
          (_selectedFilter == 'active' && (plan['status'] == 'active' || plan['status'] == 'current' || plan['status'] == 'confirmed')) ||
          plan['status'] == _selectedFilter;
      final matchesSearch = _searchController.text.isEmpty ||
          plan['planName']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          plan['clientName']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    // Sort the filtered plans to put current plan at the top
    filteredPlans.sort((a, b) {
      if (a['status'] == 'current') return -1;
      if (b['status'] == 'current') return 1;
      return 0;
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: myBlue60,
            borderRadius: myIsWebOrDektop ? const BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ) : null,
          ),
          child: AppBar(
            leading: myIsWebOrDektop ? const SizedBox.shrink() : Container(
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
            title: Row(
              children: [
                Text(
                  l10n.workout_plans_web,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.fitness_center_outlined, color: Colors.white),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: myIsWebOrDektop ? [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CustomExpandableSearch(
                  hintText: l10n.search_plans,
                  onChanged: (value) {
                    setState(() {
                      _searchController.text = value;
                    });
                  },
                ),
              ),
            ] : null,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: myIsWebOrDektop ? double.infinity : null,
            decoration: const BoxDecoration(
              color: myBlue60,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: Column(
              children: [
                if (!myIsWebOrDektop) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CustomFocusTextField(
                    label: '',
                    hintText: l10n.search_plans,
                    controller: _searchController,
                    prefixIcon: Icons.search,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                ],
                const SizedBox(height: 8),
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFilterChip(l10n.all_plans, 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip(l10n.active_plans, 'active'),
                          const SizedBox(width: 8),
                          _buildFilterChip(l10n.pending_plans, 'pending'),
                          const SizedBox(width: 8),
                          _buildFilterChip(l10n.completed_plans, 'completed'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: filteredPlans.isEmpty
                ? _buildEmptyState()
                : _buildPlansList(filteredPlans),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final l10n = AppLocalizations.of(context)!;

    final workoutPlans = context.watch<UserProvider>().workoutPlans ?? [];
    final pendingWorkoutPlans = workoutPlans.where((plan) => plan['status'] == fbCreatedStatusForAppUser).toList();
    final confirmedAndCurrentWorkoutPlans = workoutPlans.where(
      (plan) => plan['status'] == 'current' || 
                plan['status'] == fbClientConfirmedStatus ||
                plan['status'] == 'active' ||
                plan['status'] == 'confirmed'
    ).toList();
    final completedWorkoutPlans = workoutPlans.where((plan) => plan['status'] == 'completed').toList();

    // Get appropriate icon for each filter
    IconData filterIcon;
    switch (value) {
      case 'all':
        filterIcon = Icons.all_inclusive;
        break;
      case 'active':
        filterIcon = Icons.check_circle_outline;
        break;
      case 'pending':
        filterIcon = Icons.pause_circle_outline;
        break;
      case 'completed':
        filterIcon = Icons.thumb_up_off_alt_outlined;
        break;
      default:
        filterIcon = Icons.all_inclusive;
    }

    return FilterChip(
      showCheckmark: false,
      avatar: Icon(
        filterIcon,
        size: 18,
        color: isSelected ? myBlue60 : Colors.white,
      ),
      labelPadding: const EdgeInsets.only(left: -4, right: 4),
      label: Text(
        value == 'pending'
            ? pendingWorkoutPlans.isNotEmpty
                ? l10n.pending_count(pendingWorkoutPlans.length)
                : l10n.pending_plans
            : value == 'active'
                ? confirmedAndCurrentWorkoutPlans.isNotEmpty
                    ? l10n.active_count(confirmedAndCurrentWorkoutPlans.length)
                    : l10n.active_plans
                : value == 'completed'
                    ? completedWorkoutPlans.isNotEmpty
                        ? l10n.completed_count(completedWorkoutPlans.length)
                        : l10n.completed_plans
                    : label,
        style: GoogleFonts.plusJakartaSans(
          color: isSelected ? myBlue60 : Colors.white,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: myBlue60,
      selectedColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? myBlue60 : Colors.grey[300]!,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildEmptyState() {
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
            l10n.no_workout_plans,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.brightness == Brightness.light 
                ? Colors.grey[800] 
                : Colors.grey[200],
            ),
          ),
          Text(
            l10n.adjust_filters,
            style: GoogleFonts.plusJakartaSans(
              color: theme.brightness == Brightness.light 
                ? Colors.grey[600] 
                : Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList(List<Map<String, dynamic>> plans) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _buildPlanCard(plan);
      },
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final status = plan['status'] ?? 'active';
    final statusColor = _getStatusColor(status);

    // Helper function to check if a value is meaningful
    bool hasMeaningfulValue(dynamic value) {
      return value != null && 
             value.toString().isNotEmpty && 
             value.toString() != 'N/A' &&
             value.toString() != '';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientWorkoutPlanDetailsPage(planData: plan),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  bottom: BorderSide(color: myGrey30),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      plan['planName'] == '' ? 'Workout Plan' : plan['planName'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: theme.brightness == Brightness.light ? myGrey10 : Colors.white,
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
                  if (hasMeaningfulValue(plan['trainerFullName'] ?? plan['trainerUsername']))
                    _buildPlanDetail(
                      Icons.person_outline,
                      l10n.trainer_label,
                      plan['trainerFullName'] ?? plan['trainerUsername']!,
                    ),
                  if (hasMeaningfulValue(plan['duration'])) ...[
                    const SizedBox(height: 12),
                    _buildPlanDetail(
                      Icons.calendar_today_outlined,
                      l10n.duration_label,
                      plan['duration']!,
                    ),
                  ],
                  if (hasMeaningfulValue(plan['goal'])) ...[
                    const SizedBox(height: 12),
                    _buildPlanDetail(
                      Icons.track_changes_outlined,
                      l10n.goal_label,
                      plan['goal']!,
                    ),
                  ],
                ],
              ),
            ),

            // Bottom action hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                border: Border(
                  top: BorderSide(color: theme.brightness == Brightness.light ? myGrey30 : myGrey60),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    l10n.view_details,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: theme.brightness == Brightness.light ? myGrey60 : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: theme.brightness == Brightness.light ? myGrey60 : Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
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
            color: theme.brightness == Brightness.light ? myGrey70 : myGrey30,
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
                  color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
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
      case 'completed':
        return const Color(0xFF9E9E9E); // Neutral Grey
      default:
        return const Color(0xFF9E9E9E); // Neutral Grey
    }
  }
}
