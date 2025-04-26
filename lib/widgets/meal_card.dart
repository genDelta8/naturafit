import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomMealCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  final String weightUnit;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const CustomMealCard({
    Key? key,
    required this.meal,
    required this.weightUnit,
    required this.isExpanded,
    required this.onToggleExpand,
  }) : super(key: key);

  String _convertQuantity(double quantity, String unit, String weightUnit) {
    final isFromOzToG = weightUnit == 'kg' && unit == 'oz';
    if (isFromOzToG) {
      return (((quantity * 28.3495)/25).round() * 25).toStringAsFixed(1);
    }
    final isFromGToOz = weightUnit == 'lbs' && unit == 'g';
    if (isFromGToOz) {
      return (((quantity / 28.3495) * 2).round() / 2).toStringAsFixed(1);
    }
    return quantity.toString();
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.breakfast_dining;
      case 'Morning Snack':
        return Icons.apple;
      case 'Lunch':
        return Icons.lunch_dining;
      case 'Afternoon Snack':
        return Icons.cookie;
      case 'Dinner':
        return Icons.dinner_dining;
      case 'Evening Snack':
        return Icons.night_shelter;
      default:
        return Icons.restaurant;
    }
  }

  String getLocalizedMealType(String mealType, AppLocalizations l10n) {
    if (mealType == 'Breakfast') {
      return l10n.breakfast;
    }
    if (mealType == 'Morning Snack') {
      return l10n.morning_snack;
    }
    if (mealType == 'Lunch') {
      return l10n.lunch;
    }
    if (mealType == 'Afternoon Snack') {
      return l10n.afternoon_snack;
    }
    if (mealType == 'Dinner') {
      return l10n.dinner;
    }
    if (mealType == 'Evening Snack') {
      return l10n.evening_snack;
    }
    return l10n.meal;
  }
  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasIngredients = meal['ingredientDetails']?.isNotEmpty ?? false;
    final hasPreparation = meal['preparation']?.isNotEmpty ?? false;
    final hasExpandableContent = hasIngredients || hasPreparation;
    final l10n = AppLocalizations.of(context)!;
    final localizedMealType = getLocalizedMealType(meal['mealType'], l10n);
    
    return Card(
      color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: hasExpandableContent ? onToggleExpand : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row with icon, meal info, and chevron
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - App Icon and meal info
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // App Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light 
                                ? myBlue60.withOpacity(0.15)
                                : Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getMealTypeIcon(meal['mealType']),
                            color: myBlue70,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Meal type and name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizedMealType,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: theme.brightness == Brightness.light 
                                      ? Colors.grey[600] 
                                      : Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                meal['name'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: theme.brightness == Brightness.light 
                                      ? Colors.black 
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chevron icon on the right
                  if (hasExpandableContent)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: theme.brightness == Brightness.light 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                ],
              ),
              // Nutrition facts row
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildNutrientPill(
                    '${meal['calories']} kcal',
                    theme,
                  ),
                  const SizedBox(width: 6),
                  _buildNutrientPill(
                    '${meal['protein']}g protein',
                    theme,
                  ),
                  const SizedBox(width: 6),
                  _buildNutrientPill(
                    '${meal['carbs']}g carbs',
                    theme,
                  ),
                  const SizedBox(width: 6),
                  _buildNutrientPill(
                    '${meal['fats']}g fats',
                    theme,
                  ),
                ],
              ),
              // Expanded content
              if (isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                if (meal['servingSize']?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${l10n.serving_size_meal_card}: ${meal['servingSize']}',
                    style: GoogleFonts.plusJakartaSans(
                      color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ],
                if (hasIngredients) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.ingredients,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...((meal['ingredientDetails'] as List<dynamic>?) ?? []).map((ingredient) {
                    final quantity = ingredient['quantity']?.toString() ?? '';
                    final unit = ingredient['servingUnit'] ?? '';
                    final name = ingredient['name'] ?? '';
                    final nutrients = ingredient['nutrients'] as Map<String, dynamic>? ?? {};
                    
                    final isFromOzToG = weightUnit == 'kg' && unit == 'oz';
                    final isFromGToOz = weightUnit == 'lbs' && unit == 'g';
                    final shouldConvertQuantity = isFromOzToG || isFromGToOz;
                    
                    final processedQuantity = shouldConvertQuantity
                        ? _convertQuantity(double.parse(quantity), unit, weightUnit)
                        : quantity;
                        
                    final processedUnit = shouldConvertQuantity 
                        ? (isFromOzToG ? 'g' : 'oz') 
                        : unit;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Colors.grey)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$name $processedQuantity $processedUnit',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (nutrients.isNotEmpty)
                                  Text(
                                    '(${nutrients['calories']?.toStringAsFixed(0) ?? 0} kcal | '
                                    'P: ${nutrients['protein']?.toStringAsFixed(1) ?? 0}g '
                                    'C: ${nutrients['carbs']?.toStringAsFixed(1) ?? 0}g '
                                    'F: ${nutrients['fats']?.toStringAsFixed(1) ?? 0}g)',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                if (hasPreparation) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${l10n.preparation}:',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal['preparation'],
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientPill(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light 
            ? myGrey20 
            : Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: theme.brightness == Brightness.light 
              ? Colors.grey[700] 
              : Colors.grey[300],
        ),
      ),
    );
  }
} 