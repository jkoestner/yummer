import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// Custom Food Model
class CustomFood {
  final String id;
  final String name;
  final String? brand;
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
  final String? imagePath; // Optional: store path to scanned image
  final DateTime createdAt;

  CustomFood({
    required this.id,
    required this.name,
    this.brand,
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
    this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
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
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomFood.fromMap(Map<String, dynamic> map) {
    return CustomFood(
      id: map['id'],
      name: map['name'],
      brand: map['brand'],
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
      imagePath: map['imagePath'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

// Custom Foods Storage Manager
class CustomFoodsManager {
  static final CustomFoodsManager instance = CustomFoodsManager._init();
  CustomFoodsManager._init();

  static const String _boxName = 'custom_foods';
  
  // Ensure box is opened
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  Box get _box => Hive.box(_boxName);

  // Save a custom food
  Future<void> saveCustomFood(CustomFood food) async {
    await _box.put(food.id, food.toMap());
    print('Custom food saved: ${food.name}');
  }

  // Get all custom foods
  Future<List<CustomFood>> getAllCustomFoods() async {
    try {
      final foods = _box.values
          .map((e) => CustomFood.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      
      // Sort by most recently created
      foods.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return foods;
    } catch (e) {
      print('Error loading custom foods: $e');
      return [];
    }
  }

  // Search custom foods by name
  Future<List<CustomFood>> searchCustomFoods(String query) async {
    final allFoods = await getAllCustomFoods();
    if (query.isEmpty) return allFoods;

    final lowerQuery = query.toLowerCase();
    return allFoods.where((food) {
      return food.name.toLowerCase().contains(lowerQuery) ||
          (food.brand?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Delete a custom food
  Future<void> deleteCustomFood(String id) async {
    await _box.delete(id);
    print('Custom food deleted: $id');
  }

  // Update a custom food
  Future<void> updateCustomFood(CustomFood food) async {
    await _box.put(food.id, food.toMap());
    print('Custom food updated: ${food.name}');
  }
}
