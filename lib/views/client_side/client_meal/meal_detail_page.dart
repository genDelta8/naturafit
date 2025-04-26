import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MealDetailPage extends StatelessWidget {
  final Map<String, dynamic> meal;

  const MealDetailPage({super.key, required this.meal});

  Widget _buildNutritionCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            l10n.nutrition_facts,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutritionItem('Calories', '${meal['calories']} kcal', myYellow50, context),
              _buildNutritionItem('Protein', '${meal['protein']}g', myBlue60, context),
              _buildNutritionItem('Carbs', '${meal['carbs']}g', myTeal50, context),
              _buildNutritionItem('Fats', '${meal['fats']}g', myPurple50, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<dynamic> ingredients = meal['ingredientDetails'] ?? [];
    if (ingredients.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              Icon(Icons.shopping_basket_outlined, color: myBlue60),
              const SizedBox(width: 8),
              Text(
                l10n.ingredients,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...ingredients.map((ingredient) => _buildIngredientItem(ingredient)),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(Map<String, dynamic> ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ingredient['name'] ?? '',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${ingredient['quantity']} ${ingredient['unit']}',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (ingredient['nutrients'] != null) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildNutrientTag('Calories', '${ingredient['nutrients']['calories']}kcal', myYellow50),
                  const SizedBox(width: 8),
                  _buildNutrientTag('Protein', '${ingredient['nutrients']['protein']}g', myBlue60),
                  const SizedBox(width: 8),
                  _buildNutrientTag('Carbs', '${ingredient['nutrients']['carbs']}g', myTeal50),
                  const SizedBox(width: 8),
                  _buildNutrientTag('Fats', '${ingredient['nutrients']['fats']}g', myPurple50),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutrientTag(String text, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (meal['preparation']?.isEmpty ?? true) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              Icon(Icons.menu_book_outlined, color: myBlue60),
              const SizedBox(width: 8),
              Text(
                l10n.instructions,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            meal['preparation'],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (meal['notes']?.isEmpty ?? true) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              Icon(Icons.sticky_note_2_outlined, color: myBlue60),
              const SizedBox(width: 8),
              Text(
                l10n.notes,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            meal['notes'],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String value, String label, Color color, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: myGrey10,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chevron_left, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          meal['name'] ?? l10n.meal_details,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: myGrey10,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNutritionCard(context),
            const SizedBox(height: 16),
            if (meal['servingSize']?.isNotEmpty == true) ...[
              Text(
                l10n.serving_size(meal['servingSize']!),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildIngredientsCard(context),
            const SizedBox(height: 16),
            _buildInstructionsCard(context),
            const SizedBox(height: 16),
            _buildNotesCard(context),
          ],
        ),
      ),
    );
  }
} 