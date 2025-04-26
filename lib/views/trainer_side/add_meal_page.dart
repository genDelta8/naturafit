import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/ingredients_data.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_select_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:naturafit/widgets/custom_top_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/views/shared_side/create_meal_plan_page.dart';
import 'package:naturafit/models/selected_ingredient.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddMealPage extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? mealToEdit;

  const AddMealPage({
    Key? key,
    this.isEditing = false,
    this.mealToEdit,
  }) : super(key: key);

  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _notesController = TextEditingController();

  List<SelectedIngredient> selectedIngredients = [];
  List<String> preparationSteps = [];
  bool isManualNutrients = false;
  bool isLoading = false;


  // Add near other state variables
  int _currentPage = 0;
  static const int _pageSize = 20;
  List<Ingredient> _displayedIngredients = [];
  bool _isLoadingMore = false;

  String _selectedSpecificCategory = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.mealToEdit != null) {
      _initializeEditData();
    }
  }

  void _initializeEditData() {
    final meal = widget.mealToEdit!;
    _nameController.text = meal['name'] ?? '';
    _caloriesController.text = meal['calories']?.toString() ?? '';
    _proteinController.text = meal['protein']?.toString() ?? '';
    _carbsController.text = meal['carbs']?.toString() ?? '';
    _fatsController.text = meal['fats']?.toString() ?? '';
    _notesController.text = meal['notes'] ?? '';
    isManualNutrients = meal['isManualNutrients'] ?? false;

    // Initialize ingredients if they exist
    if (meal['ingredientDetails'] != null) {
      selectedIngredients = (meal['ingredientDetails'] as List).map((detail) {
        return SelectedIngredient(
          ingredient: Ingredient(
            name: detail['name'],
            category: 'Database',
            calories: (detail['nutrients']['calories'] as num).toDouble(),
            protein: (detail['nutrients']['protein'] as num).toDouble(),
            carbs: (detail['nutrients']['carbs'] as num).toDouble(),
            fats: (detail['nutrients']['fats'] as num).toDouble(),
            servingSize: detail['quantity'].toString(),
            servingUnit: detail['servingUnit'],
            specificCategories: detail['specificCategories'],
          ),
          quantity: (detail['quantity'] as num).toDouble(),
        );
      }).toList();
    }

    // Initialize preparation steps - Fixed version
    if (meal['preparation'] != null && meal['preparation'].toString().isNotEmpty) {
      preparationSteps = meal['preparation']
          .toString()
          .split('\n')
          .map((step) => step.replaceFirst(RegExp(r'Step \d+: '), ''))
          .where((step) => step.isNotEmpty)
          .toList()
          .cast<String>();  // Add explicit cast to String
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addMeal() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.add_meal_snackbar_title,
          message: l10n.please_enter_meal_name,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userData = context.read<UserProvider>().userData;
      final trainerId = userData?['userId'];
      if (trainerId == null) throw Exception(l10n.trainer_id_not_found);

      final mealData = {
        'name': _nameController.text,
        'calories': int.tryParse(_caloriesController.text) ?? 0,
        'protein': int.tryParse(_proteinController.text) ?? 0,
        'carbs': int.tryParse(_carbsController.text) ?? 0,
        'fats': int.tryParse(_fatsController.text) ?? 0,
        'notes': _notesController.text,
        'isManualNutrients': isManualNutrients,
        'ingredients': selectedIngredients
            .map((i) =>
                '${i.ingredient.name}: ${i.quantity}${i.ingredient.servingUnit}')
            .join('\n'),
        'ingredientDetails': selectedIngredients
            .map((i) => {
                  'name': i.ingredient.name,
                  'quantity': i.quantity,
                  'servingUnit': i.ingredient.servingUnit,
                  'nutrients': i.nutrients,
                })
            .toList(),
        'preparation': preparationSteps
            .asMap()
            .entries
            .where((entry) => entry.value.isNotEmpty)
            .map((entry) => 'Step ${entry.key + 1}: ${entry.value}')
            .join('\n'),
        'usageCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.isEditing) {
        await FirebaseFirestore.instance
            .collection('trainer_meals')
            .doc(trainerId)
            .collection('all_meals')
            .doc(widget.mealToEdit!['id'])
            .update(mealData);
      } else {
        mealData['createdAt'] = FieldValue.serverTimestamp();
        mealData['isBookmarked'] = false;

        await FirebaseFirestore.instance
            .collection('trainer_meals')
            .doc(trainerId)
            .collection('all_meals')
            .add(mealData);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.add_meal_snackbar_title,
            message: l10n.failed_save_meal,
            type: SnackBarType.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Calculate total nutrients from ingredients if not manual
    int totalCalories = 0;
    int totalProtein = 0;
    int totalCarbs = 0;
    int totalFats = 0;

    if (!isManualNutrients) {
      for (var selected in selectedIngredients) {
        final nutrients = selected.nutrients;
        totalCalories += nutrients['calories']!.round();
        totalProtein += nutrients['protein']!.round();
        totalCarbs += nutrients['carbs']!.round();
        totalFats += nutrients['fats']!.round();
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
              width: 1
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.chevron_left,
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          widget.isEditing ? l10n.edit_meal_title : l10n.add_meal_title,
          style: GoogleFonts.plusJakartaSans(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.85,
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light ? myGrey10 : myGrey100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          
                  
                          // Content
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomFocusTextField(
                                    label: l10n.meal_name,
                                    hintText: l10n.enter_meal_name,
                                    controller: _nameController,
                                    prefixIcon: Icons.restaurant_menu,
                                    onChanged: (value) => setState(() {}),
                                  ),
                                  const SizedBox(height: 16),
                                  Card(
                                    elevation: 1,
                                    color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                isManualNutrients
                                                    ? l10n.total_nutrients_manual
                                                    : l10n.total_nutrients_calculated,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: myBlue60,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  isManualNutrients
                                                      ? Icons.edit
                                                      : Icons.edit_outlined,
                                                  size: 20,
                                                  color: myBlue60,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    isManualNutrients =
                                                        !isManualNutrients;
                                                    if (isManualNutrients) {
                                                      _caloriesController.text =
                                                          totalCalories.toString();
                                                      _proteinController.text =
                                                          totalProtein.toString();
                                                      _carbsController.text =
                                                          totalCarbs.toString();
                                                      _fatsController.text =
                                                          totalFats.toString();
                                                    }
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          if (isManualNutrients)
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _caloriesController,
                                                    keyboardType: TextInputType.number,
                                                    decoration: InputDecoration(
                                                      labelText: 'Calories',
                                                      labelStyle:
                                                          GoogleFonts.plusJakartaSans(
                                                              fontSize: 12),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                        borderSide: BorderSide(
                                                            color: Colors.grey[400]!),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                        borderSide:
                                                            BorderSide(color: myBlue60),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                        borderSide: BorderSide(
                                                            color: Colors.grey[400]!),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: TextField(
                                                    controller: _proteinController,
                                                    keyboardType: TextInputType.number,
                                                    decoration: InputDecoration(
                                                      labelText: 'Protein (g)',
                                                      labelStyle:
                                                          GoogleFonts.plusJakartaSans(
                                                              fontSize: 12),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                        borderSide: BorderSide(
                                                            color: Colors.grey[400]!),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                        borderSide:
                                                            BorderSide(color: myBlue60),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                        borderSide: BorderSide(
                                                            color: Colors.grey[400]!),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: TextField(
                                                    controller: _carbsController,
                                                    keyboardType: TextInputType.number,
                                                    decoration: InputDecoration(
                                                      labelText: 'Carbs (g)',
                                                      labelStyle:
                                                          GoogleFonts.plusJakartaSans(
                                                              fontSize: 12),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                        borderSide: BorderSide(
                                                            color: Colors.grey[400]!),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                        borderSide:
                                                            BorderSide(color: myBlue60),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                        borderSide: BorderSide(
                                                            color: Colors.grey[400]!),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: TextField(
                                                    controller: _fatsController,
                                                    keyboardType: TextInputType.number,
                                                    decoration: InputDecoration(
                                                      labelText: 'Fats (g)',
                                                      labelStyle:
                                                          GoogleFonts.plusJakartaSans(
                                                              fontSize: 12),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                        borderSide: BorderSide(
                                                            color: Colors.grey[400]!),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                        borderSide:
                                                            BorderSide(color: myBlue60),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                        borderSide: BorderSide(
                                                            color: Colors.grey[400]!),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                _buildNutrientInfo(
                                                    'Calories', totalCalories),
                                                _buildNutrientInfo(
                                                    'Protein', totalProtein, 'g'),
                                                _buildNutrientInfo(
                                                    'Carbs', totalCarbs, 'g'),
                                                _buildNutrientInfo(
                                                    'Fats', totalFats, 'g'),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Spacer(),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _showIngredientSelectionDialog(
                                            context,
                                            selectedIngredients,
                                            (updatedIngredients) {
                                              setState(() {
                                                selectedIngredients =
                                                    updatedIngredients;
                                              });
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.add),
                                        label: Text(l10n.add_ingredients),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: myBlue60,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (selectedIngredients.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[200]!),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.added_ingredients,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                              color: myBlue60,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...selectedIngredients.map((ingredient) =>
                                              ListTile(
                                                title: Text(ingredient.ingredient.name),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        '${ingredient.quantity}${ingredient.ingredient.servingUnit}'),
                                                    Wrap(
                                                      spacing: 4,
                                                      runSpacing: 4,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey[200],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    4),
                                                          ),
                                                          child: Text(
                                                            'Cal: ${ingredient.nutrients['calories']?.round() ?? 0}',
                                                            style: GoogleFonts
                                                                .plusJakartaSans(
                                                              color: Colors.grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey[200],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    4),
                                                          ),
                                                          child: Text(
                                                            'P: ${ingredient.nutrients['protein']?.round() ?? 0}g',
                                                            style: GoogleFonts
                                                                .plusJakartaSans(
                                                              color: Colors.grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey[200],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    4),
                                                          ),
                                                          child: Text(
                                                            'C: ${ingredient.nutrients['carbs']?.round() ?? 0}g',
                                                            style: GoogleFonts
                                                                .plusJakartaSans(
                                                              color: Colors.grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey[200],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    4),
                                                          ),
                                                          child: Text(
                                                            'F: ${ingredient.nutrients['fats']?.round() ?? 0}g',
                                                            style: GoogleFonts
                                                                .plusJakartaSans(
                                                              color: Colors.grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                trailing: IconButton(
                                                  icon: const Icon(
                                                      Icons.remove_circle_outline),
                                                  iconSize: 20,
                                                  color: Colors.red,
                                                  onPressed: () {
                                                    setState(() {
                                                      selectedIngredients
                                                          .remove(ingredient);
                                                    });
                                                  },
                                                ),
                                              )),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 32),
                                  CustomFocusTextField(
                                    label: l10n.meal_notes,
                                    hintText: l10n.meal_notes_hint,
                                    controller: _notesController,
                                    prefixIcon: Icons.note_add,
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 120),
                                ],
                              ),
                            ),
                          ),
                  
                          
                        ],
                      ),
                    ),
                  ),
                ),
              ),


              // Bottom actions
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light ? myGrey10 : myGrey100,
                      borderRadius: BorderRadius.circular(0),
                      //border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[400]!),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              l10n.cancel,
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.grey[600]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _addMeal();
                                
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: myBlue60,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.isEditing ? l10n.update : l10n.add,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
          if (isLoading)
            Container(
              color: theme.brightness == Brightness.light 
                  ? Colors.black.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(color: myBlue60),
              ),
            ),
            
        ],
      ),
    );
  }


  Widget _buildNutrientInfo(String label, int value, [String unit = '']) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value.toString() + unit,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: theme.brightness == Brightness.light ? myBlue60 : myGrey40,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }


  void _showIngredientSelectionDialog(
    BuildContext context,
    List<SelectedIngredient> selectedIngredients,
    Function(List<SelectedIngredient>) onSave,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    String searchQuery = '';
    bool isManualMode = false;
    final searchController = TextEditingController();
    //String selectedSpecificCategory = 'All';  // Local state for category selection
    final List<SelectedIngredient> tempSelected = List.from(selectedIngredients);

    // Controllers for manual ingredient entry
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatsController = TextEditingController();
    final servingSizeController = TextEditingController();
    String manualSelectedServingUnit = '';
    final weightUnit = context.read<UserProvider>().userData?['weightUnit'] ?? 'kg';



    final specializationCategories = {
      'All': 'All',
      'Meat & Fish': 'Meat & Fish',
      'Plant-Based Protein': 'Plant-Based Protein',
      'Carbs': 'Carbs',
      'Healthy Fats': 'Healthy Fats',
      'Nuts & Seeds': 'Nuts & Seeds',
      'Fruits': 'Fruits',
      'Vegetables & Greens': 'Vegetables & Greens',
      'Dairy & Alternatives': 'Dairy & Alternatives',
      'Spices & Herbs': 'Spices & Herbs',
      'Condiments': 'Condiments',
    };


    // Initialize first 20 ingredients for 'All' category
    _selectedSpecificCategory = 'All';
    _currentPage = 0;
    _displayedIngredients.clear();
    final initialIngredients = IngredientsData.getIngredientsBySpecificCategory(context, 'All');
    _displayedIngredients = initialIngredients.take(_pageSize).toList();




    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.brightness == Brightness.light ? Colors.white : myGrey100,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: theme.brightness == Brightness.light ? Colors.transparent : myGrey80),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredIngredients = searchQuery.isEmpty
              ? _displayedIngredients // Show paginated results when not searching
              : IngredientsData.getIngredientsBySpecificCategory(
                      context, _selectedSpecificCategory)
                  .where((ingredient) => ingredient.name
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                  .toList();

          return Container(
            height: (MediaQuery.of(context).size.height * 0.85) - 56,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top section with mode selection
                CustomTopSelector(
                  options: [
                    TopSelectorOption(title: l10n.database),
                    TopSelectorOption(title: l10n.manual),
                  ],
                  selectedIndex: isManualMode ? 1 : 0,
                  onOptionSelected: (value) => setState(() => isManualMode = value == 1),
                ),
                
                const SizedBox(height: 12),

                // Search bar (only shown in database mode)
                if (!isManualMode) ...[

                  SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        ...specializationCategories.keys.map((category) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSpecificCategory = category;
                                _currentPage = 0;
                                final categoryIngredients =
                                    IngredientsData.getIngredientsBySpecificCategory(
                                        context, category);
                                _displayedIngredients =
                                    categoryIngredients.take(_pageSize).toList();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedSpecificCategory == category
                                      ? myGrey30
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: _selectedSpecificCategory == category
                                        ? myGrey90
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _selectedSpecificCategory == category
                                          ? Colors.transparent
                                          : theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Text(
                                    category,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: _selectedSpecificCategory == category
                                          ? Colors.white
                                          : theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),


                  CustomFocusTextField(
                    label: '',
                    hintText: 'Search ingredients...',
                    controller: searchController,
                    prefixIcon: Icons.search,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ],

                const SizedBox(height: 12),

                // After the search bar and before bottom buttons
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isManualMode) ...[
                          const SizedBox(height: 12),
                          CustomFocusTextField(
                            label: l10n.ingredient_name,
                            hintText: l10n.ingredient_name_hint,
                            controller: nameController,
                            prefixIcon: Icons.restaurant_menu,
                            isRequired: true,
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.serving,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: theme.brightness == Brightness.light
                                      ? myGrey90
                                      : Colors.white,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: CustomFocusTextField(
                                      label: '',
                                      hintText: weightUnit == 'kg'
                                          ? l10n.serving_hint_metric
                                          : l10n.serving_hint_imperial,
                                      controller: servingSizeController,
                                      prefixIcon: Icons.monitor_weight_outlined,
                                      isRequired: false,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          title: Text(
                                            l10n.select_unit,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          content: IntrinsicHeight(
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ...[
                                                    weightUnit == 'kg' ? 'g' : 'oz',
                                                    'ml',
                                                    'pc',
                                                    'cup',
                                                    'tbsp',
                                                  ].map((unit) => ListTile(
                                                    contentPadding: EdgeInsets.zero,
                                                    title: Text(
                                                      unit,
                                                      style: GoogleFonts.plusJakartaSans(),
                                                    ),
                                                    onTap: () {
                                                      setState(() {
                                                        manualSelectedServingUnit = unit;
                                                      });
                                                      Navigator.pop(context);
                                                    },
                                                  )).toList(),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      //width: 60,
                                      height: 59,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: myGrey20,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          Text(manualSelectedServingUnit, style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: theme.brightness == Brightness.light
                                                ? myGrey90
                                                : Colors.white,
                                          ),),
                                          const Icon(Icons.arrow_drop_down),
                                          const SizedBox(width: 4),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          CustomFocusTextField(
                            label: 'Calories',
                            hintText: 'e.g., 100kcal',
                            controller: caloriesController,
                            prefixIcon: Icons.local_fire_department_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: CustomFocusTextField(
                                  label: 'Protein',
                                  hintText: 'e.g., 100g',
                                  controller: proteinController,
                                  isRequired: false,
                                ),
                              ),
                              Expanded(
                                child: CustomFocusTextField(
                                  label: 'Carbs',
                                  hintText: 'e.g., 100g',
                                  controller: carbsController,
                                  isRequired: false,
                                ),
                              ),
                              Expanded(
                                child: CustomFocusTextField(
                                  label: 'Fats',
                                  hintText: 'e.g., 100g',
                                  controller: fatsController,
                                  isRequired: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (nameController.text.isNotEmpty &&
                                  servingSizeController.text.isNotEmpty) {
                                final manualIngredient = Ingredient(
                                  name: nameController.text,
                                  category: 'Manual',
                                  specificCategories: ['All'],
                                  calories: double.tryParse(
                                          caloriesController.text) ??
                                      0,
                                  protein:
                                      double.tryParse(proteinController.text) ??
                                          0,
                                  carbs:
                                      double.tryParse(carbsController.text) ??
                                          0,
                                  fats:
                                      double.tryParse(fatsController.text) ?? 0,
                                  servingSize: servingSizeController.text,
                                  servingUnit: manualSelectedServingUnit,
                                );
                                setState(() {
                                  tempSelected.add(SelectedIngredient(
                                    ingredient: manualIngredient,
                                    quantity: double.parse(
                                        servingSizeController.text),
                                  ));
                                });
                                // Clear fields after adding
                                nameController.clear();
                                servingSizeController.clear();
                                caloriesController.clear();
                                proteinController.clear();
                                carbsController.clear();
                                fatsController.clear();
                                manualSelectedServingUnit = '';
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: myBlue60,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              l10n.add_ingredient,
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white),
                            ),
                          ),
                        ] else ...[
                          // Food database list with quantity controls
                          ...filteredIngredients.map((ingredient) {
                            final isSelected = tempSelected.any(
                                (s) => s.ingredient.name == ingredient.name);
                            final selectedIngredient = tempSelected.firstWhere(
                              (s) => s.ingredient.name == ingredient.name,
                              orElse: () => SelectedIngredient(
                                ingredient: ingredient,
                                quantity: double.parse(ingredient.servingSize),
                              ),
                            );

                            return ListTile(
                              title: Text(ingredient.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${ingredient.servingSize}${ingredient.servingUnit}'),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.brightness == Brightness.light 
                                              ? Colors.grey[300]
                                              : myGrey80,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Cal: ${ingredient.calories.round()}',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: theme.textTheme.bodySmall?.color,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.brightness == Brightness.light 
                                              ? Colors.grey[300]
                                              : myGrey80,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'P: ${ingredient.protein.round()}g',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: theme.textTheme.bodySmall?.color,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.brightness == Brightness.light 
                                              ? Colors.grey[300]
                                              : myGrey80,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'C: ${ingredient.carbs.round()}g',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: theme.textTheme.bodySmall?.color,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.brightness == Brightness.light 
                                              ? Colors.grey[300]
                                              : myGrey80,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'F: ${ingredient.fats.round()}g',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: theme.textTheme.bodySmall?.color,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: isSelected
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline),
                                          iconSize: 20,
                                          color: Colors.red,
                                          onPressed: () {
                                            setState(() {
                                              if (selectedIngredient.quantity <=
                                                  double.parse(
                                                      ingredient.servingSize)) {
                                                tempSelected
                                                    .remove(selectedIngredient);
                                              } else {
                                                final index =
                                                    tempSelected.indexOf(
                                                        selectedIngredient);
                                                tempSelected[index] =
                                                    SelectedIngredient(
                                                  ingredient: ingredient,
                                                  quantity: selectedIngredient
                                                          .quantity -
                                                      double.parse(ingredient
                                                          .servingSize),
                                                );
                                              }
                                            });
                                          },
                                        ),
                                        Text(
                                          '${(selectedIngredient.quantity).toStringAsFixed(0)}${ingredient.servingUnit}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          iconSize: 20,
                                          color: myBlue60,
                                          onPressed: () {
                                            setState(() {
                                              final index = tempSelected
                                                  .indexOf(selectedIngredient);
                                              if (index >= 0) {
                                                tempSelected[index] =
                                                    SelectedIngredient(
                                                  ingredient: ingredient,
                                                  quantity: selectedIngredient
                                                          .quantity +
                                                      double.parse(ingredient
                                                          .servingSize),
                                                );
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    )
                                  : IconButton(
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      iconSize: 20,
                                      color: myBlue60,
                                      onPressed: () {
                                        setState(() {
                                          tempSelected.add(SelectedIngredient(
                                            ingredient: ingredient,
                                            quantity: double.parse(
                                                ingredient.servingSize),
                                          ));
                                        });
                                      },
                                    ),
                            );
                          }),


                          if (searchQuery.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingMore ? null : () async {
                                  setState(() => _isLoadingMore = true);
                                  await Future.delayed(const Duration(milliseconds: 500));
                                  _loadMoreIngredients();
                                  setState(() => _isLoadingMore = false);
                                },
                                icon: _isLoadingMore 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add, color: Colors.white),
                                label: Text(
                                  _isLoadingMore ? l10n.loading : l10n.load_more,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: myTeal40,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),



                        ],
                        if (tempSelected
                                .where((i) => i.ingredient.category == 'Manual')
                                .isNotEmpty &&
                            isManualMode) ...[
                          const Divider(height: 32),
                          Text(
                            l10n.added_ingredients,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              color: myBlue60,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...tempSelected
                              .where((i) => i.ingredient.category == 'Manual')
                              .map((selected) => ListTile(
                                    title: Text(selected.ingredient.name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '${selected.quantity}${selected.ingredient.servingUnit}'),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: theme.brightness == Brightness.light 
                                                    ? Colors.grey[300]
                                                    : myGrey80,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Cal: ${selected.nutrients['calories']?.round() ?? 0}',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: theme.textTheme.bodySmall?.color,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: theme.brightness == Brightness.light 
                                                    ? Colors.grey[300]
                                                    : myGrey80,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'P: ${selected.nutrients['carbs']?.round() ?? 0}g',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: theme.textTheme.bodySmall?.color,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: theme.brightness == Brightness.light 
                                                    ? Colors.grey[300]
                                                    : myGrey80,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'C: ${selected.nutrients['carbs']?.round() ?? 0}g',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: theme.textTheme.bodySmall?.color,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: theme.brightness == Brightness.light 
                                                    ? Colors.grey[300]
                                                    : myGrey80,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'F: ${selected.nutrients['fats']?.round() ?? 0}g',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: theme.textTheme.bodySmall?.color,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      iconSize: 20,
                                      color: Colors.red,
                                      onPressed: () {
                                        setState(() {
                                          tempSelected.remove(selected);
                                        });
                                      },
                                    ),
                                  )),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom action buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onSave(tempSelected);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myBlue60,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  void _loadMoreIngredients() async {
    final allCategoryIngredients = IngredientsData.getIngredientsBySpecificCategory(context, _selectedSpecificCategory);
    
    final startIndex = _displayedIngredients.length;
    final endIndex = min(startIndex + _pageSize, allCategoryIngredients.length);
    
    if (startIndex < allCategoryIngredients.length) {
      _displayedIngredients.addAll(allCategoryIngredients.sublist(startIndex, endIndex));
    }
  }
}
