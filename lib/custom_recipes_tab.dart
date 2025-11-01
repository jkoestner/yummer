import 'package:flutter/material.dart';

import 'recipe_models.dart';
import 'recipe_manager.dart';
import 'recipe_builder_page.dart';
import 'models.dart';

class CustomRecipesTab extends StatefulWidget {
  final Function(FoodEntry) onAdd;
  final DateTime selectedDate;

  const CustomRecipesTab({
    Key? key,
    required this.onAdd,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<CustomRecipesTab> createState() => _CustomRecipesTabState();
}

class _CustomRecipesTabState extends State<CustomRecipesTab> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController servingsController = TextEditingController(text: '1.0');
  List<CustomRecipe> recipes = [];
  List<CustomRecipe> filteredRecipes = [];
  CustomRecipe? selectedRecipe;
  MealType selectedMealType = MealType.breakfast;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      isLoading = true;
    });

    final loadedRecipes = await RecipeManager.instance.getAllRecipes();

    setState(() {
      recipes = loadedRecipes;
      filteredRecipes = loadedRecipes;
      isLoading = false;
    });
  }

  void _filterRecipes(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRecipes = recipes;
      } else {
        final lowerQuery = query.toLowerCase();
        filteredRecipes = recipes.where((recipe) {
          return recipe.name.toLowerCase().contains(lowerQuery) ||
              (recipe.description?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _createNewRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecipeBuilderPage(),
      ),
    );

    if (result == true) {
      await _loadRecipes();
    }
  }

  Future<void> _editRecipe(CustomRecipe recipe) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeBuilderPage(existingRecipe: recipe),
      ),
    );

    if (result == true) {
      await _loadRecipes();
      if (selectedRecipe?.id == recipe.id) {
        setState(() {
          selectedRecipe = null;
        });
      }
    }
  }

  Future<void> _deleteRecipe(CustomRecipe recipe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${recipe.name}"?'),
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
      await RecipeManager.instance.deleteRecipe(recipe.id);
      await _loadRecipes();

      if (selectedRecipe?.id == recipe.id) {
        setState(() {
          selectedRecipe = null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe deleted')),
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
          // Search and Create button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search recipes',
                    hintText: 'Search by name or description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _filterRecipes,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _createNewRecipe,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Create Recipe',
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (selectedRecipe == null)
            Expanded(
              child: filteredRecipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            recipes.isEmpty
                                ? 'No recipes created yet'
                                : 'No recipes match your search',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (recipes.isEmpty) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _createNewRecipe,
                              icon: const Icon(Icons.add),
                              label: const Text('Create Your First Recipe'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = filteredRecipes[index];
                        final nutrition = recipe.nutritionPerServing;

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.restaurant_menu, size: 40),
                            title: Text(
                              recipe.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (recipe.description != null)
                                  Text(
                                    recipe.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                Text(
                                  '${nutrition['calories']!.toStringAsFixed(0)} cal/serving • '
                                  '${recipe.ingredients.length} ingredients',
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
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _editRecipe(recipe),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _deleteRecipe(recipe),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                selectedRecipe = recipe;
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
                    // Recipe name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedRecipe!.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editRecipe(selectedRecipe!),
                        ),
                      ],
                    ),
                    if (selectedRecipe!.description != null)
                      Text(
                        selectedRecipe!.description!,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 16),

                    // Ingredients list
                    const Text(
                      'Ingredients',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...selectedRecipe!.ingredients.map((ingredient) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              _getSourceIcon(ingredient.source),
                              size: 16,
                              color: _getSourceColor(ingredient.source),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${ingredient.quantity.toStringAsFixed(1)}${ingredient.unit} ${ingredient.name}',
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
                            'Recipe makes ${selectedRecipe!.servings.toStringAsFixed(1)} servings',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Nutrition facts per serving
                    const Text(
                      'Nutrition Facts (per serving)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildNutritionRow(
                      'Calories',
                      selectedRecipe!.nutritionPerServing['calories']!,
                      'kcal',
                    ),
                    _buildNutritionRow(
                      'Protein',
                      selectedRecipe!.nutritionPerServing['protein']!,
                      'g',
                    ),
                    _buildNutritionRow(
                      'Carbohydrates',
                      selectedRecipe!.nutritionPerServing['carbs']!,
                      'g',
                    ),
                    _buildNutritionRow(
                      'Fat',
                      selectedRecipe!.nutritionPerServing['fat']!,
                      'g',
                    ),
                    if (selectedRecipe!.nutritionPerServing['fiber']! > 0)
                      _buildNutritionRow(
                        'Fiber',
                        selectedRecipe!.nutritionPerServing['fiber']!,
                        'g',
                      ),
                    if (selectedRecipe!.nutritionPerServing['sugar']! > 0)
                      _buildNutritionRow(
                        'Sugar',
                        selectedRecipe!.nutritionPerServing['sugar']!,
                        'g',
                      ),
                    if (selectedRecipe!.nutritionPerServing['sodium']! > 0)
                      _buildNutritionRow(
                        'Sodium',
                        selectedRecipe!.nutritionPerServing['sodium']!,
                        'mg',
                      ),
                    const SizedBox(height: 16),

                    // Add button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final servings =
                              double.tryParse(servingsController.text) ?? 1.0;
                          final nutritionPerServing = selectedRecipe!.nutritionPerServing;

                          final entry = FoodEntry(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: selectedRecipe!.name,
                            servingSize: servings,
                            servingUnit: 'serving',
                            calories: nutritionPerServing['calories']! * servings,
                            protein: nutritionPerServing['protein']! * servings,
                            carbs: nutritionPerServing['carbs']! * servings,
                            fat: nutritionPerServing['fat']! * servings,
                            fiber: nutritionPerServing['fiber']! * servings,
                            sugar: nutritionPerServing['sugar']! * servings,
                            sodium: nutritionPerServing['sodium']! * servings,
                            saturatedFat: nutritionPerServing['saturatedFat']! * servings,
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
                          selectedRecipe = null;
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

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'custom':
        return Icons.bookmark;
      case 'usda':
        return Icons.science;
      case 'openfoodfacts':
        return Icons.public;
      default:
        return Icons.restaurant;
    }
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'custom':
        return Colors.purple;
      case 'usda':
        return Colors.blue;
      case 'openfoodfacts':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
