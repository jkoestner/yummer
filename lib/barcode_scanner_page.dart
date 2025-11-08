import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import 'barcode_scanner_service.dart';
import 'models.dart';

class BarcodeScannerPage extends StatefulWidget {
  final Function(FoodEntry) onAdd;
  final DateTime selectedDate;

  const BarcodeScannerPage({
    Key? key,
    required this.onAdd,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isSearching = false;
  String? lastScannedBarcode;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    
    if (barcode == null || barcode == lastScannedBarcode || isSearching) {
      return;
    }

    setState(() {
      lastScannedBarcode = barcode;
      isSearching = true;
    });

    // Stop camera while searching
    await cameraController.stop();

    try {
      final result = await BarcodeScannerService.searchByBarcode(barcode);

      if (!mounted) return;

      if (result == null) {
        _showNotFoundDialog(barcode);
        return;
      }

      // Show the found product
      if (result.source == 'openfoodfacts') {
        _showOpenFoodFactsProduct(result.data as Product);
      } else {
        _showUSDAProduct(result.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        _resetScanner();
      }
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Text(
          'Barcode $barcode not found in Open Food Facts or USDA databases.\n\n'
          'You can:\n'
          '• Try scanning again\n'
          '• Search manually\n'
          '• Scan the nutrition label instead',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to add food sheet
            },
            child: const Text('Manual Search'),
          ),
        ],
      ),
    );
  }

  void _showOpenFoodFactsProduct(Product product) {
    Navigator.pop(context, {
      'source': 'openfoodfacts',
      'product': product,
    });
  }

  void _showUSDAProduct(Map<String, dynamic> food) {
    Navigator.pop(context, {
      'source': 'usda',
      'food': food,
    });
  }

  void _resetScanner() {
    setState(() {
      lastScannedBarcode = null;
    });
    cameraController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: Icon(cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: cameraController,
            onDetect: _onBarcodeDetected,
          ),

          // Overlay with scanning frame
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),

          // Instructions
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: const Text(
                'Position barcode within the frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Loading indicator
          if (isSearching)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Searching databases...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for scanner overlay
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final scanAreaWidth = size.width * 0.8;
    final scanAreaHeight = size.height * 0.3;
    final left = (size.width - scanAreaWidth) / 2;
    final top = (size.height - scanAreaHeight) / 2;

    final scanRect = Rect.fromLTWH(left, top, scanAreaWidth, scanAreaHeight);

    // Draw dark overlay with cutout
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()..addRect(scanRect);
    final overlayPath = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(overlayPath, paint);

    // Draw border around scan area
    canvas.drawRect(scanRect, borderPaint);

    // Draw corner markers
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    // Top-left corner
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), cornerPaint);

    // Top-right corner
    canvas.drawLine(Offset(left + scanAreaWidth, top), 
        Offset(left + scanAreaWidth - cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaWidth, top), 
        Offset(left + scanAreaWidth, top + cornerLength), cornerPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, top + scanAreaHeight), 
        Offset(left + cornerLength, top + scanAreaHeight), cornerPaint);
    canvas.drawLine(Offset(left, top + scanAreaHeight), 
        Offset(left, top + scanAreaHeight - cornerLength), cornerPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(left + scanAreaWidth, top + scanAreaHeight), 
        Offset(left + scanAreaWidth - cornerLength, top + scanAreaHeight), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaWidth, top + scanAreaHeight), 
        Offset(left + scanAreaWidth, top + scanAreaHeight - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
