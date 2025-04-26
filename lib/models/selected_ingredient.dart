
import 'package:naturafit/utilities/ingredients_data.dart';

class SelectedIngredient {
  final Ingredient ingredient;
  final double quantity;

  SelectedIngredient({
    required this.ingredient,
    required this.quantity,
  });

  Map<String, double> get nutrients {
    return ingredient.calculateNutrients(quantity);
  }
} 