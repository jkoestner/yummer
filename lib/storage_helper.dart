import 'package:hive_flutter/hive_flutter.dart';
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
}
