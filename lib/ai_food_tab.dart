import 'package:flutter/material.dart';
import 'models.dart';
import 'openai_service.dart';
import 'custom_foods_manager.dart';

class AIFoodTab extends StatefulWidget {
  final Function(FoodEntry) onAdd;
  final DateTime selectedDate;

  const AIFoodTab({
    Key? key,
    required this.onAdd,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<AIFoodTab> createState() => _AIFoodTabState();
}

class _AIFoodTabState extends State<AIFoodTab> {
  final TextEditingController foodQueryController = TextEditingController();
  final TextEditingController servingsController = TextEditingController(text: '1.0');

  Map<String, dynamic>? nutritionData;
  bool isLoading = false;
  String? errorMessage;
  MealType selectedMealType = MealType.breakfast;

  Future<void> _estimateNutrition() async {
    final query = foodQueryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        errorMessage = 'Please enter a food description';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      nutritionData = null;
    });

    try {
      final result = await OpenAIService.estimateFoodNutrition(query);

      setState(() {
        if (result != null) {
          nutritionData = result;
          errorMessage = null;
        } else {
          errorMessage = 'Could not parse nutrition data from AI response';
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _saveAsCustomFood() async {
    if (nutritionData == null) return;

    try {
      final customFood = CustomFood(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nutritionData!['name'] as String,
        brand: 'AI Estimated',
        servingSize: nutritionData!['servingSize'] as double,
        servingUnit: nutritionData!['servingUnit'] as String,
        calories: nutritionData!['calories'] as double,
        protein: nutritionData!['protein'] as double,
        carbs: nutritionData!['carbs'] as double,
        fat: nutritionData!['fat'] as double,
        fiber: nutritionData!['fiber'] as double,
        sugar: nutritionData!['sugar'] as double,
        sodium: nutritionData!['sodium'] as double,
        saturatedFat: nutritionData!['saturatedFat'] as double,
        createdAt: DateTime.now(),
      );

      await CustomFoodsManager.instance.saveCustomFood(customFood);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved as custom food! Find it in the "My Foods" tab.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Clear the form
      setState(() {
        foodQueryController.clear();
        servingsController.text = '1.0';
        nutritionData = null;
        errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving custom food: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addFood() {
    if (nutritionData == null) return;

    final servings = double.tryParse(servingsController.text) ?? 1.0;

    final entry = FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nutritionData!['name'] as String,
      timestamp: widget.selectedDate,
      mealType: selectedMealType,
      servingSize: (nutritionData!['servingSize'] as double) * servings,
      servingUnit: nutritionData!['servingUnit'] as String,
      calories: (nutritionData!['calories'] as double) * servings,
      protein: (nutritionData!['protein'] as double) * servings,
      carbs: (nutritionData!['carbs'] as double) * servings,
      fat: (nutritionData!['fat'] as double) * servings,
      fiber: (nutritionData!['fiber'] as double) * servings,
      sugar: (nutritionData!['sugar'] as double) * servings,
      sodium: (nutritionData!['sodium'] as double) * servings,
      saturatedFat: (nutritionData!['saturatedFat'] as double) * servings,
    );

    widget.onAdd(entry);

    // Clear the form
    setState(() {
      foodQueryController.clear();
      servingsController.text = '1.0';
      nutritionData = null;
      errorMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Food added successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enter any food description and AI will estimate nutritional values',
                    style: TextStyle(fontSize: 13, color: Colors.purple[900]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Food description input
          TextField(
            controller: foodQueryController,
            decoration: const InputDecoration(
              labelText: 'Food Description',
              hintText: 'e.g., grilled chicken breast, 1 slice pizza',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.restaurant),
            ),
            onSubmitted: (_) => _estimateNutrition(),
          ),
          const SizedBox(height: 16),

          // Estimate button
          ElevatedButton.icon(
            onPressed: isLoading ? null : _estimateNutrition,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology),
            label: Text(isLoading ? 'Estimating...' : 'Estimate Nutrition'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Error message
          if (errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red[900]),
                    ),
                  ),
                ],
              ),
            ),

          // Nutrition results
          if (nutritionData != null) ...[
            const Divider(),
            const SizedBox(height: 8),

            Text(
              nutritionData!['name'] as String,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Per ${nutritionData!['servingSize']}${nutritionData!['servingUnit']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Nutrition grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildNutrientRow('Calories', '${nutritionData!['calories'].toStringAsFixed(0)} kcal'),
                  const Divider(),
                  _buildNutrientRow('Protein', '${nutritionData!['protein'].toStringAsFixed(1)}g'),
                  _buildNutrientRow('Carbs', '${nutritionData!['carbs'].toStringAsFixed(1)}g'),
                  _buildNutrientRow('Fat', '${nutritionData!['fat'].toStringAsFixed(1)}g'),
                  _buildNutrientRow('Fiber', '${nutritionData!['fiber'].toStringAsFixed(1)}g'),
                  _buildNutrientRow('Sugar', '${nutritionData!['sugar'].toStringAsFixed(1)}g'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Servings input
            TextField(
              controller: servingsController,
              decoration: const InputDecoration(
                labelText: 'Servings',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Meal type selector
            DropdownButtonFormField<MealType>(
              value: selectedMealType,
              decoration: const InputDecoration(
                labelText: 'Meal Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              items: MealType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 20, color: type.color),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedMealType = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveAsCustomFood,
                    icon: const Icon(Icons.bookmark_add),
                    label: const Text('Save as Custom Food'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addFood,
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Log'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Nutrition values are AI-estimated and may not be exact. For precise tracking, use barcode scanning or verified databases.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    foodQueryController.dispose();
    servingsController.dispose();
    super.dispose();
  }
}
