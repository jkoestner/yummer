import 'package:flutter/material.dart';
import 'models.dart';

class EditEntryDialog extends StatefulWidget {
  final FoodEntry entry;

  const EditEntryDialog({
    Key? key,
    required this.entry,
  }) : super(key: key);

  @override
  State<EditEntryDialog> createState() => _EditEntryDialogState();
}

class _EditEntryDialogState extends State<EditEntryDialog> {
  late TextEditingController nameController;
  late TextEditingController servingSizeController;
  late TextEditingController servingUnitController;
  late TextEditingController caloriesController;
  late TextEditingController proteinController;
  late TextEditingController carbsController;
  late TextEditingController fatController;
  late TextEditingController fiberController;
  late TextEditingController sugarController;
  late TextEditingController sodiumController;
  late TextEditingController saturatedFatController;
  late MealType selectedMealType;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.entry.name);
    servingSizeController = TextEditingController(
      text: widget.entry.servingSize.toStringAsFixed(1),
    );
    servingUnitController = TextEditingController(
      text: widget.entry.servingUnit,
    );
    caloriesController = TextEditingController(
      text: widget.entry.calories.toStringAsFixed(1),
    );
    proteinController = TextEditingController(
      text: widget.entry.protein.toStringAsFixed(1),
    );
    carbsController = TextEditingController(
      text: widget.entry.carbs.toStringAsFixed(1),
    );
    fatController = TextEditingController(
      text: widget.entry.fat.toStringAsFixed(1),
    );
    fiberController = TextEditingController(
      text: widget.entry.fiber.toStringAsFixed(1),
    );
    sugarController = TextEditingController(
      text: widget.entry.sugar.toStringAsFixed(1),
    );
    sodiumController = TextEditingController(
      text: widget.entry.sodium.toStringAsFixed(1),
    );
    saturatedFatController = TextEditingController(
      text: widget.entry.saturatedFat.toStringAsFixed(1),
    );
    selectedMealType = widget.entry.mealType;
  }

  @override
  void dispose() {
    nameController.dispose();
    servingSizeController.dispose();
    servingUnitController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    fiberController.dispose();
    sugarController.dispose();
    sodiumController.dispose();
    saturatedFatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Entry'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Food Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: servingSizeController,
                      decoration: const InputDecoration(
                        labelText: 'Serving Size',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: servingUnitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Meal Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              const Text(
                'Nutrition',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: caloriesController,
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Protein (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Carbs (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fatController,
                      decoration: const InputDecoration(
                        labelText: 'Fat (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fiberController,
                      decoration: const InputDecoration(
                        labelText: 'Fiber (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sugarController,
                      decoration: const InputDecoration(
                        labelText: 'Sugar (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: sodiumController,
                      decoration: const InputDecoration(
                        labelText: 'Sodium (mg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: saturatedFatController,
                decoration: const InputDecoration(
                  labelText: 'Saturated Fat (g)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedEntry = FoodEntry(
              id: widget.entry.id,
              name: nameController.text,
              barcode: widget.entry.barcode,
              servingSize: double.tryParse(servingSizeController.text) ?? 0,
              servingUnit: servingUnitController.text,
              calories: double.tryParse(caloriesController.text) ?? 0,
              protein: double.tryParse(proteinController.text) ?? 0,
              carbs: double.tryParse(carbsController.text) ?? 0,
              fat: double.tryParse(fatController.text) ?? 0,
              fiber: double.tryParse(fiberController.text) ?? 0,
              sugar: double.tryParse(sugarController.text) ?? 0,
              sodium: double.tryParse(sodiumController.text) ?? 0,
              saturatedFat: double.tryParse(saturatedFatController.text) ?? 0,
              vitaminC: widget.entry.vitaminC,
              calcium: widget.entry.calcium,
              iron: widget.entry.iron,
              potassium: widget.entry.potassium,
              photoUrl: widget.entry.photoUrl,
              mealType: selectedMealType,
              timestamp: widget.entry.timestamp,
              recipeUrl: widget.entry.recipeUrl,
            );
            Navigator.pop(context, updatedEntry);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedMealType.color,
          ),
          child: const Text(
            'Save',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
