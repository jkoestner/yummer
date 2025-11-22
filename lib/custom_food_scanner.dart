import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'custom_food_parser.dart';
import 'custom_foods_manager.dart';
import 'models.dart';

// Helper class to store text with spatial information
class _TextBlock {
  final String text;
  final double verticalPosition;
  final double horizontalPosition;
  final double confidence;

  _TextBlock({
    required this.text,
    required this.verticalPosition,
    required this.horizontalPosition,
    required this.confidence,
  });
}

class NutritionLabelScanner extends StatefulWidget {
  final Function(FoodEntry) onAdd;
  final DateTime selectedDate;

  const NutritionLabelScanner({
    Key? key,
    required this.onAdd,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<NutritionLabelScanner> createState() => _NutritionLabelScannerState();
}

class _NutritionLabelScannerState extends State<NutritionLabelScanner> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController servingSizeController = TextEditingController();
  final TextEditingController servingsController = TextEditingController(
    text: '1.0',
  );
  final TextEditingController caloriesController = TextEditingController();
  final TextEditingController proteinController = TextEditingController();
  final TextEditingController carbsController = TextEditingController();
  final TextEditingController fatController = TextEditingController();
  final TextEditingController fiberController = TextEditingController();
  final TextEditingController sugarController = TextEditingController();
  final TextEditingController sodiumController = TextEditingController();
  final TextEditingController saturatedFatController = TextEditingController();

  String servingUnit = 'g';
  MealType selectedMealType = MealType.breakfast;
  bool isProcessing = false;
  String? errorMessage;
  File? scannedImage;
  String? extractedText;

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    servingSizeController.dispose();
    servingsController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    fiberController.dispose();
    sugarController.dispose();
    sodiumController.dispose();
    saturatedFatController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      setState(() {
        isProcessing = true;
        errorMessage = null;
      });

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) {
        setState(() {
          isProcessing = false;
        });
        return;
      }

      final File imageFile = File(photo.path);
      setState(() {
        scannedImage = imageFile;
      });

