import 'package:flutter/material.dart';
import 'dart:io';

import 'models.dart';
import 'storage_helper.dart';

class RecentFoodsTab extends StatefulWidget {
  final Function(FoodEntry) onAdd;
  final DateTime selectedDate;

  const RecentFoodsTab({
    Key? key,
    required this.onAdd,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<RecentFoodsTab> createState() => _RecentFoodsTabState();
}

class _RecentFoodsTabState extends State<RecentFoodsTab> {
  final TextEditingController servingsController = TextEditingController(text: '1.0');
  List<FoodEntry> recentFoods = [];
  FoodEntry? selectedFood;
  MealType selectedMealType = MealType.breakfast;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentFoods();
  }

  Future<void> _loadRecentFoods() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get all food entries
      final allEntries = await StorageHelper.instance.getAllFoodEntries();
      
      // Create a map to track unique foods by name+barcode
      final Map<String, FoodEntry> uniqueFoods = {};
      
      // Sort by timestamp (most recent first)
      allEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Keep only unique foods (deduplicate by name and barcode)
      for (var entry in allEntries) {
        final key = '${entry.name}_${entry.barcode ?? ""}';
        if (!uniqueFoods.containsKey(key)) {
          uniqueFoods[key] = entry;
          
          // Stop after collecting 20 unique items
          if (uniqueFoods.length >= 20) break;
        }
      }
      
      setState(() {
        recentFoods = uniqueFoods.values.toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading recent foods: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Convert the stored entry into a template with original serving size
  FoodEntry _createTemplateEntry(FoodEntry original) {
    // Calculate per-serving nutrition from the original entry
    final servings = original.servingSize;
    
    return FoodEntry(
      id: original.id,
      name: original.name,
      barcode: original.barcode,
      servingSize: servings, // Keep original serving size as the base
      servingUnit: original.servingUnit,
      calories: original.calories,
      protein: original.protein,
      carbs: original.carbs,
      fat: original.fat,
      fiber: original.fiber,
      sugar: original.sugar,
      sodium: original.sodium,
      saturatedFat: original.saturatedFat,
      vitaminC: original.vitaminC,
      calcium: original.calcium,
      iron: original.iron,
      potassium: original.potassium,
      photoUrl: original.photoUrl,
      mealType: original.mealType,
      timestamp: original.timestamp,
      recipeUrl: original.recipeUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Quickly add foods you\'ve logged recently',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (selectedFood == null)
            Expanded(
              child: recentFoods.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No recent foods yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Foods you add will appear here for quick access',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: recentFoods.length,
                      itemBuilder: (context, index) {
                        final food = recentFoods[index];
                        
                        // Calculate time since last use
                        final now = DateTime.now();
                        final difference = now.difference(food.timestamp);
                        String timeAgo;
                        if (difference.inDays > 0) {
                          timeAgo = '${difference.inDays}d ago';
                        } else if (difference.inHours > 0) {
                          timeAgo = '${difference.inHours}h ago';
                        } else if (difference.inMinutes > 0) {
                          timeAgo = '${difference.inMinutes}m ago';
                        } else {
                          timeAgo = 'Just now';
                        }

                        return Card(
                          child: ListTile(
                            leading: food.photoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      food.photoUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.restaurant),
                                    ),
                                  )
                                : const Icon(Icons.restaurant, size: 50),
                            title: Text(
                              food.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${food.calories.toStringAsFixed(0)} cal • '
                                  '${food.servingSize.toStringAsFixed(0)}${food.servingUnit}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Quick add button
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () {
                                    // Quick add with same serving size
                                    final entry = FoodEntry(
                                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                                      name: food.name,
                                      barcode: food.barcode,
                                      servingSize: food.servingSize,
                                      servingUnit: food.servingUnit,
                                      calories: food.calories,
                                      protein: food.protein,
                                      carbs: food.carbs,
                                      fat: food.fat,
                                      fiber: food.fiber,
                                      sugar: food.sugar,
                                      sodium: food.sodium,
                                      saturatedFat: food.saturatedFat,
                                      vitaminC: food.vitaminC,
                                      calcium: food.calcium,
                                      iron: food.iron,
                                      potassium: food.potassium,
                                      photoUrl: food.photoUrl,
                                      mealType: _determineMealType(),
                                      timestamp: widget.selectedDate,
                                      recipeUrl: food.recipeUrl,
                                    );
                                    widget.onAdd(entry);
                                    Navigator.pop(context);
                                  },
                                  tooltip: 'Quick add',
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                selectedFood = _createTemplateEntry(food);
                                // Reset serving multiplier to 1
                                servingsController.text = '1.0';
                                // Set meal type based on current time
                                selectedMealType = _determineMealType();
                              });
                            },
                          ),
                        );
                      },
                    ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food image
                    if (selectedFood!.photoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          selectedFood!.photoUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.restaurant, size: 100),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Food name
                    Text(
                      selectedFood!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (selectedFood!.barcode != null)
                      Text(
                        'Barcode: ${selectedFood!.barcode}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 16),

                    // Meal type selector
                    const Text(
                      'Meal Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: MealType.values.map((mealType) {
                        final isSelected = selectedMealType == mealType;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                mealType.icon,
                                size: 18,
                                color: isSelected ? Colors.white : mealType.color,
                              ),
                              const SizedBox(width: 4),
                              Text(mealType.displayName),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: mealType.color,
                          onSelected: (selected) {
                            setState(() {
                              selectedMealType = mealType;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Servings multiplier
                    TextField(
                      controller: servingsController,
                      decoration: InputDecoration(
                        labelText: 'Servings',
                        border: const OutlineInputBorder(),
                        helperText:
                            'Original: ${selectedFood!.servingSize.toStringAsFixed(0)} ${selectedFood!.servingUnit}',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                final current = double.tryParse(servingsController.text) ?? 1.0;
                                if (current > 0.5) {
                                  servingsController.text = (current - 0.5).toStringAsFixed(1);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                final current = double.tryParse(servingsController.text) ?? 1.0;
                                servingsController.text = (current + 0.5).toStringAsFixed(1);
                              },
                            ),
                          ],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Nutrition facts
                    const Text(
                      'Nutrition Facts (per serving)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildNutritionRow('Calories', selectedFood!.calories, 'kcal'),
                    _buildNutritionRow('Protein', selectedFood!.protein, 'g'),
                    _buildNutritionRow('Carbohydrates', selectedFood!.carbs, 'g'),
                    _buildNutritionRow('Fat', selectedFood!.fat, 'g'),
                    if (selectedFood!.saturatedFat > 0)
                      _buildNutritionRow(
                        '  Saturated Fat',
                        selectedFood!.saturatedFat,
                        'g',
                      ),
                    if (selectedFood!.fiber > 0)
                      _buildNutritionRow('Fiber', selectedFood!.fiber, 'g'),
                    if (selectedFood!.sugar > 0)
                      _buildNutritionRow('Sugar', selectedFood!.sugar, 'g'),
                    if (selectedFood!.sodium > 0)
                      _buildNutritionRow('Sodium', selectedFood!.sodium, 'mg'),
                    const SizedBox(height: 16),

                    // Add button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final multiplier =
                              double.tryParse(servingsController.text) ?? 1.0;

                          final entry = FoodEntry(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: selectedFood!.name,
                            barcode: selectedFood!.barcode,
                            servingSize: selectedFood!.servingSize * multiplier,
                            servingUnit: selectedFood!.servingUnit,
                            calories: selectedFood!.calories * multiplier,
                            protein: selectedFood!.protein * multiplier,
                            carbs: selectedFood!.carbs * multiplier,
                            fat: selectedFood!.fat * multiplier,
                            fiber: selectedFood!.fiber * multiplier,
                            sugar: selectedFood!.sugar * multiplier,
                            sodium: selectedFood!.sodium * multiplier,
                            saturatedFat: selectedFood!.saturatedFat * multiplier,
                            vitaminC: selectedFood!.vitaminC != null
                                ? selectedFood!.vitaminC! * multiplier
                                : null,
                            calcium: selectedFood!.calcium != null
                                ? selectedFood!.calcium! * multiplier
                                : null,
                            iron: selectedFood!.iron != null
                                ? selectedFood!.iron! * multiplier
                                : null,
                            potassium: selectedFood!.potassium != null
                                ? selectedFood!.potassium! * multiplier
                                : null,
                            photoUrl: selectedFood!.photoUrl,
                            mealType: selectedMealType,
                            timestamp: widget.selectedDate,
                            recipeUrl: selectedFood!.recipeUrl,
                          );

                          widget.onAdd(entry);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: selectedMealType.color,
                        ),
                        child: Text(
                          'Add to ${selectedMealType.displayName}',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedFood = null;
                        });
                      },
                      child: const Text('Back to List'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Determine meal type based on current time
  MealType _determineMealType() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 11) {
      return MealType.breakfast;
    } else if (hour >= 11 && hour < 15) {
      return MealType.lunch;
    } else if (hour >= 15 && hour < 21) {
      return MealType.dinner;
    } else {
      return MealType.snack;
    }
  }

  Widget _buildNutritionRow(String label, double value, String unit) {
    if (value == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
