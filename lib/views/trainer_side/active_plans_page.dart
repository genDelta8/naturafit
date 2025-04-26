import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/trainer_side/create_workout_plan_page.dart';
import 'package:naturafit/views/trainer_side/workout_plan_details_page.dart';
import 'package:naturafit/widgets/custom_expandable_search.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/widgets/workout_plan_card.dart';
import 'package:flutter/gestures.dart';

class ActiveWorkoutPlansPage extends StatefulWidget {
  const ActiveWorkoutPlansPage({Key? key}) : super(key: key);

  @override
  State<ActiveWorkoutPlansPage> createState() => _ActiveWorkoutPlansPageState();
}

class _ActiveWorkoutPlansPageState extends State<ActiveWorkoutPlansPage> {
  String _selectedFilter = 'active'; // 'all', 'active', 'pending', 'template', 'completed'
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
          (_selectedFilter == 'active' && 
              (plan['status'] == 'active' || 
               plan['status'] == 'confirmed' || 
               plan['status'] == 'current')) ||
          (_selectedFilter != 'active' && plan['status'] == _selectedFilter);
      final matchesSearch = _searchController.text.isEmpty ||
          plan['planName']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          plan['clientFullName']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          plan['clientUsername']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: myBlue60,
            borderRadius: myIsWebOrDektop 
                ? const BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  )
                : null,
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
                  myIsWebOrDektop ? l10n.workout_plans_web : l10n.workout_plans,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.fitness_center_outlined, color: Colors.white),
              ],
            ),
            centerTitle: myIsWebOrDektop ? false : true,
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
            ] : [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CreateWorkoutPlanPage()),
                    );
                  },
                  label: Text(
                    l10n.create_workout_plan,
                    style: GoogleFonts.plusJakartaSans(),
                  ),
                  icon: const Icon(
                    Icons.add,
                    size: 18,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    foregroundColor: Colors.white,
                    backgroundColor: myBlue60,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
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
                          _buildFilterChip(l10n.filter_all, 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip(l10n.filter_active, 'active'),
                          const SizedBox(width: 8),
                          _buildFilterChip(l10n.filter_pending, 'pending'),
                          const SizedBox(width: 8),
                          _buildFilterChip(l10n.filter_completed, 'completed'),
                          const SizedBox(width: 8),
                          _buildFilterChip(l10n.filter_templates, 'template'),
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
                ? _buildEmptyState(theme)
                : _buildPlansList(filteredPlans, theme),
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
    final activeAndConfirmedWorkoutPlans = workoutPlans.where((plan) => 
        plan['status'] == fbCreatedStatusForNotAppUser || 
        plan['status'] == fbClientConfirmedStatus ||
        plan['status'] == 'active' ||
        plan['status'] == 'confirmed' ||
        plan['status'] == 'current'
    ).toList();


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
      case 'template':
        filterIcon = Icons.article_outlined;
        break;
      case 'completed':
        filterIcon = Icons.thumb_up_alt_outlined;
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
                ? '${l10n.filter_pending} (${pendingWorkoutPlans.length})'
                : l10n.filter_pending
            : value == 'active'
                ? activeAndConfirmedWorkoutPlans.isNotEmpty
                    ? '${l10n.filter_active} (${activeAndConfirmedWorkoutPlans.length})'
                    : l10n.filter_active
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

  Widget _buildEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 64,
            color: theme.brightness == Brightness.light ? myGrey40 : myGrey60,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.no_workout_plans_found,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.create_new_workout_plan,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList(List<Map<String, dynamic>> plans, ThemeData theme) {
    final sortedPlans = List<Map<String, dynamic>>.from(plans)
      ..sort((a, b) {
        final aCreatedAt = a['createdAt'];
        final bCreatedAt = b['createdAt'];
        
        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;

        final aTimestamp = aCreatedAt is Timestamp 
            ? aCreatedAt 
            : Timestamp((aCreatedAt as Map<String, dynamic>)['_seconds'] as int, 
                       (aCreatedAt)['_nanoseconds'] as int);
                
        final bTimestamp = bCreatedAt is Timestamp 
            ? bCreatedAt 
            : Timestamp((bCreatedAt as Map<String, dynamic>)['_seconds'] as int, 
                       (bCreatedAt)['_nanoseconds'] as int);
        
        return bTimestamp.compareTo(aTimestamp); // Descending order
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedPlans.length,
      itemBuilder: (context, index) {
        final plan = sortedPlans[index];
        return WorkoutPlanCard(
          plan: plan,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrainerWorkoutPlanDetailsPage(planData: plan),
              ),
            );
          },
        );
      },
    );
  }
}
