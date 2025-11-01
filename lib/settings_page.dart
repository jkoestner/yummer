import 'package:flutter/material.dart';

import 'models.dart';
import 'storage_helper.dart';
import 'mealie_service.dart';
import 'usda_service.dart';

// USDA Settings Page
class USDASettingsPage extends StatefulWidget {
  const USDASettingsPage({Key? key}) : super(key: key);

  @override
  State<USDASettingsPage> createState() => _USDASettingsPageState();
}

class _USDASettingsPageState extends State<USDASettingsPage> {
  late TextEditingController apiKeyController;
  bool isTesting = false;
  String? testResult;

  @override
  void initState() {
    super.initState();
    apiKeyController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final apiKey = await _getStoredApiKey();
    setState(() {
      apiKeyController.text = apiKey ?? '';
    });
    
    // Set the API key in the service
    if (apiKey != null && apiKey.isNotEmpty) {
      USDAService.setApiKey(apiKey);
    }
  }

  Future<String?> _getStoredApiKey() async {
    try {
      return await StorageHelper.instance.getUSDAApiKey();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveApiKey(String apiKey) async {
    await StorageHelper.instance.setUSDAApiKey(apiKey);
    USDAService.setApiKey(apiKey);
  }

  Future<void> _testConnection() async {
    final apiKey = apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        testResult = '❌ Please enter an API key';
      });
      return;
    }

    setState(() {
      isTesting = true;
      testResult = null;
    });

    try {
      // Save and set the API key first
      await _saveApiKey(apiKey);

      // Test with a simple search
      final results = await USDAService.searchFoods('banana');

      setState(() {
        testResult = '✅ Connection successful! Found ${results.length} foods.';
        isTesting = false;
      });
    } catch (e) {
      setState(() {
        testResult = '❌ Connection failed: ${e.toString().replaceFirst('Exception: ', '')}';
        isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('USDA Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'USDA FoodData Central',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Access 300,000+ foods from the USDA database. Get your free API key to enable recipe building with USDA foods.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Free API Key',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The USDA API is completely free with no limits! '
                    'Sign up takes less than 1 minute.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Your USDA FoodData Central API key',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
                helperText: 'Get your free API key at fdc.nal.usda.gov',
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
                      await _saveApiKey(apiKeyController.text.trim());
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('API key saved!')),
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
              'How to get your API key:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            _buildStep(
              '1',
              'Visit the USDA API signup page',
              'https://fdc.nal.usda.gov/api-key-signup.html',
              onTap: () {
                // Could open URL in browser if you add url_launcher package
              },
            ),
            _buildStep('2', 'Fill out the simple form', 'Name, email, and organization'),
            _buildStep('3', 'Check your email', 'Your API key will be sent immediately'),
            _buildStep('4', 'Copy the API key', 'Paste it in the field above'),
            _buildStep('5', 'Test the connection', 'Click "Test Connection" to verify'),

            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What you\'ll get access to:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildBullet('300,000+ foods from USDA database'),
                  _buildBullet('Foundation Foods (basic ingredients)'),
                  _buildBullet('SR Legacy (standard reference foods)'),
                  _buildBullet('Branded Foods (packaged products)'),
                  _buildBullet('Complete nutrition data for all foods'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String subtitle, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

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
  final Function(ThemeMode) onThemeChanged;

  const SettingsPage({
    Key? key,
    required this.goals,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController caloriesController;
  late TextEditingController proteinController;
  late TextEditingController carbsController;
  late TextEditingController fatController;
  late TextEditingController fiberController;
  String selectedTheme = 'system';

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
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final theme = await StorageHelper.instance.getThemeMode();
    setState(() {
      selectedTheme = theme ?? 'system';
    });
  }

  Future<void> _saveThemePreference(String theme) async {
    await StorageHelper.instance.setThemeMode(theme);
    ThemeMode mode;
    switch (theme) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }
    widget.onThemeChanged(mode);
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
            // Theme Settings
            const Text(
              'Appearance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('System Default'),
                    subtitle: const Text('Follow system theme'),
                    value: 'system',
                    groupValue: selectedTheme,
                    onChanged: (value) {
                      setState(() {
                        selectedTheme = value!;
                      });
                      _saveThemePreference(value!);
                    },
                    secondary: const Icon(Icons.brightness_auto),
                  ),
                  RadioListTile<String>(
                    title: const Text('Light Mode'),
                    subtitle: const Text('Always use light theme'),
                    value: 'light',
                    groupValue: selectedTheme,
                    onChanged: (value) {
                      setState(() {
                        selectedTheme = value!;
                      });
                      _saveThemePreference(value!);
                    },
                    secondary: const Icon(Icons.light_mode),
                  ),
                  RadioListTile<String>(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Always use dark theme'),
                    value: 'dark',
                    groupValue: selectedTheme,
                    onChanged: (value) {
                      setState(() {
                        selectedTheme = value!;
                      });
                      _saveThemePreference(value!);
                    },
                    secondary: const Icon(Icons.dark_mode),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Daily Goals
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

            // Integrations
            const Text(
              'Integrations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.science, color: Colors.blue),
              title: const Text('USDA FoodData Central'),
              subtitle: const Text(
                'Configure USDA API for 300,000+ foods',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const USDASettingsPage(),
                  ),
                );
              },
            ),

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
