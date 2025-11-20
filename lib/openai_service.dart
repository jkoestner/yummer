import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_helper.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static String? _apiKey;

  // Initialize by loading API key from storage
  static Future<void> init() async {
    _apiKey = await StorageHelper.instance.getOpenAIApiKey();
  }

  static void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  static Future<String?> getApiKey() async {
    if (_apiKey == null) {
      _apiKey = await StorageHelper.instance.getOpenAIApiKey();
    }
    return _apiKey;
  }

  /// Estimate nutrition information for a custom food using OpenAI
  static Future<Map<String, dynamic>?> estimateFoodNutrition(
      String foodQuery) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
          'OpenAI API key not configured. Please add it in settings.');
    }

    try {
      final prompt = '''If cannot find information from this search "$foodQuery", then approximate the nutritional information. The output should be in the following format:
food, calories: <calories>, protein: <protein>, carbs: <carbs>, fat: <fat>, fiber: <fiber>, sugar: <sugar>

Important:
- Provide only the formatted output, no additional text
- Use numeric values only (no units)
- Values should be per 1 serving (interpret the food query as 1 serving)
- If you cannot find exact information, provide reasonable approximations based on similar foods''';

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: json.encode({
              'model': 'gpt-3.5-turbo',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a nutrition expert that provides accurate nutritional information for foods.'
                },
                {'role': 'user', 'content': prompt}
              ],
              'temperature': 0.3,
              'max_tokens': 150,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Parse the response
        return _parseNutritionResponse(content, foodQuery);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
        throw Exception('OpenAI API error: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      throw Exception('Error estimating food nutrition: $e');
    }
  }

  /// Parse the OpenAI response to extract nutrition data
  static Map<String, dynamic>? _parseNutritionResponse(
      String response, String originalQuery) {
    try {
      // Expected format: food, calories: X, protein: Y, carbs: Z, fat: A, fiber: B, sugar: C
      final lines = response.trim().split('\n');
      String nutritionLine = '';

      // Find the line with the nutrition data
      for (var line in lines) {
        if (line.contains('calories:') && line.contains('protein:')) {
          nutritionLine = line;
          break;
        }
      }

      if (nutritionLine.isEmpty) {
        nutritionLine = lines.first;
      }

      // Extract food name (everything before first comma or "calories:")
      String foodName = originalQuery;
      final firstCommaIndex = nutritionLine.indexOf(',');
      if (firstCommaIndex > 0) {
        final extractedName = nutritionLine.substring(0, firstCommaIndex).trim();
        if (extractedName.isNotEmpty && !extractedName.contains(':')) {
          foodName = extractedName;
        }
      }

      // Extract numeric values using regex
      double extractValue(String key) {
        final pattern = RegExp('$key:\\s*(\\d+\\.?\\d*)');
        final match = pattern.firstMatch(nutritionLine);
        if (match != null) {
          return double.tryParse(match.group(1) ?? '0') ?? 0.0;
        }
        return 0.0;
      }

      final calories = extractValue('calories');
      final protein = extractValue('protein');
      final carbs = extractValue('carbs');
      final fat = extractValue('fat');
      final fiber = extractValue('fiber');
      final sugar = extractValue('sugar');

      // Validate that we got at least some values
      if (calories == 0 && protein == 0 && carbs == 0 && fat == 0) {
        throw Exception('Could not parse nutrition values from response');
      }

      return {
        'name': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sugar': sugar,
        'servingSize': 1.0,
        'servingUnit': 'serving',
        'sodium': 0.0, // Not included in basic prompt, can be extended
        'saturatedFat': 0.0, // Not included in basic prompt, can be extended
        'source': 'OpenAI',
      };
    } catch (e) {
      print('Error parsing OpenAI response: $e');
      print('Response was: $response');
      return null;
    }
  }
}
