import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

// Helper function to safely get nutrient value
double getNutrientValue(Nutriments? nutriments, String nutrientType) {
  if (nutriments == null) return 0.0;

  final nutrient = Nutrient.fromOffTag(nutrientType);
  if (nutrient == null) return 0.0;

  final value = nutriments.getValue(nutrient, PerSize.oneHundredGrams);
  return value ?? 0.0;
}

// Meal Type Enum
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snacks';
    }
  }

  IconData get icon {
    switch (this) {
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.cookie;
    }
  }

  Color get color {
    switch (this) {
      case MealType.breakfast:
        return Colors.orange;
      case MealType.lunch:
        return Colors.blue;
      case MealType.dinner:
        return Colors.purple;
      case MealType.snack:
        return Colors.pink;
    }
  }
}

// Food Entry Model
class FoodEntry {
  final String id;
  final String name;
  final String? barcode;
  final double servingSize;
  final String servingUnit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final double saturatedFat;
  final double? vitaminC;
  final double? calcium;
  final double? iron;
  final double? potassium;
  final String? photoUrl;
  final MealType mealType;
  final DateTime timestamp;
  final String? recipeUrl;

  FoodEntry({
    required this.id,
    required this.name,
    this.barcode,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.saturatedFat,
    this.vitaminC,
    this.calcium,
    this.iron,
    this.potassium,
    this.photoUrl,
    required this.mealType,
    required this.timestamp,
    this.recipeUrl,
  });

  factory FoodEntry.fromOpenFoodFacts(
    Product product,
    DateTime timestamp,
    double servings,
    MealType mealType,
  ) {
    final nutriments = product.nutriments;

    return FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: product.productName ?? 'Unknown Product',
      barcode: product.barcode,
      servingSize: 100 * servings,
      servingUnit: 'g',
      calories: getNutrientValue(nutriments, 'energy-kcal') * servings,
      protein: getNutrientValue(nutriments, 'proteins') * servings,
      carbs: getNutrientValue(nutriments, 'carbohydrates') * servings,
      fat: getNutrientValue(nutriments, 'fat') * servings,
      fiber: getNutrientValue(nutriments, 'fiber') * servings,
      sugar: getNutrientValue(nutriments, 'sugars') * servings,
      sodium: getNutrientValue(nutriments, 'sodium') * servings * 1000,
      saturatedFat: getNutrientValue(nutriments, 'saturated-fat') * servings,
      vitaminC: getNutrientValue(nutriments, 'vitamin-c') * servings,
      calcium: getNutrientValue(nutriments, 'calcium') * servings,
      iron: getNutrientValue(nutriments, 'iron') * servings,
      potassium: getNutrientValue(nutriments, 'potassium') * servings,
      photoUrl: product.imageFrontUrl,
      mealType: mealType,
      timestamp: timestamp,
    );
  }

  factory FoodEntry.fromMealieRecipe(
    Map<String, dynamic> recipe,
    DateTime timestamp,
    double servings,
    MealType mealType,
  ) {
    final nutrition = recipe['nutrition'] as Map<String, dynamic>?;
    final baseServings = recipe['recipeServings'] ?? 1.0;
    final multiplier = servings;

    return FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: recipe['name'] ?? 'Unknown Recipe',
      servingSize: servings,
      servingUnit: 'serving',
      calories:
          (double.tryParse(nutrition?['calories']?.toString() ?? '0') ?? 0) *
          multiplier,
      protein:
          (double.tryParse(nutrition?['proteinContent']?.toString() ?? '0') ??
              0) *
          multiplier,
      carbs:
          (double.tryParse(
                nutrition?['carbohydrateContent']?.toString() ?? '0',
              ) ??
              0) *
          multiplier,
      fat:
          (double.tryParse(nutrition?['fatContent']?.toString() ?? '0') ?? 0) *
          multiplier,
      fiber:
          (double.tryParse(nutrition?['fiberContent']?.toString() ?? '0') ??
              0) *
          multiplier,
      sugar:
          (double.tryParse(nutrition?['sugarContent']?.toString() ?? '0') ??
              0) *
          multiplier,
      sodium:
          (double.tryParse(nutrition?['sodiumContent']?.toString() ?? '0') ??
              0) *
          multiplier,
      saturatedFat:
          (double.tryParse(
                nutrition?['saturatedFatContent']?.toString() ?? '0',
              ) ??
              0) *
          multiplier,
      photoUrl: recipe['imageUrl'], // Use the pre-constructed URL
      mealType: mealType,
      timestamp: timestamp,
      recipeUrl: recipe['slug'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'saturatedFat': saturatedFat,
      'vitaminC': vitaminC,
      'calcium': calcium,
      'iron': iron,
      'potassium': potassium,
      'photoUrl': photoUrl,
      'mealType': mealType.name,
      'timestamp': timestamp.toIso8601String(),
      'recipeUrl': recipeUrl,
    };
  }

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      servingSize: (map['servingSize'] ?? 0).toDouble(),
      servingUnit: map['servingUnit'] ?? 'g',
      calories: (map['calories'] ?? 0).toDouble(),
      protein: (map['protein'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      fat: (map['fat'] ?? 0).toDouble(),
      fiber: (map['fiber'] ?? 0).toDouble(),
      sugar: (map['sugar'] ?? 0).toDouble(),
      sodium: (map['sodium'] ?? 0).toDouble(),
      saturatedFat: (map['saturatedFat'] ?? 0).toDouble(),
      vitaminC: map['vitaminC']?.toDouble(),
      calcium: map['calcium']?.toDouble(),
      iron: map['iron']?.toDouble(),
      potassium: map['potassium']?.toDouble(),
      photoUrl: map['photoUrl'],
      mealType: MealType.values.firstWhere((e) => e.name == map['mealType']),
      timestamp: DateTime.parse(map['timestamp']),
      recipeUrl: map['recipeUrl'],
    );
  }
}

// Daily Goals Model
class DailyGoals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  DailyGoals({
    this.calories = 2000,
    this.protein = 150,
    this.carbs = 250,
    this.fat = 65,
    this.fiber = 30,
  });

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
    };
  }

  factory DailyGoals.fromMap(Map<String, dynamic> map) {
    return DailyGoals(
      calories: (map['calories'] ?? 2000).toDouble(),
      protein: (map['protein'] ?? 150).toDouble(),
      carbs: (map['carbs'] ?? 250).toDouble(),
      fat: (map['fat'] ?? 65).toDouble(),
      fiber: (map['fiber'] ?? 30).toDouble(),
    );
  }
}
