import 'package:flutter/material.dart';

import 'models.dart';
import 'storage_helper.dart';
import 'mealie_service.dart';

// Mealie Settings Page
class MealieSettingsPage extends StatefulWidget {
  const MealieSettingsPage({Key? key}) : super(key: key);

  @override
  State<MealieSettingsPage> createState() => _MealieSettingsPageState();
}

class _MealieSettingsPageState extends State<MealieSettingsPage> {
  late TextEditingController urlController;
  late TextEditingController tokenController;
  bool isTesting = false;
  String? testResult;

  @override
  void initState() {
    super.initState();
    urlController = TextEditingController();
    tokenController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url = await MealieService.getMealieUrl();
    final token = await MealieService.getMealieToken();
    setState(() {
      urlController.text = url ?? '';
      tokenController.text = token ?? '';
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      isTesting = true;
      testResult = null;
    });

    try {
      await MealieService.saveMealieConfig(
        urlController.text.trim(),
        tokenController.text.trim(),
      );

      final results = await MealieService.searchRecipes('test');

      setState(() {
        testResult =
            '✅ Connection successful! Found ${results.length} recipes.';
        isTesting = false;
      });
    } catch (e) {
      setState(() {
        testResult =
            '❌ Connection failed: ${e.toString().replaceFirst('Exception: ', '')}';
        isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mealie Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure Mealie Integration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Import recipes with nutrition data from your self-hosted Mealie instance.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Mealie URL',
                hintText: 'https://mealie.yourdomain.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
                helperText: 'Your Mealie instance URL (without /api)',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'API Token',
                hintText: 'Your Mealie API token',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
                helperText: 'Generate in Mealie: User Profile > API Tokens',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            if (testResult != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: testResult!.startsWith('✅')
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: testResult!.startsWith('✅')
                        ? Colors.green[200]!
                        : Colors.red[200]!,
                  ),
                ),
                child: Text(testResult!),
              ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isTesting ? null : _testConnection,
                    icon: isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(isTesting ? 'Testing...' : 'Test Connection'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await MealieService.saveMealieConfig(
                        urlController.text.trim(),
                        tokenController.text.trim(),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings saved!')),
                        );
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'How to get your API token:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Log into your Mealie instance'),
            const Text('2. Click your profile (top right)'),
            const Text('3. Go to "Manage Your API Tokens"'),
            const Text('4. Click "Generate" to create a new token'),
            const Text('5. Copy the token and paste it above'),
          ],
        ),
      ),
    );
  }
}

// Main Settings Page
class SettingsPage extends StatefulWidget {
  final DailyGoals goals;

  const SettingsPage({Key? key, required this.goals}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController caloriesController;
  late TextEditingController proteinController;
  late TextEditingController carbsController;
  late TextEditingController fatController;
  late TextEditingController fiberController;

  @override
  void initState() {
    super.initState();
    caloriesController = TextEditingController(
      text: widget.goals.calories.toString(),
    );
    proteinController = TextEditingController(
      text: widget.goals.protein.toString(),
    );
    carbsController = TextEditingController(
      text: widget.goals.carbs.toString(),
    );
    fatController = TextEditingController(text: widget.goals.fat.toString());
    fiberController = TextEditingController(
      text: widget.goals.fiber.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Goals',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories (kcal)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: proteinController,
              decoration: const InputDecoration(
                labelText: 'Protein (g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: carbsController,
              decoration: const InputDecoration(
                labelText: 'Carbohydrates (g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fatController,
              decoration: const InputDecoration(
                labelText: 'Fat (g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fiberController,
              decoration: const InputDecoration(
                labelText: 'Fiber (g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final newGoals = DailyGoals(
                    calories: double.tryParse(caloriesController.text) ?? 2000,
                    protein: double.tryParse(proteinController.text) ?? 150,
                    carbs: double.tryParse(carbsController.text) ?? 250,
                    fat: double.tryParse(fatController.text) ?? 65,
                    fiber: double.tryParse(fiberController.text) ?? 30,
                  );
                  await StorageHelper.instance.updateDailyGoals(newGoals);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Goals'),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'Integrations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.green),
              title: const Text('Mealie Integration'),
              subtitle: const Text(
                'Configure your self-hosted Mealie instance',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealieSettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