      await _processImage(imageFile);
    } catch (e) {
      setState(() {
        errorMessage = 'Error taking picture: $e';
        isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() {
        isProcessing = true;
        errorMessage = null;
      });

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (photo == null) {
        setState(() {
          isProcessing = false;
        });
        return;
      }

      final File imageFile = File(photo.path);
      setState(() {
        scannedImage = imageFile;
      });

      await _processImage(imageFile);
    } catch (e) {
      setState(() {
        errorMessage = 'Error picking image: $e';
        isProcessing = false;
      });
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      if (recognizedText.blocks.isEmpty) {
        setState(() {
          errorMessage =
              'No text found in image. Please try again with better lighting.';
          isProcessing = false;
        });
        return;
      }

      // Extract text blocks with spatial information
      final blocks = <_TextBlock>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          // Calculate vertical position (top of bounding box)
          final box = line.boundingBox;
          final verticalPos = box.top.toDouble();
          final horizontalPos = box.left.toDouble();

          blocks.add(_TextBlock(
            text: line.text,
            verticalPosition: verticalPos,
            horizontalPosition: horizontalPos,
            confidence: line.confidence ?? 1.0,
          ));
        }
      }

      // Sort blocks by vertical position (top to bottom), then horizontal (left to right)
      blocks.sort((a, b) {
        // Group lines that are roughly on the same vertical level
        const verticalThreshold = 20.0;
        if ((a.verticalPosition - b.verticalPosition).abs() < verticalThreshold) {
          // If on same line, sort left to right
          return a.horizontalPosition.compareTo(b.horizontalPosition);
        }
        // Otherwise sort top to bottom
        return a.verticalPosition.compareTo(b.verticalPosition);
      });

      // Filter out low confidence text (optional - helps reduce noise)
      final filteredBlocks = blocks.where((b) => b.confidence > 0.5).toList();

      // Build structured text maintaining spatial relationships
      final structuredText = filteredBlocks.map((b) => b.text).join('\n');

      setState(() {
        extractedText = structuredText;
      });

      if (structuredText.isEmpty) {
        setState(() {
          errorMessage =
              'Could not extract readable text. Please try again with better image quality.';
          isProcessing = false;
        });
        return;
      }

      // Parse nutrition data
      final nutritionData = NutritionLabelParser.parseNutritionText(structuredText);
      final productName = NutritionLabelParser.extractProductName(structuredText);

      // Pre-fill form with parsed data
      setState(() {
        if (productName != null && productName.isNotEmpty) {
          nameController.text = productName;
        }

        // Only set non-zero values to avoid overwriting user edits with 0.0
        if (nutritionData['servingSize']! > 0) {
          servingSizeController.text = nutritionData['servingSize']!.toStringAsFixed(1);
        }
        if (nutritionData['calories']! > 0) {
          caloriesController.text = nutritionData['calories']!.toStringAsFixed(0);
        }
        if (nutritionData['protein']! > 0) {
          proteinController.text = nutritionData['protein']!.toStringAsFixed(1);
        }
        if (nutritionData['carbs']! > 0) {
          carbsController.text = nutritionData['carbs']!.toStringAsFixed(1);
        }
        if (nutritionData['fat']! > 0) {
          fatController.text = nutritionData['fat']!.toStringAsFixed(1);
        }
        if (nutritionData['fiber']! > 0) {
          fiberController.text = nutritionData['fiber']!.toStringAsFixed(1);
        }
        if (nutritionData['sugar']! > 0) {
          sugarController.text = nutritionData['sugar']!.toStringAsFixed(1);
        }
        if (nutritionData['sodium']! > 0) {
          sodiumController.text = nutritionData['sodium']!.toStringAsFixed(0);
        }
        if (nutritionData['saturatedFat']! > 0) {
          saturatedFatController.text = nutritionData['saturatedFat']!.toStringAsFixed(1);
        }

        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error processing image: $e';
        isProcessing = false;
      });
    }
  }

  Future<void> _saveCustomFood() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a food name')));
      return;
    }

    final customFood = CustomFood(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      brand: brandController.text.trim().isNotEmpty
          ? brandController.text.trim()
          : null,
      servingSize: double.tryParse(servingSizeController.text) ?? 100,
      servingUnit: servingUnit,
      calories: double.tryParse(caloriesController.text) ?? 0,
      protein: double.tryParse(proteinController.text) ?? 0,
      carbs: double.tryParse(carbsController.text) ?? 0,
      fat: double.tryParse(fatController.text) ?? 0,
      fiber: double.tryParse(fiberController.text) ?? 0,
      sugar: double.tryParse(sugarController.text) ?? 0,
      sodium: double.tryParse(sodiumController.text) ?? 0,
      saturatedFat: double.tryParse(saturatedFatController.text) ?? 0,
      imagePath: scannedImage?.path,
      createdAt: DateTime.now(),
    );

    await CustomFoodsManager.instance.saveCustomFood(customFood);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Custom food saved!')));
    }
  }

  void _addToMeal() {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a food name')));
      return;
    }

    final servings = double.tryParse(servingsController.text) ?? 1.0;
    final servingSize = double.tryParse(servingSizeController.text) ?? 100;

    final entry = FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      servingSize: servingSize * servings,
      servingUnit: servingUnit,
      calories: (double.tryParse(caloriesController.text) ?? 0) * servings,
      protein: (double.tryParse(proteinController.text) ?? 0) * servings,
      carbs: (double.tryParse(carbsController.text) ?? 0) * servings,
      fat: (double.tryParse(fatController.text) ?? 0) * servings,
      fiber: (double.tryParse(fiberController.text) ?? 0) * servings,
      sugar: (double.tryParse(sugarController.text) ?? 0) * servings,
      sodium: (double.tryParse(sodiumController.text) ?? 0) * servings,
      saturatedFat:
          (double.tryParse(saturatedFatController.text) ?? 0) * servings,
      mealType: selectedMealType,
      timestamp: widget.selectedDate,
    );

    widget.onAdd(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (scannedImage == null) ...[
            // Camera buttons
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
                    const SizedBox(height: 24),
                    const Text(
                      'Scan a nutrition label',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Take a photo of a nutrition facts label\nand we\'ll extract the data automatically',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: isProcessing ? null : _takePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: isProcessing ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose from Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    if (isProcessing) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('Processing image...'),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else ...[
            // Form after image is scanned
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scanned image preview
                    if (scannedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          scannedImage!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Text(
                          'Edit Nutrition Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Scan new image',
                          onPressed: () {
                            setState(() {
                              scannedImage = null;
                              extractedText = null;
                              nameController.clear();
                              brandController.clear();
                              servingSizeController.clear();
                              caloriesController.clear();
                              proteinController.clear();
                              carbsController.clear();
                              fatController.clear();
                              fiberController.clear();
                              sugarController.clear();
                              sodiumController.clear();
                              saturatedFatController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(),

                    // Debug: Show extracted text
                    if (extractedText != null && extractedText!.isNotEmpty)
                      ExpansionTile(
                        title: const Text(
                          'View Extracted Text (Debug)',
                          style: TextStyle(fontSize: 14),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              extractedText!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),

                    // Product info
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Food Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

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
                          child: DropdownButtonFormField<String>(
                            value: servingUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'g', child: Text('g')),
                              DropdownMenuItem(value: 'ml', child: Text('ml')),
                              DropdownMenuItem(value: 'oz', child: Text('oz')),
                              DropdownMenuItem(
                                value: 'cup',
                                child: Text('cup'),
                              ),
                              DropdownMenuItem(
                                value: 'tbsp',
                                child: Text('tbsp'),
                              ),
                              DropdownMenuItem(
                                value: 'tsp',
                                child: Text('tsp'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                servingUnit = value ?? 'g';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Nutrition per serving',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    _buildNutrientField('Calories', caloriesController, 'kcal'),
                    _buildNutrientField('Protein', proteinController, 'g'),
                    _buildNutrientField('Carbohydrates', carbsController, 'g'),
                    _buildNutrientField('Fat', fatController, 'g'),
                    _buildNutrientField(
                      'Saturated Fat',
                      saturatedFatController,
                      'g',
                    ),
                    _buildNutrientField('Fiber', fiberController, 'g'),
                    _buildNutrientField('Sugar', sugarController, 'g'),
                    _buildNutrientField('Sodium', sodiumController, 'mg'),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

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

                    // Servings
                    TextField(
                      controller: servingsController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Servings',
                        border: OutlineInputBorder(),
                        helperText: 'How many servings to add',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saveCustomFood,
                            icon: const Icon(Icons.bookmark_add),
                            label: const Text('Save as Custom Food'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addToMeal,
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
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutrientField(
    String label,
    TextEditingController controller,
    String unit,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label ($unit)',
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }
}
