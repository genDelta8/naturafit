import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/client_side/client_meal_plan_details_page.dart';
import 'package:naturafit/views/shared_side/create_meal_plan_page.dart';
import 'package:naturafit/views/trainer_side/meal_plan_details_page.dart';
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

class ClientMealPlansPage extends StatefulWidget {
  const ClientMealPlansPage({Key? key}) : super(key: key);

  @override
  State<ClientMealPlansPage> createState() => _ClientMealPlansPageState();
}

class _ClientMealPlansPageState extends State<ClientMealPlansPage> {
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
    final mealPlans = context.watch<UserProvider>().mealPlans ?? [];
    final myIsWebOrDektop = isWebOrDesktopCached;

    // Filter meal plans based on selection and search
    final filteredPlans = mealPlans.where((plan) {
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

    // Sort the filtered plans to put current plans at the top
    filteredPlans.sort((a, b) {
      // If either plan is 'current', sort it to the top
      if (a['status'] == 'current' && b['status'] != 'current') {
        return -1;
      } else if (b['status'] == 'current' && a['status'] != 'current') {
        return 1;
      }
      // For other cases, maintain the existing order
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
                  l10n.meal_plans_web,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.restaurant_menu_outlined, color: Colors.white),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: myIsWebOrDektop ? [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CustomExpandableSearch(
                  hintText: l10n.search_meal_plans,
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
                    hintText: l10n.search_meal_plans,
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
                          _buildFilterChip(l10n.pending_plans, 'pending'),
                          const SizedBox(width: 8),
                          _buildFilterChip(l10n.filter_completed, 'completed'),
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

    final mealPlans = context.watch<UserProvider>().mealPlans ?? [];
    final pendingMealPlans = mealPlans.where((plan) => plan['status'] == fbCreatedStatusForAppUser).toList();
    final confirmedAndCurrentMealPlans = mealPlans.where((plan) => 
        plan['status'] == 'current' || 
        plan['status'] == fbClientConfirmedStatus || 
        plan['status'] == 'active' ||
        plan['status'] == 'confirmed'
    ).toList();
    final completedMealPlans = mealPlans.where((plan) => plan['status'] == 'completed').toList();

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
                ? l10n.pending_count(pendingMealPlans.length)
                : l10n.pending_plans
            : value == 'active'
                ? confirmedAndCurrentMealPlans.isNotEmpty
                    ? l10n.active_count(confirmedAndCurrentMealPlans.length)
                    : l10n.active_plans
                : value == 'completed'
                    ? completedMealPlans.isNotEmpty
                        ? l10n.completed_count(completedMealPlans.length)
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
          color: isSelected ? myBlue60 : Colors.white,
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
            Icons.restaurant_menu_outlined,
            size: 64,
            color: theme.brightness == Brightness.light ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.no_meal_plans_found,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.brightness == Brightness.light ? Colors.grey[800] : Colors.grey[200],
            ),
          ),
          Text(
            l10n.adjust_meal_filters,
            style: GoogleFonts.plusJakartaSans(
              color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
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
    final macros = plan['macros'] as Map<String, dynamic>?;

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
            builder: (context) => ClientMealPlanDetailsPage(planData: plan),
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
                border: const Border(
                  bottom: BorderSide(color: myGrey30),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      plan['planName'] == '' ? 'Meal Plan' : plan['planName'],
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

            // Plan details
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
                      context,
                    ),
                  if (hasMeaningfulValue(plan['duration'])) ...[
                    const SizedBox(height: 12),
                    _buildPlanDetail(
                      Icons.calendar_today_outlined,
                      l10n.duration_label,
                      plan['duration']!,
                      context,
                    ),
                  ],
                  if (hasMeaningfulValue(plan['dietType'])) ...[
                    const SizedBox(height: 12),
                    _buildPlanDetail(
                      Icons.restaurant_menu_outlined,
                      l10n.diet_type_label,
                      plan['dietType']!,
                      context,
                    ),
                  ],
                  if (macros != null &&
                      hasMeaningfulValue(macros['protein']) &&
                      hasMeaningfulValue(macros['carbs']) &&
                      hasMeaningfulValue(macros['fats'])) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: myGrey20,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.pie_chart_outline,
                            size: 14,
                            color: myGrey70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.macros_label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: myGrey60,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
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

  Widget _buildPlanDetail(IconData icon, String label, String value, BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
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

  Widget _buildMacroIndicator(String label, String value) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: myBlue70.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        l10n.macro_value(label, value),
        style: GoogleFonts.plusJakartaSans(
          color: myBlue70,
          fontWeight: FontWeight.w500,
          fontSize: 12,
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
      case 'completed':
        return const Color(0xFF9E9E9E); // Neutral Grey
      default:
        return const Color(0xFF9E9E9E); // Neutral Grey
    }
  }
}
