import 'package:http/http.dart' as http;
import 'dart:convert';

import 'storage_helper.dart';

class USDAService {
  // USDA FoodData Central API
  // Get your free API key at: https://fdc.nal.usda.gov/api-key-signup.html
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  static String? _apiKey;

  // Initialize by loading API key from storage
  static Future<void> init() async {
    _apiKey = await StorageHelper.instance.getUSDAApiKey();
  }

  static void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  static Future<String?> getApiKey() async {
    if (_apiKey == null) {
      _apiKey = await StorageHelper.instance.getUSDAApiKey();
    }
    return _apiKey;
  }

  // Search foods in USDA database
  static Future<List<Map<String, dynamic>>> searchFoods(String query) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
          'USDA API key not configured. Please add it in settings.');
    }

    try {
      // Build query parameters
      final uri = Uri.parse('$_baseUrl/foods/search').replace(
        queryParameters: {
          'query': query,
          'pageSize': '20',
          'api_key': _apiKey,
        },
      );

      final response = await http.get(uri).timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foods = data['foods'] as List? ?? [];

        return foods.map((food) {
          return {
            'fdcId': food['fdcId'].toString(),
            'description': food['description'] ?? 'Unknown Food',
            'brandOwner': food['brandOwner'],
            'dataType': food['dataType'],
            'ingredients': food['ingredients'],
          };
        }).toList();
      } else {
        throw Exception(
            'USDA API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error searching USDA foods: $e');
    }
  }

  // Get detailed nutrition for a specific food
  static Future<Map<String, dynamic>?> getFoodDetails(String fdcId) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('USDA API key not configured');
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/food/$fdcId?api_key=$_apiKey'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract nutrition data - USDA provides per 100g
        final nutrients = data['foodNutrients'] as List? ?? [];

        // Extract food portions (serving size options)
        final foodPortions = data['foodPortions'] as List? ?? [];

        // Map nutrient IDs to our needs
        // 1008 = Energy (kcal)
        // 1003 = Protein
        // 1005 = Carbohydrate
        // 1004 = Total lipid (fat)
        // 1079 = Fiber
        // 2000 = Sugars
        // 1093 = Sodium
        // 1258 = Saturated fatty acids

        double getNutrient(int nutrientId) {
          try {
            final nutrient = nutrients.firstWhere(
              (n) => n['nutrient']?['id'] == nutrientId,
              orElse: () => {},
            );
            return (nutrient['amount'] ?? 0).toDouble();
          } catch (e) {
            return 0.0;
          }
        }

        // Get per 100g nutrition values (USDA default)
        final caloriePer100g = getNutrient(1008);
        final proteinPer100g = getNutrient(1003);
        final carbsPer100g = getNutrient(1005);
        final fatPer100g = getNutrient(1004);
        final fiberPer100g = getNutrient(1079);
        final sugarPer100g = getNutrient(2000);
        final sodiumPer100g = getNutrient(1093) * 1000; // Convert g to mg
        final saturatedFatPer100g = getNutrient(1258);

        // Process food portions into serving options
        List<Map<String, dynamic>> servingOptions = [];

        // Always include 100g as the first option
        servingOptions.add({
          'amount': 100.0,
          'unit': 'g',
          'description': '100g',
          'gramWeight': 100.0,
        });

        // Add serving options from USDA
        for (var portion in foodPortions) {
          final amount = (portion['amount'] ?? 1).toDouble();
          final gramWeight = (portion['gramWeight'] ?? 0).toDouble();
          final modifier = portion['modifier'] ?? '';
          final portionDescription = portion['portionDescription'] ?? '';

          if (gramWeight > 0) {
            String description;
            if (modifier.isNotEmpty) {
              description =
                  '$modifier ${amount.toStringAsFixed(0)} $portionDescription';
            } else {
              description = '${amount.toStringAsFixed(0)} $portionDescription';
            }

            // Clean up the description
            description = description.trim();
            if (description.isEmpty) {
              description = '${gramWeight.toStringAsFixed(0)}g serving';
            }

            servingOptions.add({
              'amount': amount,
              'unit': portionDescription,
              'description': description,
              'gramWeight': gramWeight,
            });
          }
        }

        // Use first serving option as default
        final defaultServing = servingOptions.first;
        final defaultGramWeight = defaultServing['gramWeight'] as double;
        final multiplier = defaultGramWeight / 100.0;

        return {
          'fdcId': data['fdcId'].toString(),
          'description': data['description'] ?? 'Unknown Food',
          'brandOwner': data['brandOwner'],
          'servingOptions': servingOptions,
          'defaultServingSize': defaultGramWeight,
          'defaultServingUnit': 'g',
          'defaultServingDescription': defaultServing['description'],
          // Nutrition for default serving
          'calories': caloriePer100g * multiplier,
          'protein': proteinPer100g * multiplier,
          'carbs': carbsPer100g * multiplier,
          'fat': fatPer100g * multiplier,
          'fiber': fiberPer100g * multiplier,
          'sugar': sugarPer100g * multiplier,
          'sodium': sodiumPer100g * multiplier,
          'saturatedFat': saturatedFatPer100g * multiplier,
          // Keep per 100g values for recalculation
          'caloriePer100g': caloriePer100g,
          'proteinPer100g': proteinPer100g,
          'carbsPer100g': carbsPer100g,
          'fatPer100g': fatPer100g,
          'fiberPer100g': fiberPer100g,
          'sugarPer100g': sugarPer100g,
          'sodiumPer100g': sodiumPer100g,
          'saturatedFatPer100g': saturatedFatPer100g,
        };
      } else {
        throw Exception('Failed to load food details');
      }
    } catch (e) {
      print('Error fetching USDA food details: $e');
      return null;
    }
  }
}
