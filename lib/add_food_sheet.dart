import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import 'models.dart';
import 'mealie_service.dart';

// Main Add Food Sheet with Tabs
class AddFoodSheet extends StatefulWidget {
  final Function(FoodEntry) onAdd;
  final DateTime selectedDate;

  const AddFoodSheet({
    Key? key,
    required this.onAdd,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            'Add Food',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.public), text: 'Open Food Facts'),
              Tab(icon: Icon(Icons.menu_book), text: 'Mealie Recipes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                OpenFoodFactsTab(
                  onAdd: widget.onAdd,
                  selectedDate: widget.selectedDate,
                ),
                MealieTab(
                  onAdd: widget.onAdd,
                  selectedDate: widget.selectedDate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Open Food Facts Tab
class OpenFoodFactsTab extends StatefulWidget {
  final Function(FoodEntry) onAdd;
  final DateTime selectedDate;

  const OpenFoodFactsTab({
    Key? key,
    required this.onAdd,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<OpenFoodFactsTab> createState() => _OpenFoodFactsTabState();
}

class _OpenFoodFactsTabState extends State<OpenFoodFactsTab> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController servingsController = TextEditingController(
    text: '1.0',
  );
  List<Product> searchResults = [];
  Product? selectedProduct;
  MealType selectedMealType = MealType.breakfast;
  bool isLoading = false;
  bool isSearching = false;
  String? errorMessage;

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
          ProductField.IMAGE_FRONT_URL,
          ProductField.NUTRIMENTS,
        ],
        language: OpenFoodFactsLanguage.ENGLISH,
        version: ProductQueryVersion.v3,
      );

      final result = await OpenFoodAPIClient.searchProducts(null, searchConfig)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Search timed out. Please try again.');
            },
          );

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

  Future<void> _selectProduct(Product product) async {
    if (product.barcode == null) {
      setState(() {
        selectedProduct = product;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final detailConfig = ProductQueryConfiguration(
        product.barcode!,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [
          ProductField.NAME,
          ProductField.BARCODE,
          ProductField.BRANDS,
          ProductField.IMAGE_FRONT_URL,
          ProductField.NUTRIMENTS,
        ],
        version: ProductQueryVersion.v3,
      );

      final result = await OpenFoodAPIClient.getProductV3(detailConfig).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Loading timed out');
        },
      );

      setState(() {
        if (result.product != null) {
          selectedProduct = result.product;
        } else {
          selectedProduct = product;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        selectedProduct = product;
        isLoading = false;
      });
    }
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
                    labelText: 'Search food products',
                    hintText: 'e.g., "almond milk", "pasta"',
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            )
          else if (isSearching || isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (selectedProduct == null)
            Expanded(
              child: searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            searchController.text.isEmpty
                                ? 'Search for foods to get started'
                                : 'No results found. Try a different search.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final product = searchResults[index];
                        final brandName = product.brands;
                        final photoUrl = product.imageFrontUrl;

                        return ListTile(
                          leading: photoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    photoUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.restaurant);
                                    },
                                  ),
                                )
                              : const Icon(Icons.restaurant),
                          title: Text(product.productName ?? 'Unknown Product'),
                          subtitle: brandName != null ? Text(brandName) : null,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectProduct(product),
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
                    if (selectedProduct!.imageFrontUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          selectedProduct!.imageFrontUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Icon(Icons.restaurant, size: 100),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
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
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 16),

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
                                color: isSelected
                                    ? Colors.white
                                    : mealType.color,
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

                    TextField(
                      controller: servingsController,
                      decoration: const InputDecoration(
                        labelText: 'Servings (100g each)',
                        border: OutlineInputBorder(),
                        helperText: 'Enter number of 100g servings',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nutrition Facts (per 100g)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildNutritionRow(
                      'Calories',
                      getNutrientValue(
                        selectedProduct!.nutriments,
                        'energy-kcal',
                      ),
                      'kcal',
                    ),
                    _buildNutritionRow(
                      'Protein',
                      getNutrientValue(selectedProduct!.nutriments, 'proteins'),
                      'g',
                    ),
                    _buildNutritionRow(
                      'Carbohydrates',
                      getNutrientValue(
                        selectedProduct!.nutriments,
                        'carbohydrates',
                      ),
                      'g',
                    ),
                    _buildNutritionRow(
                      'Fat',
                      getNutrientValue(selectedProduct!.nutriments, 'fat'),
                      'g',
                    ),
                    _buildNutritionRow(
                      'Fiber',
                      getNutrientValue(selectedProduct!.nutriments, 'fiber'),
                      'g',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final servings =
                              double.tryParse(servingsController.text) ?? 1.0;
                          final entry = FoodEntry.fromOpenFoodFacts(
                            selectedProduct!,
                            widget.selectedDate,
                            servings,
                            selectedMealType,
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
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedProduct = null;
                        });
                      },
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

// Mealie Tab
class MealieTab extends StatefulWidget {
  final Function(FoodEntry) onAdd;
  final DateTime selectedDate;

  const MealieTab({Key? key, required this.onAdd, required this.selectedDate})
    : super(key: key);

  @override
  State<MealieTab> createState() => _MealieTabState();
}

class _MealieTabState extends State<MealieTab> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController servingsController = TextEditingController(
    text: '1.0',
  );
  List<Map<String, dynamic>> searchResults = [];
  Map<String, dynamic>? selectedRecipe;
  MealType selectedMealType = MealType.dinner;
  bool isLoading = false;
  bool isSearching = false;
  String? errorMessage;
  bool isMealieConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkMealieConfig();
  }

  Future<void> _checkMealieConfig() async {
    final url = await MealieService.getMealieUrl();
    final token = await MealieService.getMealieToken();
    setState(() {
      isMealieConfigured =
          url != null && token != null && url.isNotEmpty && token.isNotEmpty;
    });
  }

  Future<void> _performSearch() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
      searchResults = [];
      selectedRecipe = null;
      errorMessage = null;
    });

    try {
      final results = await MealieService.searchRecipes(query);
      setState(() {
        searchResults = results;
        if (results.isEmpty) {
          errorMessage = 'No recipes found';
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

  Future<void> _selectRecipe(Map<String, dynamic> recipe) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final details = await MealieService.getRecipeDetails(recipe['slug']);
      setState(() {
        selectedRecipe = details ?? recipe;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        selectedRecipe = recipe;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isMealieConfigured) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Mealie Not Configured',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Configure your Mealie instance in Settings to import recipes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

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
                    labelText: 'Search recipes',
                    hintText: 'e.g., "lasagna"',
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
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            )
          else if (isSearching || isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (selectedRecipe == null)
            Expanded(
              child: searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Search for your Mealie recipes',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final recipe = searchResults[index];
                        return ListTile(
                          leading: recipe['imageUrl'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    recipe['imageUrl'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.menu_book),
                                  ),
                                )
                              : const Icon(Icons.menu_book),
                          title: Text(recipe['name'] ?? 'Unknown Recipe'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectRecipe(recipe),
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
                    if (selectedRecipe!['imageUrl'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          selectedRecipe!['imageUrl'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      selectedRecipe!['name'] ?? 'Unknown Recipe',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Meal Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: MealType.values.map((mealType) {
                        final isSelected = selectedMealType == mealType;
                        return ChoiceChip(
                          label: Text(mealType.displayName),
                          selected: isSelected,
                          selectedColor: mealType.color,
                          onSelected: (selected) =>
                              setState(() => selectedMealType = mealType),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: servingsController,
                      decoration: InputDecoration(
                        labelText: 'Servings',
                        border: const OutlineInputBorder(),
                        helperText:
                            'Recipe yields: ${selectedRecipe!['recipeServings'] ?? 1.0}',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    if (selectedRecipe!['nutrition'] != null) ...[
                      const Text(
                        'Nutrition Facts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildNutritionRow(
                        'Calories',
                        selectedRecipe!['nutrition']?['calories'],
                      ),
                      _buildNutritionRow(
                        'Protein',
                        selectedRecipe!['nutrition']?['proteinContent'],
                      ),
                      _buildNutritionRow(
                        'Carbs',
                        selectedRecipe!['nutrition']?['carbohydrateContent'],
                      ),
                      _buildNutritionRow(
                        'Fat',
                        selectedRecipe!['nutrition']?['fatContent'],
                      ),
                      _buildNutritionRow(
                        'Fiber',
                        selectedRecipe!['nutrition']?['fiberContent'],
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No nutrition data available for this recipe.',
                        ),
                      ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedRecipe!['nutrition'] == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'This recipe has no nutrition data.',
                                ),
                              ),
                            );
                            return;
                          }

                          final servings =
                              double.tryParse(servingsController.text) ?? 1.0;
                          final entry = FoodEntry.fromMealieRecipe(
                            selectedRecipe!,
                            widget.selectedDate,
                            servings,
                            selectedMealType,
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
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => selectedRecipe = null),
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

  Widget _buildNutritionRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    final numValue = double.tryParse(value.toString()) ?? 0;
    if (numValue == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${numValue.toStringAsFixed(1)}g',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
