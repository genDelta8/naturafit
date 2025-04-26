import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/views/trainer_side/add_meal_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MealResourcesPage extends StatefulWidget {
  const MealResourcesPage({Key? key}) : super(key: key);

  @override
  State<MealResourcesPage> createState() => _MealResourcesPageState();
}

class _MealResourcesPageState extends State<MealResourcesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> meals = [];
  bool isLoading = true;
  Set<String> _expandedCards = {};
  Set<String> _updatingBookmarks = {};

  @override
  void initState() {
    super.initState();
    _fetchMeals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMeals() async {
    try {
      final userData = context.read<UserProvider>().userData;
      final trainerId = userData?['userId'];
      if (trainerId == null) return debugPrint('trainerId is null');

      final snapshot = await FirebaseFirestore.instance
          .collection('trainer_meals')
          .doc(trainerId)
          .collection('all_meals')
          .get();

      setState(() {
        meals = snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching meals: $e');
    }
  }

  List<Map<String, dynamic>> getFilteredMeals() {
    if (_searchController.text.isEmpty) return meals;
    
    return meals.where((meal) {
      final name = meal['name']?.toString().toLowerCase() ?? '';
      final category = meal['category']?.toString().toLowerCase() ?? '';
      final searchTerm = _searchController.text.toLowerCase();
      
      return name.contains(searchTerm) || category.contains(searchTerm);
    }).toList();
  }

  Future<void> _toggleBookmark(Map<String, dynamic> meal) async {
    final mealId = meal['id'];
    if (mealId == null) return debugPrint('mealId is null');
    
    if (_updatingBookmarks.contains(mealId)) return;

    try {
      setState(() {
        _updatingBookmarks.add(mealId);
      });

      final userData = context.read<UserProvider>().userData;
      final trainerId = userData?['userId'];
      if (trainerId == null) return debugPrint('trainerId is null');

      final isCurrentlyBookmarked = meal['isBookmarked'] == true;

      await FirebaseFirestore.instance
          .collection('trainer_meals')
          .doc(trainerId)
          .collection('all_meals')
          .doc(mealId)
          .update({'isBookmarked': !isCurrentlyBookmarked});

      if (mounted) {
        setState(() {
          final index = meals.indexWhere((e) => e['id'] == mealId);
          if (index != -1) {
            meals[index] = {
              ...meals[index],
              'isBookmarked': !isCurrentlyBookmarked,
            };
          }
          _updatingBookmarks.remove(mealId);
        });
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      if (mounted) {
        setState(() {
          _updatingBookmarks.remove(mealId);
        });
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.meal,
            message: l10n.failed_update_bookmark,
            type: SnackBarType.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final filteredMeals = getFilteredMeals();

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
        title: Row(
          children: [
            Text(
              l10n.meals,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.restaurant_menu, color: Colors.white),
          ],
        ),
        backgroundColor: myBlue60,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddMealPage(),
                  ),
                ).then((added) {
                  if (added == true) {
                    // Refresh exercises list
                    _fetchMeals();
                  }
                });
              },
              label: Text(
                l10n.add,
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
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: myBlue60,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CustomFocusTextField(
                    label: '',
                    hintText: l10n.search_meals,
                    controller: _searchController,
                    prefixIcon: Icons.search,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMeals.isEmpty
                    ? _buildEmptyState()
                    : _buildMealsList(filteredMeals),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList(List<Map<String, dynamic>> meals) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return _buildMealCard(meal);
      },
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isExpanded = _expandedCards.contains(meal['id']);

    return GestureDetector(
      onTap: () {
        setState(() {
          final id = meal['id'];
          if (isExpanded) {
            _expandedCards.remove(id);
          } else {
            _expandedCards.add(id);
          }
        });
      },
      child: Card(
        color: theme.cardColor,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? myGrey70 : myGrey90,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(
                  bottom: BorderSide(
                    color: theme.brightness == Brightness.light ? myGrey30 : myGrey80,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      meal['name'] ?? 'Unnamed Meal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _buildBookmarkIcon(meal),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddMealPage(
                                    isEditing: true,
                                    mealToEdit: meal,
                                  ),
                                ),
                              ).then((edited) {
                                if (edited == true) {
                                  // Refresh exercises list
                                  _fetchMeals();
                                }
                              });
                            },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildNutritionInfo(
                            'Calories',
                            meal['calories']?.toString() ?? '0',
                            Icons.local_fire_department,
                          ),
                        ),
                        Expanded(
                          child: _buildNutritionInfo(
                            'Protein',
                            '${meal['protein']?.toString() ?? '0'}g',
                            Icons.egg_outlined,
                          ),
                        ),
                        Expanded(
                          child: _buildNutritionInfo(
                            'Carbs',
                            '${meal['carbs']?.toString() ?? '0'}g',
                            Icons.grain,
                          ),
                        ),
                        Expanded(
                          child: _buildNutritionInfo(
                            'Fats',
                            '${meal['fats']?.toString() ?? '0'}g',
                            Icons.water_drop_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              secondChild: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildNutritionInfo(
                            'Calories',
                            meal['calories']?.toString() ?? '0',
                            Icons.local_fire_department,
                          ),
                        ),
                        Expanded(
                          child: _buildNutritionInfo(
                            'Protein',
                            '${meal['protein']?.toString() ?? '0'}g',
                            Icons.egg_outlined,
                          ),
                        ),
                        Expanded(
                          child: _buildNutritionInfo(
                            'Carbs',
                            '${meal['carbs']?.toString() ?? '0'}g',
                            Icons.grain,
                          ),
                        ),
                        Expanded(
                          child: _buildNutritionInfo(
                            'Fats',
                            '${meal['fats']?.toString() ?? '0'}g',
                            Icons.water_drop_outlined,
                          ),
                        ),
                      ],
                    ),
                    if (meal['ingredients'] != null) ...[
                      const SizedBox(height: 16),
                      _buildPlanDetail(
                        Icons.restaurant,
                        'Ingredients',
                        meal['ingredients'].toString(),
                      ),
                    ],
                    if (meal['preparation'] != null && meal['preparation'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildPlanDetail(
                        Icons.list_alt,
                        'Preparation',
                        meal['preparation'].toString(),
                      ),
                    ],
                    if (meal['notes'] != null && meal['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildPlanDetail(
                        Icons.notes,
                        'Notes',
                        meal['notes'].toString(),
                      ),
                    ],
                  ],
                ),
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                border: Border(
                  top: BorderSide(
                    color: theme.brightness == Brightness.light ? myGrey30 : myGrey70,
                  ),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (meal['usageCount'] != null)
                    Text(
                      l10n.meal_used_times(meal['usageCount']),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.textTheme.bodySmall?.color,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkIcon(Map<String, dynamic> meal) {
    final mealId = meal['id'];
    final isUpdating = _updatingBookmarks.contains(mealId);

    return GestureDetector(
      onTap: isUpdating ? null : () => _toggleBookmark(meal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUpdating)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(
                meal['isBookmarked'] == true 
                    ? Icons.bookmark 
                    : Icons.bookmark_outline,
                color: Colors.white,
                size: 16,
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
            color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
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
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodySmall?.color,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: theme.textTheme.bodyLarge?.color,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionInfo(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: theme.brightness == Brightness.light ? myGrey70 : myGrey30,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: theme.textTheme.bodySmall?.color,
            letterSpacing: 0.5,
          ),
        ),
      ],
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
            Icons.restaurant_menu,
            size: 64,
            color: theme.brightness == Brightness.light ? myGrey40 : myGrey60,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.no_meals_yet,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.add_first_meal,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
} 