import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

class StorageHelper {
  static final StorageHelper instance = StorageHelper._init();
  StorageHelper._init();

  static const String _entriesBoxName = 'food_entries';
  static const String _goalsBoxName = 'daily_goals';
  static const String _customFoodsBoxName = 'custom_foods';
  static const String _customRecipesBoxName = 'custom_recipes';

  // Initialize Hive - call this in main() before runApp()
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_entriesBoxName);
    await Hive.openBox(_goalsBoxName);
    await Hive.openBox(_customFoodsBoxName);
    await Hive.openBox(_customRecipesBoxName);
  }

  Box get _entriesBox => Hive.box(_entriesBoxName);
  Box get _goalsBox => Hive.box(_goalsBoxName);

  Future<void> insertFoodEntry(FoodEntry entry) async {
    try {
      await _entriesBox.put(entry.id, entry.toMap());
      print('Entry saved: ${entry.name}, Total entries: ${_entriesBox.length}');
    } catch (e) {
      print('Error saving entry: $e');
    }
  }

  Future<List<FoodEntry>> getAllFoodEntries() async {
    try {
      final entries = _entriesBox.values
          .map((e) => FoodEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      return entries;
    } catch (e) {
      print('Error loading entries: $e');
      return [];
    }
  }

  Future<List<FoodEntry>> getFoodEntriesForDate(DateTime date) async {
    final allEntries = await getAllFoodEntries();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return allEntries.where((entry) {
      return entry.timestamp.isAfter(
            startOfDay.subtract(const Duration(seconds: 1)),
          ) &&
          entry.timestamp.isBefore(endOfDay);
    }).toList();
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    try {
      await _entriesBox.put(entry.id, entry.toMap());
      print('Entry updated: ${entry.name}');
    } catch (e) {
      print('Error updating entry: $e');
    }
  }

  Future<void> deleteFoodEntry(String id) async {
    try {
      await _entriesBox.delete(id);
      print('Entry deleted: $id');
    } catch (e) {
      print('Error deleting entry: $e');
    }
  }

  Future<DailyGoals> getDailyGoals() async {
    try {
      final goalsMap = _goalsBox.get('default');
      if (goalsMap == null) return DailyGoals();
      return DailyGoals.fromMap(Map<String, dynamic>.from(goalsMap));
    } catch (e) {
      print('Error loading goals: $e');
      return DailyGoals();
    }
  }

  Future<void> updateDailyGoals(DailyGoals goals) async {
    try {
      await _goalsBox.put('default', goals.toMap());
      print('Goals saved');
    } catch (e) {
      print('Error saving goals: $e');
    }
  }

  Future<void> clearAllData() async {
    await _entriesBox.clear();
    await _goalsBox.clear();
    print('All data cleared');
  }

  // Theme mode storage
  Future<String?> getThemeMode() async {
    try {
      return _goalsBox.get('theme_mode');
    } catch (e) {
      print('Error loading theme mode: $e');
      return null;
    }
  }

  Future<void> setThemeMode(String mode) async {
    try {
      await _goalsBox.put('theme_mode', mode);
      print('Theme mode saved: $mode');
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }

  // USDA API key storage
  Future<String?> getUSDAApiKey() async {
    try {
      return _goalsBox.get('usda_api_key');
    } catch (e) {
      print('Error loading USDA API key: $e');
      return null;
    }
  }

  Future<void> setUSDAApiKey(String apiKey) async {
    try {
      await _goalsBox.put('usda_api_key', apiKey);
      print('USDA API key saved');
    } catch (e) {
      print('Error saving USDA API key: $e');
    }
  }

  // OpenAI API key storage
  Future<String?> getOpenAIApiKey() async {
    try {
      return _goalsBox.get('openai_api_key');
    } catch (e) {
      print('Error loading OpenAI API key: $e');
      return null;
    }
  }

  Future<void> setOpenAIApiKey(String apiKey) async {
    try {
      await _goalsBox.put('openai_api_key', apiKey);
      print('OpenAI API key saved');
    } catch (e) {
      print('Error saving OpenAI API key: $e');
    }
  }

  // Export all data to JSON file
  Future<File> exportAllData() async {
    try {
      // Get all data from Hive boxes
      final foodEntriesBox = Hive.box(_entriesBoxName);
      final goalsBox = Hive.box(_goalsBoxName);
      final customFoodsBox = Hive.box(_customFoodsBoxName);
      final customRecipesBox = Hive.box(_customRecipesBoxName);

      // Create export data structure
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'foodEntries': foodEntriesBox.toMap(),
        'dailyGoals': goalsBox.toMap(),
        'customFoods': customFoodsBox.toMap(),
        'customRecipes': customRecipesBox.toMap(),
      };

      // Convert to JSON
      final jsonString = jsonEncode(exportData);

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/yummer_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      print('Data exported to: ${file.path}');
      return file;
    } catch (e) {
      print('Error exporting data: $e');
      rethrow;
    }
  }

  // Import data from JSON file
  Future<void> importAllData(String jsonString) async {
    try {
      // Parse JSON
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate version (for future compatibility)
      final version = data['version'] as String?;
      print('Importing data version: $version');

      // Get boxes
      final foodEntriesBox = Hive.box(_entriesBoxName);
      final goalsBox = Hive.box(_goalsBoxName);
      final customFoodsBox = Hive.box(_customFoodsBoxName);
      final customRecipesBox = Hive.box(_customRecipesBoxName);

      // Import food entries
      if (data['foodEntries'] != null) {
        final entries = data['foodEntries'] as Map<String, dynamic>;
        for (var entry in entries.entries) {
          await foodEntriesBox.put(entry.key, entry.value);
        }
        print('Imported ${entries.length} food entries');
      }

      // Import daily goals
      if (data['dailyGoals'] != null) {
        final goals = data['dailyGoals'] as Map<String, dynamic>;
        for (var goal in goals.entries) {
          await goalsBox.put(goal.key, goal.value);
        }
        print('Imported ${goals.length} daily goals/settings');
      }

      // Import custom foods
      if (data['customFoods'] != null) {
        final foods = data['customFoods'] as Map<String, dynamic>;
        for (var food in foods.entries) {
          await customFoodsBox.put(food.key, food.value);
        }
        print('Imported ${foods.length} custom foods');
      }

      // Import custom recipes
      if (data['customRecipes'] != null) {
        final recipes = data['customRecipes'] as Map<String, dynamic>;
        for (var recipe in recipes.entries) {
          await customRecipesBox.put(recipe.key, recipe.value);
        }
        print('Imported ${recipes.length} custom recipes');
      }

      print('Data import completed successfully');
    } catch (e) {
      print('Error importing data: $e');
      rethrow;
    }
  }

  // Clear all data (useful before import to avoid conflicts)
  Future<void> clearAllDataComplete() async {
    try {
      final foodEntriesBox = Hive.box(_entriesBoxName);
      final goalsBox = Hive.box(_goalsBoxName);
      final customFoodsBox = Hive.box(_customFoodsBoxName);
      final customRecipesBox = Hive.box(_customRecipesBoxName);

      await foodEntriesBox.clear();
      await goalsBox.clear();
      await customFoodsBox.clear();
      await customRecipesBox.clear();

      print('All data cleared');
    } catch (e) {
      print('Error clearing data: $e');
      rethrow;
    }
  }
}
