import 'package:flutter/material.dart';

// Recipe Ingredient Model
class RecipeIngredient {
  final String id; // Can be custom food ID, USDA ID, or OFF barcode
  final String name;
  final String source; // 'custom', 'usda', 'openfoodfacts'
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final double saturatedFat;

  RecipeIngredient({
    required this.id,
    required this.name,
    required this.source,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.saturatedFat,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'source': source,
      'quantity': quantity,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'saturatedFat': saturatedFat,
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      id: map['id'],
      name: map['name'],
      source: map['source'],
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'g',
      calories: (map['calories'] ?? 0).toDouble(),
      protein: (map['protein'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      fat: (map['fat'] ?? 0).toDouble(),
      fiber: (map['fiber'] ?? 0).toDouble(),
      sugar: (map['sugar'] ?? 0).toDouble(),
      sodium: (map['sodium'] ?? 0).toDouble(),
      saturatedFat: (map['saturatedFat'] ?? 0).toDouble(),
    );
  }
}

// Custom Recipe Model
class CustomRecipe {
  final String id;
  final String name;
  final String? description;
  final List<RecipeIngredient> ingredients;
  final double servings;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime? lastModified;

  CustomRecipe({
    required this.id,
    required this.name,
    this.description,
    required this.ingredients,
    required this.servings,
    this.imagePath,
    required this.createdAt,
    this.lastModified,
  });

  // Calculate total nutrition for entire recipe
  Map<String, double> get totalNutrition {
    return {
      'calories': ingredients.fold(0.0, (sum, ing) => sum + ing.calories),
      'protein': ingredients.fold(0.0, (sum, ing) => sum + ing.protein),
      'carbs': ingredients.fold(0.0, (sum, ing) => sum + ing.carbs),
      'fat': ingredients.fold(0.0, (sum, ing) => sum + ing.fat),
      'fiber': ingredients.fold(0.0, (sum, ing) => sum + ing.fiber),
      'sugar': ingredients.fold(0.0, (sum, ing) => sum + ing.sugar),
      'sodium': ingredients.fold(0.0, (sum, ing) => sum + ing.sodium),
      'saturatedFat': ingredients.fold(0.0, (sum, ing) => sum + ing.saturatedFat),
    };
  }

  // Calculate nutrition per serving
  Map<String, double> get nutritionPerServing {
    final total = totalNutrition;
    return total.map((key, value) => MapEntry(key, value / servings));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'servings': servings,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory CustomRecipe.fromMap(Map<String, dynamic> map) {
    return CustomRecipe(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      ingredients: (map['ingredients'] as List)
          .map((i) => RecipeIngredient.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      servings: (map['servings'] ?? 1).toDouble(),
      imagePath: map['imagePath'],
      createdAt: DateTime.parse(map['createdAt']),
      lastModified: map['lastModified'] != null
          ? DateTime.parse(map['lastModified'])
          : null,
    );
  }

  // Create a copy with updated fields
  CustomRecipe copyWith({
    String? name,
    String? description,
    List<RecipeIngredient>? ingredients,
    double? servings,
    String? imagePath,
    DateTime? lastModified,
  }) {
    return CustomRecipe(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      servings: servings ?? this.servings,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt,
      lastModified: lastModified ?? DateTime.now(),
    );
  }
}
