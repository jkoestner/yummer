import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import 'recipe_models.dart';
import 'recipe_manager.dart';
import 'custom_foods_manager.dart';
import 'usda_service.dart';
import 'models.dart';

class RecipeBuilderPage extends StatefulWidget {
  final CustomRecipe? existingRecipe; // For editing

  const RecipeBuilderPage({Key? key, this.existingRecipe}) : super(key: key);

  @override
  State<RecipeBuilderPage> createState() => _RecipeBuilderPageState();
}

class _RecipeBuilderPageState extends State<RecipeBuilderPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController servingsController = TextEditingController(text: '1.0');
  
  List<RecipeIngredient> ingredients = [];
  bool isModified = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecipe != null) {
      nameController.text = widget.existingRecipe!.name;
      descriptionController.text = widget.existingRecipe!.description ?? '';
      servingsController.text = widget.existingRecipe!.servings.toString();
      ingredients = List.from(widget.existingRecipe!.ingredients);
    }
  }

  Future<void> _saveRecipe() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipe name')),
      );
      return;
    }

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    final recipe = CustomRecipe(
      id: widget.existingRecipe?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      description: descriptionController.text.trim().isNotEmpty 
          ? descriptionController.text.trim() 
          : null,
      ingredients: ingredients,
      servings: double.tryParse(servingsController.text) ?? 1.0,
      createdAt: widget.existingRecipe?.createdAt ?? DateTime.now(),
      lastModified: widget.existingRecipe != null ? DateTime.now() : null,
    );

    await RecipeManager.instance.saveRecipe(recipe);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved!')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _addIngredient() async {
    final ingredient = await showModalBottomSheet<RecipeIngredient>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddIngredientSheet(),
    );

    if (ingredient != null) {
      setState(() {
        ingredients.add(ingredient);
        isModified = true;
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      ingredients.removeAt(index);
      isModified = true;
    });
  }

  void _editIngredient(int index) async {
    final updatedIngredient = await showModalBottomSheet<RecipeIngredient>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddIngredientSheet(
        existingIngredient: ingredients[index],
      ),
    );

    if (updatedIngredient != null) {
      setState(() {
        ingredients[index] = updatedIngredient;
        isModified = true;
      });
    }
  }

  Map<String, double> _calculateTotalNutrition() {
    return {
      'calories': ingredients.fold(0.0, (sum, ing) => sum + ing.calories),
      'protein': ingredients.fold(0.0, (sum, ing) => sum + ing.protein),
      'carbs': ingredients.fold(0.0, (sum, ing) => sum + ing.carbs),
      'fat': ingredients.fold(0.0, (sum, ing) => sum + ing.fat),
      'fiber': ingredients.fold(0.0, (sum, ing) => sum + ing.fiber),
      'sugar': ingredients.fold(0.0, (sum, ing) => sum + ing.sugar),
      'sodium': ingredients.fold(0.0, (sum, ing) => sum + ing.sodium),
    };
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotalNutrition();
    final servings = double.tryParse(servingsController.text) ?? 1.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRecipe == null ? 'Create Recipe' : 'Edit Recipe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRecipe,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Name
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Recipe Name *',
                border: OutlineInputBorder(),
                hintText: 'e.g., "Protein Smoothie"',
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                hintText: 'Brief description of your recipe',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Servings
            TextField(
              controller: servingsController,
              decoration: const InputDecoration(
                labelText: 'Number of Servings',
                border: OutlineInputBorder(),
                helperText: 'How many servings does this recipe make?',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Ingredients Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ingredients',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (ingredients.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No ingredients added yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap "Add" to add ingredients from\nMy Foods, USDA, or Open Food Facts',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      ingredient.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ingredient.quantity.toStringAsFixed(1)} ${ingredient.unit}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${ingredient.calories.toStringAsFixed(0)} cal • '
                          'P: ${ingredient.protein.toStringAsFixed(1)}g • '
                          'C: ${ingredient.carbs.toStringAsFixed(1)}g • '
                          'F: ${ingredient.fat.toStringAsFixed(1)}g',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editIngredient(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _removeIngredient(index),
                        ),
                      ],
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getSourceColor(ingredient.source).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getSourceIcon(ingredient.source),
                        color: _getSourceColor(ingredient.source),
                      ),
                    ),
                  ),
                );
              }).toList(),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Nutrition Summary
            const Text(
              'Nutrition Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildNutritionCard(
                    'Total',
                    totals,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNutritionCard(
                    'Per Serving',
                    totals.map((key, value) => MapEntry(key, value / servings)),
                    Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveRecipe,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Save Recipe', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(String title, Map<String, double> nutrition, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text('${nutrition['calories']!.toStringAsFixed(0)} cal'),
            Text('P: ${nutrition['protein']!.toStringAsFixed(1)}g'),
            Text('C: ${nutrition['carbs']!.toStringAsFixed(1)}g'),
            Text('F: ${nutrition['fat']!.toStringAsFixed(1)}g'),
            if (nutrition['fiber']! > 0)
              Text('Fiber: ${nutrition['fiber']!.toStringAsFixed(1)}g'),
          ],
        ),
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

