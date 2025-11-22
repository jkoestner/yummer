// Helper class to store extracted text elements with context
class _TextElement {
  final String text;
  final int position;
  final String? unit;
  final double? numericValue;

  _TextElement({
    required this.text,
    required this.position,
    this.unit,
    this.numericValue,
  });
}

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

    // Parse text into structured elements
    final elements = _extractTextElements(text);

    // Try to match each nutrient using context-aware matching
    result['servingSize'] = _extractServingSize(elements, text);
    result['calories'] = _extractCalories(elements, text);
    result['protein'] = _extractNutrient(elements, text, ['protein', 'proteins'], 'g', maxValue: 100);
    result['carbs'] = _extractNutrient(elements, text, ['carbohydrate', 'carbohydrates', 'carbs', 'total carbohydrate'], 'g', maxValue: 200);
    result['fat'] = _extractNutrient(elements, text, ['total fat', 'fat'], 'g', maxValue: 100, excludeKeywords: ['saturated', 'trans']);
    result['saturatedFat'] = _extractNutrient(elements, text, ['saturated fat', 'saturated'], 'g', maxValue: 50);
    result['fiber'] = _extractNutrient(elements, text, ['dietary fiber', 'fiber', 'fibre'], 'g', maxValue: 50);
    result['sugar'] = _extractNutrient(elements, text, ['total sugars', 'sugars', 'sugar'], 'g', maxValue: 150);
    result['sodium'] = _extractSodium(elements, text);

    return result;
  }

  // Extract and structure all text elements with their context
  static List<_TextElement> _extractTextElements(String text) {
    final elements = <_TextElement>[];
    final lines = text.split('\n');
    var position = 0;

    for (var line in lines) {
      // Find all numbers with optional units
      final numberPattern = RegExp(r'(\d+\.?\d*)\s*(g|mg|kcal|cal|%)?', caseSensitive: false);
      final matches = numberPattern.allMatches(line.toLowerCase());

      for (var match in matches) {
        final value = double.tryParse(match.group(1)!);
        if (value != null) {
          elements.add(_TextElement(
            text: line,
            position: position + match.start,
            unit: match.group(2),
            numericValue: value,
          ));
        }
      }
      position += line.length + 1;
    }

    return elements;
  }

  // Extract serving size with better context awareness
  static double _extractServingSize(List<_TextElement> elements, String text) {
    final cleanText = text.toLowerCase();

    // Pattern 1: Standard format "serving size: XXg"
    final patterns = [
      RegExp(r'serving\s+size[:\s-]+(\d+\.?\d*)\s*g', caseSensitive: false),
      RegExp(r'serving[:\s-]+(\d+\.?\d*)\s*g', caseSensitive: false),
      RegExp(r'(\d+\.?\d*)\s*g\s+per\s+serving', caseSensitive: false),
      RegExp(r'portion[:\s-]+(\d+\.?\d*)\s*g', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        final value = double.tryParse(match.group(1)!) ?? 0.0;
        if (value > 0 && value <= 1000) return value;
      }
    }

    // Pattern 2: Look for "serving" keyword near a number with "g" unit
    for (var element in elements) {
      if (element.unit == 'g' && element.text.toLowerCase().contains('serv')) {
        final value = element.numericValue ?? 0.0;
        if (value > 10 && value <= 1000) return value;
      }
    }

    return 0.0;
  }

  // Extract calories with validation
  static double _extractCalories(List<_TextElement> elements, String text) {
    final cleanText = text.toLowerCase();

    // Pattern 1: Direct keyword matching
    final patterns = [
      RegExp(r'calories[:\s-]+(\d+\.?\d*)', caseSensitive: false),
      RegExp(r'energy[:\s-]+(\d+\.?\d*)\s*kcal', caseSensitive: false),
      RegExp(r'(\d+\.?\d*)\s*kcal', caseSensitive: false),
      RegExp(r'(\d+\.?\d*)\s*cal(?!cium)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        final value = double.tryParse(match.group(1)!) ?? 0.0;
        // Validate: calories typically 0-1000 per serving
        if (value >= 0 && value <= 1500) return value;
      }
    }

    // Pattern 2: Look for numbers near "calorie" or "energy" keywords
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.contains('calor') || line.contains('energy')) {
        // Check current line and next line for numbers
        for (var j = i; j <= i + 1 && j < lines.length; j++) {
          final numbers = RegExp(r'(\d+\.?\d*)').allMatches(lines[j]);
          for (var match in numbers) {
            final value = double.tryParse(match.group(1)!) ?? 0.0;
            if (value >= 10 && value <= 1500 && !lines[j].contains('g')) {
              return value;
            }
          }
        }
      }
    }

    return 0.0;
  }

  // Generic nutrient extraction with context awareness
  static double _extractNutrient(
    List<_TextElement> elements,
    String text,
    List<String> keywords,
    String expectedUnit,
    {double maxValue = 100, List<String>? excludeKeywords}
  ) {
    final cleanText = text.toLowerCase();

    // Try each keyword in priority order
    for (var keyword in keywords) {
      // Pattern 1: Direct keyword + value pattern
      final patterns = [
        RegExp('$keyword[:\\s-]+(\\d+\\.?\\d*)\\s*$expectedUnit', caseSensitive: false),
        RegExp('$keyword[:\\s-]+(\\d+\\.?\\d*)', caseSensitive: false),
      ];

      for (var pattern in patterns) {
        final matches = pattern.allMatches(cleanText);
        for (var match in matches) {
          // Check if this match should be excluded
          if (excludeKeywords != null) {
            final matchContext = cleanText.substring(
              match.start > 20 ? match.start - 20 : 0,
              match.end + 20 < cleanText.length ? match.end + 20 : cleanText.length
            );
            if (excludeKeywords.any((exclude) => matchContext.contains(exclude))) {
              continue;
            }
          }

          final value = double.tryParse(match.group(1)!) ?? 0.0;
          if (value >= 0 && value <= maxValue) return value;
        }
      }
    }

    // Pattern 2: Look for keyword on one line, value on nearby line
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      // Check if this line contains any of our keywords
      for (var keyword in keywords) {
        if (line.contains(keyword)) {
          // Check for exclude keywords
          if (excludeKeywords != null && excludeKeywords.any((exclude) => line.contains(exclude))) {
            continue;
          }

          // Look for numbers in current line and nearby lines
          for (var j = i; j <= i + 1 && j < lines.length; j++) {
            final valuePattern = RegExp('(\\d+\\.?\\d*)\\s*$expectedUnit', caseSensitive: false);
            final match = valuePattern.firstMatch(lines[j]);
            if (match != null) {
              final value = double.tryParse(match.group(1)!) ?? 0.0;
              if (value >= 0 && value <= maxValue) return value;
            }
          }

          // If no value with unit found, try any number in reasonable range
          for (var j = i; j <= i + 1 && j < lines.length; j++) {
            final numbers = RegExp(r'(\d+\.?\d*)').allMatches(lines[j]);
            for (var numMatch in numbers) {
              final value = double.tryParse(numMatch.group(1)!) ?? 0.0;
              if (value >= 0 && value <= maxValue) return value;
            }
          }
        }
      }
    }

    return 0.0;
  }

  // Extract sodium (can be in mg or g)
  static double _extractSodium(List<_TextElement> elements, String text) {
    final cleanText = text.toLowerCase();

    // Try mg first (more common)
    final mgPattern = RegExp(r'sodium[:\s-]+(\d+\.?\d*)\s*mg', caseSensitive: false);
    var match = mgPattern.firstMatch(cleanText);
    if (match != null) {
      final value = double.tryParse(match.group(1)!) ?? 0.0;
      if (value >= 0 && value <= 5000) return value;
    }

    // Try grams
    final gPattern = RegExp(r'sodium[:\s-]+(\d+\.?\d*)\s*g', caseSensitive: false);
    match = gPattern.firstMatch(cleanText);
    if (match != null) {
      final value = double.tryParse(match.group(1)!) ?? 0.0;
      if (value >= 0 && value <= 5) return value * 1000; // Convert to mg
    }

    // Look for "sodium" keyword near numbers with mg/g units
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains('sodium')) {
        for (var j = i; j <= i + 1 && j < lines.length; j++) {
          final mgMatch = RegExp(r'(\d+\.?\d*)\s*mg').firstMatch(lines[j]);
          if (mgMatch != null) {
            final value = double.tryParse(mgMatch.group(1)!) ?? 0.0;
            if (value >= 0 && value <= 5000) return value;
          }
        }
      }
    }

    return 0.0;
  }

  // Extract product name from text
  static String? extractProductName(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // Keywords that indicate this is NOT a product name
    final excludeKeywords = [
      'nutrition', 'facts', 'serving', 'calories', 'energy', 'protein',
      'carbohydrate', 'fat', 'fiber', 'sugar', 'sodium', 'vitamin',
      'calcium', 'iron', 'per serving', 'amount', 'daily value', '%',
      'ingredients', 'allergen'
    ];

    // Patterns that indicate this is NOT a product name
    final excludePatterns = [
      RegExp(r'\d+\s*(g|mg|kcal|cal)\b', caseSensitive: false),  // Numbers with units
      RegExp(r'^\d+\.?\d*$'),  // Just a number
      RegExp(r'\d+%'),  // Percentages
    ];

    final candidates = <String>[];

    // Scan first 10 lines for potential product names
    for (var i = 0; i < lines.length && i < 10; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      // Skip if line contains exclude keywords
      if (excludeKeywords.any((keyword) => lineLower.contains(keyword))) {
        continue;
      }

      // Skip if line matches exclude patterns
      if (excludePatterns.any((pattern) => pattern.hasMatch(line))) {
        continue;
      }

      // Good product name characteristics:
      // - Not too short (>3 chars) or too long (<80 chars)
      // - Contains letters
      // - Doesn't start with a number
      if (line.length > 3 &&
          line.length < 80 &&
          RegExp(r'[a-zA-Z]').hasMatch(line) &&
          !RegExp(r'^\d').hasMatch(line)) {
        candidates.add(line);
      }
    }

    // Prefer candidates from earlier in the text
    if (candidates.isNotEmpty) {
      // Filter out very generic or suspicious names
      final filtered = candidates.where((c) {
        final lower = c.toLowerCase();
        // Skip if it's mostly numbers
        final digitCount = c.replaceAll(RegExp(r'[^\d]'), '').length;
        if (digitCount > c.length / 2) return false;

        // Skip common non-name text
        if (lower == 'label' || lower == 'front' || lower == 'back') return false;

        return true;
      }).toList();

      return filtered.isNotEmpty ? filtered.first : null;
    }

    return null;
  }
}
