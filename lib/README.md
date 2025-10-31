# Nutrition Tracker App

A Flutter nutrition tracking app with Open Food Facts and Mealie integration.

## 📁 Project Structure

```
lib/
├── main.dart              # Main app and home page
├── models.dart            # Data models (FoodEntry, DailyGoals, MealType)
├── storage_helper.dart    # Local storage (SharedPreferences)
├── mealie_service.dart    # Mealie API integration
├── add_food_sheet.dart    # Food search UI (Open Food Facts + Mealie)
└── settings_page.dart     # Settings and Mealie configuration
```

## 🚀 Setup Instructions

### 1. Create Flutter Project
```bash
flutter create nutrition_tracker
cd nutrition_tracker
```

### 2. Update pubspec.yaml

Add these dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  intl: ^0.18.0
  openfoodfacts: ^3.27.0
  shared_preferences: ^2.2.2
  http: ^1.2.0
```

### 3. Add Files to lib/

Create the following files in `lib/` directory:
- `models.dart` - Copy from artifact "models.dart - Data Models"
- `storage_helper.dart` - Copy from artifact "storage_helper.dart - Data Persistence"
- `mealie_service.dart` - Copy from artifact "mealie_service.dart - Mealie API Integration"
- `main.dart` - Copy from artifact "main.dart - Core App" (but you need the complete versions)

### 4. Update main.dart Imports

Replace the placeholder imports at the top of `main.dart` with:

```dart
import 'models.dart';
import 'storage_helper.dart';
import 'mealie_service.dart';
import 'add_food_sheet.dart';
import 'settings_page.dart';
```

Remove the placeholder classes at the bottom of `main.dart`.

### 5. Install Dependencies

```bash
flutter pub get
```

### 6. Run the App

**For Web (with persistent storage):**
```bash
flutter run -d chrome --web-port=8080
```

**For Android:**
```bash
flutter run
```

## ✨ Features

### Food Tracking
- ✅ Track calories and macros (protein, carbs, fat, fiber)
- ✅ Track micronutrients (sodium, sugar, vitamins, minerals)
- ✅ Meal categories (Breakfast, Lunch, Dinner, Snacks)
- ✅ Date navigation to view different days
- ✅ Progress bars for daily goals

### Open Food Facts Integration
- ✅ Search 2.9M+ food products worldwide
- ✅ Complete nutrition data
- ✅ Product images
- ✅ Barcode information
- ✅ No API key required (free!)

### Mealie Integration
- ✅ Import recipes from your self-hosted Mealie instance
- ✅ Automatic nutrition data import
- ✅ Adjustable serving sizes
- ✅ Recipe photos

### Data Persistence
- ✅ All entries saved locally (SharedPreferences)
- ✅ Works on web and mobile
- ✅ Survives app restarts

## 🔧 Configuration

### Mealie Setup

1. Open the app and go to **Settings** (gear icon)
2. Tap **Mealie Integration**
3. Enter your Mealie URL: `https://mealie.yourdomain.com`
4. Get your API token:
   - Log into Mealie
   - Go to User Profile
   - Navigate to "Manage Your API Tokens"
   - Click "Generate" to create a new token
   - Copy the token
5. Paste the token in the app
6. Click **Test Connection**
7. Click **Save**

### Daily Goals

1. Go to **Settings**
2. Adjust your daily targets:
   - Calories (kcal)
   - Protein (g)
   - Carbohydrates (g)
   - Fat (g)
   - Fiber (g)
3. Click **Save Goals**

## 📱 Usage

### Adding Food

1. Tap the **+** button
2. Choose a tab:
   - **Open Food Facts**: Search packaged foods
   - **Mealie Recipes**: Search your recipes
3. Search for your food/recipe
4. Select it from results
5. Choose meal type (Breakfast, Lunch, Dinner, Snacks)
6. Adjust serving size
7. Tap **Add to [Meal Type]**

### Viewing History

- Use **← →** arrows to navigate between dates
- Tap any entry to view detailed nutrition info
- Swipe or tap delete icon to remove entries

## 🐛 Troubleshooting

### Web: Data not persisting after restart

Run with a fixed port:
```bash
flutter run -d chrome --web-port=8080
```

Browser storage is tied to the port. Always use the same port.

### Mealie: Connection failed

- Verify your Mealie URL is correct (no `/api` at the end)
- Check your API token is valid
- Ensure your Mealie instance is accessible
- Check for CORS issues if running on web

### Open Food Facts: Search timeout

The API can be slow. The timeout is set to 30 seconds. If it times out:
- Check your internet connection
- Try a different search term
- Try again later

## 📝 Notes

- **Web Storage**: Uses browser localStorage (port-specific)
- **Mobile Storage**: Uses native platform storage
- **Mealie Recipes**: Only recipes with nutrition data can be tracked
- **Open Food Facts**: Some products may have incomplete data

## 🎯 Roadmap

Future enhancements:
- [ ] Barcode scanner
- [ ] Charts and analytics
- [ ] Export reports
- [ ] Water tracking
- [ ] Weight tracking
- [ ] Custom foods
- [ ] Recipe calculator

## 📄 License

MIT License - Feel free to modify and use!