// Add Ingredient Sheet with tabs for different sources
class AddIngredientSheet extends StatefulWidget {
  final RecipeIngredient? existingIngredient;

  const AddIngredientSheet({Key? key, this.existingIngredient}) : super(key: key);

  @override
  State<AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends State<AddIngredientSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Add Ingredient',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.bookmark), text: 'My Foods'),
              Tab(icon: Icon(Icons.science), text: 'USDA'),
              Tab(icon: Icon(Icons.public), text: 'Open Food Facts'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CustomFoodsIngredientTab(
                  existingIngredient: widget.existingIngredient,
                ),
                USDAIngredientTab(
                  existingIngredient: widget.existingIngredient,
                ),
                OpenFoodFactsIngredientTab(
                  existingIngredient: widget.existingIngredient,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Foods Ingredient Tab
class CustomFoodsIngredientTab extends StatefulWidget {
  final RecipeIngredient? existingIngredient;

  const CustomFoodsIngredientTab({Key? key, this.existingIngredient}) : super(key: key);

  @override
  State<CustomFoodsIngredientTab> createState() => _CustomFoodsIngredientTabState();
}

class _CustomFoodsIngredientTabState extends State<CustomFoodsIngredientTab> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '100');
  List<CustomFood> customFoods = [];
  List<CustomFood> filteredFoods = [];
  CustomFood? selectedFood;
  String selectedUnit = 'g';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomFoods();
    
    if (widget.existingIngredient != null && widget.existingIngredient!.source == 'custom') {
      quantityController.text = widget.existingIngredient!.quantity.toString();
      selectedUnit = widget.existingIngredient!.unit;
    }
  }

  Future<void> _loadCustomFoods() async {
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

  void _addIngredient() {
    if (selectedFood == null) return;

    final quantity = double.tryParse(quantityController.text) ?? 100;
    final servingSize = selectedFood!.servingSize;
    final multiplier = quantity / servingSize;

    final ingredient = RecipeIngredient(
      id: selectedFood!.id,
      name: selectedFood!.name,
      source: 'custom',
      quantity: quantity,
      unit: selectedUnit,
      calories: selectedFood!.calories * multiplier,
      protein: selectedFood!.protein * multiplier,
      carbs: selectedFood!.carbs * multiplier,
      fat: selectedFood!.fat * multiplier,
      fiber: selectedFood!.fiber * multiplier,
      sugar: selectedFood!.sugar * multiplier,
      sodium: selectedFood!.sodium * multiplier,
      saturatedFat: selectedFood!.saturatedFat * multiplier,
    );

    Navigator.pop(context, ingredient);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search custom foods',
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
                  ? const Center(child: Text('No custom foods found'))
                  : ListView.builder(
                      itemCount: filteredFoods.length,
                      itemBuilder: (context, index) {
                        final food = filteredFoods[index];
                        return ListTile(
                          title: Text(food.name),
                          subtitle: Text(
                            '${food.calories.toStringAsFixed(0)} cal • '
                            '${food.servingSize.toStringAsFixed(0)}${food.servingUnit}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            setState(() {
                              selectedFood = food;
                              selectedUnit = food.servingUnit;
                            });
                          },
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
                    Text(
                      selectedFood!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'g', child: Text('g')),
                              DropdownMenuItem(value: 'ml', child: Text('ml')),
                              DropdownMenuItem(value: 'oz', child: Text('oz')),
                              DropdownMenuItem(value: 'cup', child: Text('cup')),
                              DropdownMenuItem(value: 'tbsp', child: Text('tbsp')),
                              DropdownMenuItem(value: 'tsp', child: Text('tsp')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedUnit = value ?? 'g';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addIngredient,
                        child: const Text('Add Ingredient'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => selectedFood = null),
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
}

// USDA Ingredient Tab
class USDAIngredientTab extends StatefulWidget {
  final RecipeIngredient? existingIngredient;

  const USDAIngredientTab({Key? key, this.existingIngredient}) : super(key: key);

  @override
  State<USDAIngredientTab> createState() => _USDAIngredientTabState();
}

class _USDAIngredientTabState extends State<USDAIngredientTab> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '100');
  List<Map<String, dynamic>> searchResults = [];
  Map<String, dynamic>? selectedFood;
  String selectedUnit = 'g';
  bool isSearching = false;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.existingIngredient != null && widget.existingIngredient!.source == 'usda') {
      quantityController.text = widget.existingIngredient!.quantity.toString();
      selectedUnit = widget.existingIngredient!.unit;
    }
  }

