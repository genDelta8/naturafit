import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/shared_side/create_meal_plan_page.dart';
import 'package:naturafit/views/trainer_side/meal_plan_details_page.dart';
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
import 'package:naturafit/widgets/meal_plan_card.dart';
import 'package:flutter/gestures.dart';

class ActiveMealPlansPage extends StatefulWidget {
  const ActiveMealPlansPage({Key? key}) : super(key: key);

  @override
  State<ActiveMealPlansPage> createState() => _ActiveMealPlansPageState();
}

class _ActiveMealPlansPageState extends State<ActiveMealPlansPage> {
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
    final mealPlans = context.watch<UserProvider>().mealPlans ?? [];
    final myIsWebOrDektop = isWebOrDesktopCached;

    // Filter meal plans based on selection and search
    final filteredPlans = mealPlans.where((plan) {
      final matchesFilter = _selectedFilter == 'all' || 
          (_selectedFilter == 'active' ? 
              ['active', 'confirmed', 'current'].contains(plan['status']) : 
              plan['status'] == _selectedFilter);
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
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
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
                  myIsWebOrDektop ? l10n.meal_plans_web : l10n.meal_plans,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.restaurant_menu_outlined, color: Colors.white),
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
                          builder: (context) => const CreateMealPlanPage()),
                    );
                  },
                  label: Text(
                    l10n.create_plan,
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
                const SizedBox(height: 12),
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

    final mealPlans = context.watch<UserProvider>().mealPlans ?? [];
    final pendingMealPlans = mealPlans.where((plan) => plan['status'] == fbCreatedStatusForAppUser).toList();
    final activeAndConfirmedMealPlans = mealPlans.where((plan) => 
        plan['status'] == fbCreatedStatusForNotAppUser || 
        plan['status'] == fbClientConfirmedStatus ||
        plan['status'] == 'current').toList();

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
            ? pendingMealPlans.isNotEmpty
                ? '${l10n.filter_pending} (${pendingMealPlans.length})'
                : l10n.filter_pending
            : value == 'active'
                ? activeAndConfirmedMealPlans.isNotEmpty
                    ? '${l10n.filter_active} (${activeAndConfirmedMealPlans.length})'
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
          color: isSelected ? myBlue60 : Colors.white,
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
            Icons.restaurant_menu,
            size: 64,
            color: theme.brightness == Brightness.light ? myGrey40 : myGrey60,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.no_meal_plans_found,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.create_a_new_meal_plan_to_get_started,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList(List<Map<String, dynamic>> plans, ThemeData theme) {
    final sortedPlans = List<Map<String, dynamic>>.from(plans)
      ..sort((a, b) {
        try {
          final aCreatedAt = a['createdAt'];
          final bCreatedAt = b['createdAt'];
          
          if (aCreatedAt == null || bCreatedAt == null) return 0;

          final aTimestamp = aCreatedAt is Timestamp 
              ? aCreatedAt 
              : Timestamp(aCreatedAt['_seconds'], aCreatedAt['_nanoseconds']);
                  
          final bTimestamp = bCreatedAt is Timestamp 
              ? bCreatedAt 
              : Timestamp(bCreatedAt['_seconds'], bCreatedAt['_nanoseconds']);
          
          return bTimestamp.compareTo(aTimestamp);
        } catch (e) {
          return 0;
        }
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedPlans.length,
      itemBuilder: (context, index) {
        final plan = sortedPlans[index];
        return MealPlanCard(
          plan: plan,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrainerMealPlanDetailsPage(planData: plan),
              ),
            );
          },
        );
      },
    );
  }
}
