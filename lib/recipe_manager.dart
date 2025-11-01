import 'package:hive/hive.dart';
import 'recipe_models.dart';

class RecipeManager {
  static final RecipeManager instance = RecipeManager._init();
  RecipeManager._init();

  static const String _boxName = 'custom_recipes';

  // Ensure box is opened
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  Box get _box => Hive.box(_boxName);

  // Save a custom recipe
  Future<void> saveRecipe(CustomRecipe recipe) async {
    await _box.put(recipe.id, recipe.toMap());
    print('Recipe saved: ${recipe.name}');
  }

  // Get all custom recipes
  Future<List<CustomRecipe>> getAllRecipes() async {
    try {
      final recipes = _box.values
          .map((e) => CustomRecipe.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // Sort by most recently modified/created
      recipes.sort((a, b) {
        final aDate = a.lastModified ?? a.createdAt;
        final bDate = b.lastModified ?? b.createdAt;
        return bDate.compareTo(aDate);
      });

      return recipes;
    } catch (e) {
      print('Error loading recipes: $e');
      return [];
    }
  }

  // Get a specific recipe by ID
  Future<CustomRecipe?> getRecipe(String id) async {
    try {
      final recipeMap = _box.get(id);
      if (recipeMap == null) return null;
      return CustomRecipe.fromMap(Map<String, dynamic>.from(recipeMap));
    } catch (e) {
      print('Error loading recipe: $e');
      return null;
    }
  }

  // Search recipes by name
  Future<List<CustomRecipe>> searchRecipes(String query) async {
    final allRecipes = await getAllRecipes();
    if (query.isEmpty) return allRecipes;

    final lowerQuery = query.toLowerCase();
    return allRecipes.where((recipe) {
      return recipe.name.toLowerCase().contains(lowerQuery) ||
          (recipe.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Delete a recipe
  Future<void> deleteRecipe(String id) async {
    await _box.delete(id);
    print('Recipe deleted: $id');
  }

  // Update a recipe
  Future<void> updateRecipe(CustomRecipe recipe) async {
    final updatedRecipe = recipe.copyWith(lastModified: DateTime.now());
    await _box.put(updatedRecipe.id, updatedRecipe.toMap());
    print('Recipe updated: ${recipe.name}');
  }
}
