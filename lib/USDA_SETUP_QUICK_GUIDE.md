# 🔑 USDA API Key Setup - Quick Guide

The USDA FoodData Central API is now fully integrated into your app settings!

## ✅ What's New

- **Settings Integration**: Configure USDA API key directly in the app
- **Persistent Storage**: API key is saved and loaded automatically
- **Connection Test**: Verify your API key works before saving
- **User-Friendly UI**: Step-by-step instructions built into the settings page

---

## 🚀 Quick Setup (5 minutes)

### Step 1: Get Your Free API Key

1. Visit: https://fdc.nal.usda.gov/api-key-signup.html
2. Fill out the form:
   - Name
   - Email
   - Organization (can be personal/individual)
3. Check your email - key arrives instantly!

### Step 2: Add to App

1. Open your app
2. Go to **Settings** (gear icon)
3. Scroll to **Integrations**
4. Tap **"USDA FoodData Central"**
5. Paste your API key
6. Tap **"Test Connection"**
7. If successful, tap **"Save"**

That's it! 🎉

---

## 📱 How to Use

Once configured, you can access USDA foods when:

1. **Creating Recipes**:
   - Tap + → My Recipes → + (create new)
   - Add Ingredient → USDA tab
   - Search for any food!

2. **What You Can Search**:
   - Raw ingredients: "chicken breast", "banana", "brown rice"
   - Basic foods: "eggs", "milk", "olive oil"
   - Meats: "ground beef", "salmon", "turkey"
   - Produce: "broccoli", "sweet potato", "spinach"
   - Grains: "oats", "quinoa", "whole wheat bread"

---

## 🔧 Files Updated

Make sure you have these updated files:

1. **`settings_page_updated.dart`** - Now includes USDA settings page
2. **`storage_helper_updated.dart`** - Stores/retrieves USDA API key
3. **`usda_service.dart`** - Loads API key from storage on init
4. **`main_updated.dart`** - Initializes USDA service on app start

---

## 🐛 Troubleshooting

### "USDA API key not configured" error
- Go to Settings → USDA FoodData Central
- Add your API key and save

### Test connection fails
- Check that you copied the entire API key (no spaces)
- Verify email address on signup was correct
- Check your internet connection
- Try requesting a new API key

### Can't find a food
- Use simple search terms: "chicken" not "grilled chicken breast"
- Try common names: "banana" not "cavendish banana"
- USDA is better for raw ingredients than packaged foods

---

## 💡 Tips

- **Save your API key**: Keep a copy in a password manager
- **No limits**: USDA API is completely free with no rate limits
- **Best for basics**: Use USDA for raw meats, produce, grains, nuts
- **Packaged foods**: Use Open Food Facts for branded products
- **Custom combos**: Mix USDA foods with Custom Foods and OFF in recipes

---

## 🎯 Example Searches

Try these to test your USDA integration:

| Category | Search Terms |
|----------|--------------|
| Meat | chicken breast, ground beef, salmon, turkey |
| Produce | banana, broccoli, spinach, sweet potato |
| Dairy | greek yogurt, milk, cheddar cheese |
| Grains | brown rice, oats, quinoa, whole wheat bread |
| Nuts | almonds, peanut butter, cashews, walnuts |
| Eggs | eggs, egg whites |
| Oils | olive oil, coconut oil |

---

## 📊 USDA vs Other Sources

| Source | Best For | Database Size |
|--------|----------|---------------|
| **USDA** | Raw ingredients, basic foods | 300,000+ |
| **Open Food Facts** | Packaged products with barcodes | 2.9M+ |
| **Custom Foods** | Items you scan yourself | Unlimited |
| **Mealie** | Complete multi-step recipes | Your recipes |

---

You're all set! Start building recipes with USDA foods. 🎉
