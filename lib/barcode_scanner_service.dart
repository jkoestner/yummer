import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'usda_service.dart';

class BarcodeSearchResult {
  final String barcode;
  final String source; // 'openfoodfacts' or 'usda'
  final dynamic data; // Product for OFF, Map for USDA

  BarcodeSearchResult({
    required this.barcode,
    required this.source,
    required this.data,
  });
}

class BarcodeScannerService {
  // Search Open Food Facts by barcode
  static Future<Product?> searchOpenFoodFactsByBarcode(String barcode) async {
    try {
      final config = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [
          ProductField.NAME,
          ProductField.BARCODE,
          ProductField.BRANDS,
          ProductField.IMAGE_FRONT_URL,
          ProductField.NUTRIMENTS,
          ProductField.SERVING_SIZE,
          ProductField.SERVING_QUANTITY,
        ],
        version: ProductQueryVersion.v3,
      );

      final result = await OpenFoodAPIClient.getProductV3(config).timeout(
        const Duration(seconds: 10),
      );

      return result.product;
    } catch (e) {
      print('Error searching Open Food Facts by barcode: $e');
      return null;
    }
  }

  // Search USDA by barcode (UPC)
  static Future<Map<String, dynamic>?> searchUSDAByBarcode(String barcode) async {
    try {
      // USDA uses gtinUpc field for barcodes
      final searchResults = await USDAService.searchFoods('upc:$barcode');
      
      if (searchResults.isEmpty) {
        return null;
      }

      // Get the first result
      final firstResult = searchResults.first;
      
      // Fetch full details
      return await USDAService.getFoodDetails(firstResult['fdcId']);
    } catch (e) {
      print('Error searching USDA by barcode: $e');
      return null;
    }
  }

  // Search both databases by barcode
  static Future<BarcodeSearchResult?> searchByBarcode(String barcode) async {
    // Try Open Food Facts first (better barcode database)
    final offProduct = await searchOpenFoodFactsByBarcode(barcode);
    if (offProduct != null) {
      return BarcodeSearchResult(
        barcode: barcode,
        source: 'openfoodfacts',
        data: offProduct,
      );
    }

    // Try USDA if Open Food Facts didn't find it
    final usdaFood = await searchUSDAByBarcode(barcode);
    if (usdaFood != null) {
      return BarcodeSearchResult(
        barcode: barcode,
        source: 'usda',
        data: usdaFood,
      );
    }

    return null; // Not found in either database
  }
}
