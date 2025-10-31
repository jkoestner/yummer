import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'dart:convert';

class MealieService {
  static Box get _configBox => Hive.box('daily_goals'); // Reuse existing box

  static Future<String?> getMealieUrl() async {
    return _configBox.get('mealie_url');
  }

  static Future<String?> getMealieToken() async {
    return _configBox.get('mealie_token');
  }

  static Future<void> saveMealieConfig(String url, String token) async {
    await _configBox.put('mealie_url', url);
    await _configBox.put('mealie_token', token);
  }

  static Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    final url = await getMealieUrl();
    final token = await getMealieToken();

    if (url == null || token == null || url.isEmpty || token.isEmpty) {
      throw Exception(
        'Mealie not configured. Please set URL and API token in settings.',
      );
    }

    try {
      final response = await http
          .get(
            Uri.parse('$url/api/recipes?search=$query&perPage=20'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

        // Add full image URL to each recipe
        for (var recipe in items) {
          final recipeId = recipe['id'];
          if (recipeId != null) {
            recipe['imageUrl'] =
                '$url/api/media/recipes/$recipeId/images/min-original.webp';
          }
        }

        return items;
      } else {
        throw Exception('Failed to search recipes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to Mealie: $e');
    }
  }

  static Future<Map<String, dynamic>?> getRecipeDetails(String slug) async {
    final url = await getMealieUrl();
    final token = await getMealieToken();

    if (url == null || token == null) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$url/api/recipes/$slug'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final recipe = json.decode(response.body) as Map<String, dynamic>;

        // Add full image URL to the recipe details too
        final recipeId = recipe['id'];
        if (recipeId != null) {
          recipe['imageUrl'] =
              '$url/api/media/recipes/$recipeId/images/min-original.webp';
        }

        return recipe;
      }
      return null;
    } catch (e) {
      print('Error fetching recipe details: $e');
      return null;
    }
  }
}
