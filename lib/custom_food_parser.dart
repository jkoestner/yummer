// Helper class to parse nutrition label text from OCR
class NutritionLabelParser {
  static Map<String, double> parseNutritionText(String text) {
    final result = <String, double>{
      'calories': 0.0,
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
      'fiber': 0.0,
      'sugar': 0.0,
      'sodium': 0.0,
      'saturatedFat': 0.0,
      'servingSize': 0.0,
    };

    // Clean up text: normalize whitespace and convert to lowercase
    final cleanText = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    // Extract serving size
    final servingSizePatterns = [
      RegExp(r'serving\s+size[:\s]+(\d+\.?\d*)\s*g'),
      RegExp(r'serving[:\s]+(\d+\.?\d*)\s*g'),
      RegExp(r'(\d+\.?\d*)\s*g\s+per\s+serving'),
    ];
    for (var pattern in servingSizePatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        result['servingSize'] = double.tryParse(match.group(1)!) ?? 0.0;
        break;
      }
    }

    // Extract calories
    final caloriesPatterns = [
      RegExp(r'calories[:\s]+(\d+\.?\d*)'),
      RegExp(r'energy[:\s]+(\d+\.?\d*)\s*kcal'),
      RegExp(r'(\d+\.?\d*)\s*kcal'),
    ];
    for (var pattern in caloriesPatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        result['calories'] = double.tryParse(match.group(1)!) ?? 0.0;
        break;
      }
    }

    // Extract protein
    final proteinPatterns = [
      RegExp(r'protein[:\s]+(\d+\.?\d*)\s*g'),
      RegExp(r'proteins[:\s]+(\d+\.?\d*)\s*g'),
    ];
    for (var pattern in proteinPatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        result['protein'] = double.tryParse(match.group(1)!) ?? 0.0;
        break;
      }
    }

    // Extract carbohydrates
    final carbsPatterns = [
      RegExp(r'total\s+carbohydrate[s]?[:\s]+(\d+\.?\d*)\s*g'),
      RegExp(r'carbohydrate[s]?[:\s]+(\d+\.?\d*)\s*g'),
      RegExp(r'carbs[:\s]+(\d+\.?\d*)\s*g'),
    ];
    for (var pattern in carbsPatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        result['carbs'] = double.tryParse(match.group(1)!) ?? 0.0;
        break;
      }
    }

    // Extract total fat
    final fatPatterns = [
      RegExp(r'total\s+fat[:\s]+(\d+\.?\d*)\s*g'),
      RegExp(r'fat[:\s]+(\d+\.?\d*)\s*g'),
    ];
    for (var pattern in fatPatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        result['fat'] = double.tryParse(match.group(1)!) ?? 0.0;
        break;
      }
    }

    // Extract saturated fat
    final saturatedFatPatterns = [
      RegExp(r'saturated\s+fat[:\s]+(\d+\.?\d*)\s*g'),
      RegExp(r'saturated[:\s]+(\d+\.?\d*)\s*g'),
    ];
    for (var pattern in saturatedFatPatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        result['saturatedFat'] = double.tryParse(match.group(1)!) ?? 0.0;
        break;
      }
    }

    // Extract fiber
    final fiberPatterns = [
      RegExp(r'dietary\s+fiber[:\s]+(\d+\.?\d*)\s*g'),
      RegExp(r'fiber[:\s]+(\d+\.?\d*)\s*g'),
      RegExp(r'fibre[:\s]+(\d+\.?\d*)\s*g'),
    ];
    for (var pattern in fiberPatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        result['fiber'] = double.tryParse(match.group(1)!) ?? 0.0;
        break;
      }
    }

    // Extract sugar
    final sugarPatterns = [
      RegExp(r'total\s+sugars?[:\s]+(\d+\.?\d*)\s*g'),
      RegExp(r'sugars?[:\s]+(\d+\.?\d*)\s*g'),
    ];
    for (var pattern in sugarPatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        result['sugar'] = double.tryParse(match.group(1)!) ?? 0.0;
        break;
      }
    }

    // Extract sodium (can be in mg or g)
    final sodiumPatterns = [
      RegExp(r'sodium[:\s]+(\d+\.?\d*)\s*mg'),
      RegExp(r'sodium[:\s]+(\d+\.?\d*)\s*g'),
    ];
    for (var pattern in sodiumPatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        final value = double.tryParse(match.group(1)!) ?? 0.0;
        // If in grams, convert to mg
        result['sodium'] = cleanText.contains('${match.group(1)} g') 
            ? value * 1000 
            : value;
        break;
      }
    }

    return result;
  }

  // Extract product name from text
  static String? extractProductName(String text) {
    // Try to find product name - usually at the top of the label
    final lines = text.split('\n');
    
    // Look for lines that might be product names (not nutrition facts)
    for (var line in lines.take(5)) {
      final cleanLine = line.trim();
      
      // Skip lines that look like nutrition facts
      if (cleanLine.toLowerCase().contains('nutrition') ||
          cleanLine.toLowerCase().contains('facts') ||
          cleanLine.toLowerCase().contains('serving') ||
          RegExp(r'\d+\s*(g|mg|kcal|calories)').hasMatch(cleanLine.toLowerCase())) {
        continue;
      }
      
      // If line has reasonable length and some text, use it
      if (cleanLine.length > 3 && cleanLine.length < 50) {
        return cleanLine;
      }
    }
    
    return null;
  }
}
