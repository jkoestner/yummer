import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';

// Your app imports
import 'models.dart';
import 'storage_helper.dart';
import 'add_food_sheet.dart';
import 'edit_entry_dialog.dart';
import 'settings_page.dart';
import 'usda_service.dart';
import 'openai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await StorageHelper.init();

  // Initialize USDA service (loads API key from storage)
  await USDAService.init();

  // Initialize OpenAI service (loads API key from storage)
  await OpenAIService.init();

  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'Nutrition Tracker',
    url: 'https://github.com/yourusername/nutrition-tracker',
  );
  OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
    OpenFoodFactsLanguage.ENGLISH,
  ];

  runApp(const NutritionTrackerApp());
}

class NutritionTrackerApp extends StatefulWidget {
  const NutritionTrackerApp({Key? key}) : super(key: key);

  @override
  State<NutritionTrackerApp> createState() => _NutritionTrackerAppState();
}

class _NutritionTrackerAppState extends State<NutritionTrackerApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final themeString = await StorageHelper.instance.getThemeMode();
    setState(() {
      _themeMode = _themeModeFromString(themeString);
    });
  }

  ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrition Tracker',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomePage(onThemeChanged: _changeTheme),
    );
  }
}

class HomePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const HomePage({Key? key, required this.onThemeChanged}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
  List<FoodEntry> foodEntries = [];
  DailyGoals goals = DailyGoals();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final entries = await StorageHelper.instance.getFoodEntriesForDate(
        selectedDate,
      );
      final loadedGoals = await StorageHelper.instance.getDailyGoals();

      if (mounted) {
        setState(() {
          foodEntries = entries;
          goals = loadedGoals;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _addFoodEntry(FoodEntry entry) async {
    await StorageHelper.instance.insertFoodEntry(entry);
    await _loadData();
  }

  Future<void> _deleteEntry(String id) async {
    await StorageHelper.instance.deleteFoodEntry(id);
    await _loadData();
  }

  Future<void> _editEntry(FoodEntry entry) async {
    final result = await showDialog<FoodEntry>(
      context: context,
      builder: (context) => EditEntryDialog(entry: entry),
    );

    if (result != null) {
      await StorageHelper.instance.updateFoodEntry(result);
      await _loadData();
    }
  }

  void _changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
    _loadData();
  }

  Map<String, double> _calculateTotals() {
    return {
      'calories': foodEntries.fold(0.0, (sum, entry) => sum + entry.calories),
      'protein': foodEntries.fold(0.0, (sum, entry) => sum + entry.protein),
      'carbs': foodEntries.fold(0.0, (sum, entry) => sum + entry.carbs),
      'fat': foodEntries.fold(0.0, (sum, entry) => sum + entry.fat),
      'fiber': foodEntries.fold(0.0, (sum, entry) => sum + entry.fiber),
      'sugar': foodEntries.fold(0.0, (sum, entry) => sum + entry.sugar),
      'sodium': foodEntries.fold(0.0, (sum, entry) => sum + entry.sodium),
    };
  }

  List<FoodEntry> _getEntriesForMeal(MealType mealType) {
    return foodEntries.where((entry) => entry.mealType == mealType).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Tracker'),
        actions: [
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'Debug Storage',
              onPressed: () async {
                final entriesBox = Hive.box('food_entries');
                final goalsBox = Hive.box('daily_goals');

                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Storage Debug'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Food entries: ${entriesBox.length}'),
                        Text('Goals saved: ${goalsBox.isNotEmpty}'),
                        Text('Entries in memory: ${foodEntries.length}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    goals: goals,
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              );
              await _loadData();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date Selector
                Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeDate(-1),
                      ),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeDate(1),
                      ),
                    ],
                  ),
                ),

                // Macros Summary
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildMacroCard(
                        'Calories',
                        totals['calories']!,
                        goals.calories,
                        'kcal',
                        Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMacroCard(
                              'Protein',
                              totals['protein']!,
                              goals.protein,
                              'g',
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMacroCard(
                              'Carbs',
                              totals['carbs']!,
                              goals.carbs,
                              'g',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMacroCard(
                              'Fat',
                              totals['fat']!,
                              goals.fat,
                              'g',
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMacroCard(
                              'Fiber',
                              totals['fiber']!,
                              goals.fiber,
                              'g',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMacroCard(
                              'Sugar',
                              totals['sugar']!,
                              50,
                              'g',
                              Colors.pink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Meal Categories
                Expanded(
                  child: foodEntries.isEmpty
                      ? const Center(
                          child: Text(
                            'No food entries yet.\nTap + to add food.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView(
                          children: [
                            for (var mealType in MealType.values)
                              _buildMealSection(mealType),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) =>
                AddFoodSheet(onAdd: _addFoodEntry, selectedDate: selectedDate),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMealSection(MealType mealType) {
    final mealEntries = _getEntriesForMeal(mealType);

    if (mealEntries.isEmpty) return const SizedBox.shrink();

    final mealTotals = {
      'calories': mealEntries.fold(0.0, (sum, entry) => sum + entry.calories),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: mealType.color.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(mealType.icon, color: mealType.color),
              const SizedBox(width: 12),
              Text(
                mealType.displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mealType.color,
                ),
              ),
              const Spacer(),
              Text(
                '${mealTotals['calories']!.toStringAsFixed(0)} cal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
        ...mealEntries.map(
          (entry) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: entry.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        entry.photoUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.restaurant, size: 50);
                        },
                      ),
                    )
                  : const Icon(Icons.restaurant, size: 50),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (entry.recipeUrl != null)
                    const Icon(Icons.menu_book, size: 16, color: Colors.grey),
                ],
              ),
              subtitle: Text(
                '${entry.servingSize.toStringAsFixed(1)} ${entry.servingUnit} • '
                '${entry.calories.toStringAsFixed(0)} cal\n'
                'P: ${entry.protein.toStringAsFixed(1)}g C: ${entry.carbs.toStringAsFixed(1)}g F: ${entry.fat.toStringAsFixed(1)}g',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editEntry(entry),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEntry(entry.id),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMacroCard(
    String label,
    double current,
    double goal,
    String unit,
    Color color,
  ) {
    final percentage = (current / goal * 100).clamp(0, 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${current.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }
}
