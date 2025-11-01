import 'package:flutter/material.dart';
import 'dart:io';

import 'custom_foods_manager.dart';
import 'models.dart';

class CustomFoodsTab extends StatefulWidget {
  final Function(FoodEntry) onAdd;
  final DateTime selectedDate;

  const CustomFoodsTab({
    Key? key,
    required this.onAdd,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<CustomFoodsTab> createState() => _CustomFoodsTabState();
}

class _CustomFoodsTabState extends State<CustomFoodsTab> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController servingsController = TextEditingController(text: '1.0');
  List<CustomFood> customFoods = [];
  List<CustomFood> filteredFoods = [];
  CustomFood? selectedFood;
  MealType selectedMealType = MealType.breakfast;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomFoods();
  }

  Future<void> _loadCustomFoods() async {
    setState(() {
      isLoading = true;
    });

    final foods = await CustomFoodsManager.instance.getAllCustomFoods();
    
    setState(() {
      customFoods = foods;
      filteredFoods = foods;
      isLoading = false;
    });
  }

  void _filterFoods(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredFoods = customFoods;
      } else {
        final lowerQuery = query.toLowerCase();
        filteredFoods = customFoods.where((food) {
          return food.name.toLowerCase().contains(lowerQuery) ||
              (food.brand?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _deleteCustomFood(CustomFood food) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Custom Food'),
        content: Text('Are you sure you want to delete "${food.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CustomFoodsManager.instance.deleteCustomFood(food.id);
      await _loadCustomFoods();
      
      if (selectedFood?.id == food.id) {
        setState(() {
          selectedFood = null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom food deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search custom foods',
              hintText: 'Search by name or brand',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _filterFoods,
          ),
          const SizedBox(height: 16),

          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (selectedFood == null)
            Expanded(
              child: filteredFoods.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            customFoods.isEmpty
                                ? 'No custom foods saved yet'
                                : 'No foods match your search',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (customFoods.isEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Use the "Scan Label" tab to add custom foods',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredFoods.length,
                      itemBuilder: (context, index) {
                        final food = filteredFoods[index];
                        return Card(
                          child: ListTile(
                            leading: food.imagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(food.imagePath!),
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
                                if (food.brand != null) Text(food.brand!),
                                Text(
                                  '${food.calories.toStringAsFixed(0)} cal • '
                                  '${food.servingSize.toStringAsFixed(0)}${food.servingUnit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCustomFood(food),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                selectedFood = food;
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
                    if (selectedFood!.imagePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(selectedFood!.imagePath!),
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

                    // Food name and brand
                    Text(
                      selectedFood!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (selectedFood!.brand != null)
                      Text(
                        selectedFood!.brand!,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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

                    // Servings
                    TextField(
                      controller: servingsController,
                      decoration: InputDecoration(
                        labelText: 'Servings',
                        border: const OutlineInputBorder(),
                        helperText:
                            'Serving size: ${selectedFood!.servingSize.toStringAsFixed(0)} ${selectedFood!.servingUnit}',
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
                          final servings =
                              double.tryParse(servingsController.text) ?? 1.0;

                          final entry = FoodEntry(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: selectedFood!.name,
                            servingSize: selectedFood!.servingSize * servings,
                            servingUnit: selectedFood!.servingUnit,
                            calories: selectedFood!.calories * servings,
                            protein: selectedFood!.protein * servings,
                            carbs: selectedFood!.carbs * servings,
                            fat: selectedFood!.fat * servings,
                            fiber: selectedFood!.fiber * servings,
                            sugar: selectedFood!.sugar * servings,
                            sodium: selectedFood!.sodium * servings,
                            saturatedFat: selectedFood!.saturatedFat * servings,
                            mealType: selectedMealType,
                            timestamp: widget.selectedDate,
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
