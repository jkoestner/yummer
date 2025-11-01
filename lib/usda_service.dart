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

        // Extract nutrition data
        final nutrients = data['foodNutrients'] as List? ?? [];

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

        return {
          'fdcId': data['fdcId'].toString(),
          'description': data['description'] ?? 'Unknown Food',
          'brandOwner': data['brandOwner'],
          'servingSize': (data['servingSize'] ?? 100).toDouble(),
          'servingSizeUnit': data['servingSizeUnit'] ?? 'g',
          'calories': getNutrient(1008),
          'protein': getNutrient(1003),
          'carbs': getNutrient(1005),
          'fat': getNutrient(1004),
          'fiber': getNutrient(1079),
          'sugar': getNutrient(2000),
          'sodium': getNutrient(1093) * 1000, // Convert g to mg
          'saturatedFat': getNutrient(1258),
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