  Future<void> _performSearch() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
      searchResults = [];
      selectedFood = null;
      errorMessage = null;
    });

    try {
      final results = await USDAService.searchFoods(query);
      setState(() {
        searchResults = results;
        if (results.isEmpty) {
          errorMessage = 'No foods found';
        }
        isSearching = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isSearching = false;
      });
    }
  }

  Future<void> _selectFood(Map<String, dynamic> food) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final details = await USDAService.getFoodDetails(food['fdcId']);
      setState(() {
        selectedFood = details ?? food;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        selectedFood = food;
        isLoading = false;
      });
    }
  }

  void _addIngredient() {
    if (selectedFood == null) return;

    final quantity = double.tryParse(quantityController.text) ?? 100;
    final servingSize = selectedFood!['servingSize'] ?? 100.0;
    final multiplier = quantity / servingSize;

    final ingredient = RecipeIngredient(
      id: selectedFood!['fdcId'],
      name: selectedFood!['description'],
      source: 'usda',
      quantity: quantity,
      unit: selectedUnit,
      calories: (selectedFood!['calories'] ?? 0) * multiplier,
      protein: (selectedFood!['protein'] ?? 0) * multiplier,
      carbs: (selectedFood!['carbs'] ?? 0) * multiplier,
      fat: (selectedFood!['fat'] ?? 0) * multiplier,
      fiber: (selectedFood!['fiber'] ?? 0) * multiplier,
      sugar: (selectedFood!['sugar'] ?? 0) * multiplier,
      sodium: (selectedFood!['sodium'] ?? 0) * multiplier,
      saturatedFat: (selectedFood!['saturatedFat'] ?? 0) * multiplier,
    );

    Navigator.pop(context, ingredient);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search USDA foods',
                    hintText: 'e.g., "chicken breast"',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _performSearch,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (errorMessage != null)
            Expanded(
              child: Center(
                child: Text(errorMessage!, style: const TextStyle(color: Colors.orange)),
              ),
            )
          else if (isSearching || isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (selectedFood == null)
            Expanded(
              child: searchResults.isEmpty
                  ? const Center(
                      child: Text('Search for foods in the USDA database'),
                    )
                  : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final food = searchResults[index];
                        return ListTile(
                          title: Text(food['description'] ?? 'Unknown'),
                          subtitle: food['brandOwner'] != null
                              ? Text(food['brandOwner'])
                              : null,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectFood(food),
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
                    Text(
                      selectedFood!['description'] ?? 'Unknown Food',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'g', child: Text('g')),
                              DropdownMenuItem(value: 'ml', child: Text('ml')),
                              DropdownMenuItem(value: 'oz', child: Text('oz')),
                              DropdownMenuItem(value: 'cup', child: Text('cup')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedUnit = value ?? 'g';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addIngredient,
                        child: const Text('Add Ingredient'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => selectedFood = null),
                      child: const Text('Back to Search'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Open Food Facts Ingredient Tab
class OpenFoodFactsIngredientTab extends StatefulWidget {
  final RecipeIngredient? existingIngredient;

  const OpenFoodFactsIngredientTab({Key? key, this.existingIngredient}) : super(key: key);

  @override
  State<OpenFoodFactsIngredientTab> createState() => _OpenFoodFactsIngredientTabState();
}

class _OpenFoodFactsIngredientTabState extends State<OpenFoodFactsIngredientTab> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '100');
  List<Product> searchResults = [];
  Product? selectedProduct;
  String selectedUnit = 'g';
  bool isSearching = false;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.existingIngredient != null && widget.existingIngredient!.source == 'openfoodfacts') {
      quantityController.text = widget.existingIngredient!.quantity.toString();
      selectedUnit = widget.existingIngredient!.unit;
    }
  }

  Future<void> _performSearch() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
      searchResults = [];
      selectedProduct = null;
      errorMessage = null;
    });

    try {
      final searchConfig = ProductSearchQueryConfiguration(
        parametersList: <Parameter>[
          SearchTerms(terms: [query]),
          const PageSize(size: 10),
        ],
        fields: [
          ProductField.NAME,
          ProductField.BARCODE,
          ProductField.BRANDS,
          ProductField.NUTRIMENTS,
        ],
        language: OpenFoodFactsLanguage.ENGLISH,
        version: ProductQueryVersion.v3,
      );

      final result = await OpenFoodAPIClient.searchProducts(null, searchConfig)
          .timeout(const Duration(seconds: 30));

      setState(() {
        if (result.products != null && result.products!.isNotEmpty) {
          searchResults = result.products!;
        } else {
          errorMessage = 'No products found';
        }
        isSearching = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isSearching = false;
      });
    }
  }

  void _addIngredient() {
    if (selectedProduct == null) return;

    final quantity = double.tryParse(quantityController.text) ?? 100;
    final multiplier = quantity / 100; // OFF data is per 100g

    final nutriments = selectedProduct!.nutriments;

    final ingredient = RecipeIngredient(
      id: selectedProduct!.barcode ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: selectedProduct!.productName ?? 'Unknown Product',
      source: 'openfoodfacts',
      quantity: quantity,
      unit: selectedUnit,
      calories: getNutrientValue(nutriments, 'energy-kcal') * multiplier,
      protein: getNutrientValue(nutriments, 'proteins') * multiplier,
      carbs: getNutrientValue(nutriments, 'carbohydrates') * multiplier,
      fat: getNutrientValue(nutriments, 'fat') * multiplier,
      fiber: getNutrientValue(nutriments, 'fiber') * multiplier,
      sugar: getNutrientValue(nutriments, 'sugars') * multiplier,
      sodium: getNutrientValue(nutriments, 'sodium') * multiplier * 1000,
      saturatedFat: getNutrientValue(nutriments, 'saturated-fat') * multiplier,
    );

    Navigator.pop(context, ingredient);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Open Food Facts',
                    hintText: 'e.g., "almond milk"',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _performSearch,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (errorMessage != null)
            Expanded(
              child: Center(
                child: Text(errorMessage!, style: const TextStyle(color: Colors.orange)),
              ),
            )
          else if (isSearching || isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (selectedProduct == null)
            Expanded(
              child: searchResults.isEmpty
                  ? const Center(
                      child: Text('Search for foods to get started'),
                    )
                  : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final product = searchResults[index];
                        return ListTile(
                          title: Text(product.productName ?? 'Unknown Product'),
                          subtitle: product.brands != null
                              ? Text(product.brands!)
                              : null,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            setState(() {
                              selectedProduct = product;
                            });
                          },
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
                    Text(
                      selectedProduct!.productName ?? 'Unknown Product',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (selectedProduct!.brands != null)
                      Text(
                        selectedProduct!.brands!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                              helperText: 'Amount in grams',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'g', child: Text('g')),
                              DropdownMenuItem(value: 'ml', child: Text('ml')),
                              DropdownMenuItem(value: 'oz', child: Text('oz')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedUnit = value ?? 'g';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addIngredient,
                        child: const Text('Add Ingredient'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => selectedProduct = null),
                      child: const Text('Back to Search'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
