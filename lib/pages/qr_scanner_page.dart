import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/services/merchant_service.dart';
import 'package:ouro_pay_consumer_app/pages/merchant_payment_page.dart';
import 'package:ouro_pay_consumer_app/pages/payment_history_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isProcessing = false;
  final GlobalKey _scannerKey = GlobalKey();

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isProcessing = true;
        });
        _handleQrCode(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _handleQrCode(String code) async {
    try {
      final Map<String, dynamic> data = jsonDecode(code);

      // Validation logic
      // Must receive: type = merchant_static_payment
      bool isValid = data['type'] == 'merchant_static_payment' &&
          data.containsKey('merchant_id') &&
          data.containsKey('currency');

      if (!isValid) {
        _showErrorDialog(
            'Invalid QR Code. Please scan a valid merchant payment QR code.');
        return;
      }

      final int merchantId = data['merchant_id'];
      final String currency = data['currency'];

      // Show processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
      );

      // Fetch merchant info
      final merchantService = MerchantService();
      // Add optional name from QR code to be used if needed?
      // Actually, let's see if we can use the QR data directly if it has enough info.

      // If the QR code contains the merchant name, we might construct the object directly
      // However, we should prefer the backend source of truth.
      // But if the user insists this "should get the response", maybe they mean the QR code *is* the response?

      // Let's stick to the current logic which calls the API, as I am on the "working commit".
      final response =
          await merchantService.getMerchantInfo(merchantId, currency);

      // Close processing dialog
      if (mounted) Navigator.of(context).pop();

      if (response.success && response.data != null) {
        if (!mounted) return;

        // Navigate to payment page and remove scanner from stack so back button goes to dashboard
        // Navigate to payment page
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                MerchantPaymentPage(paymentInfo: response.data!),
          ),
        );

        // If payment was successful (returned true), close scanner and notify dashboard
        if (result == true && mounted) {
          Navigator.of(context).pop(true);
        } else {
          // If payment cancelled/back, go back to dashboard as requested
          if (mounted) Navigator.of(context).pop();
        }
      } else {
        _showErrorDialog(
            response.message ?? 'Failed to load merchant details.');
      }
    } catch (e) {
      _showErrorDialog('Invalid QR Code format.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Error', style: TextStyle(color: AppColors.errorRed)),
        content:
            Text(message, style: const TextStyle(color: AppColors.whiteText)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text('OK',
                style: TextStyle(color: AppColors.primaryGold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan to Pay'),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.whiteText),
        titleTextStyle: const TextStyle(
            color: AppColors.whiteText,
            fontSize: 20,
            fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PaymentHistoryPage()),
              );
            },
            icon: const Icon(Icons.history, color: AppColors.whiteText),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            key: _scannerKey,
            onDetect: _onDetect,
          ),
          // Dark overlay with cutout
          CustomPaint(
            painter: ScannerOverlayPainter(borderColor: AppColors.primaryGold),
            child: Container(),
          ),
          // Instruction text
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Align QR code within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;

  ScannerOverlayPainter({
    required this.borderColor,
    this.borderRadius = 20,
    this.borderLength = 40,
    this.borderWidth = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final Rect scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw dark background with cutout
    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);

    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
          RRect.fromRectAndRadius(scanRect, Radius.circular(borderRadius)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw corners
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final Path borderPath = Path();

    // Top Left
    borderPath.moveTo(scanRect.left, scanRect.top + borderLength);
    borderPath.lineTo(scanRect.left, scanRect.top);
    borderPath.lineTo(scanRect.left + borderLength, scanRect.top);

    // Top Right
    borderPath.moveTo(scanRect.right - borderLength, scanRect.top);
    borderPath.lineTo(scanRect.right, scanRect.top);
    borderPath.lineTo(scanRect.right, scanRect.top + borderLength);

    // Bottom Right
    borderPath.moveTo(scanRect.right, scanRect.bottom - borderLength);
    borderPath.lineTo(scanRect.right, scanRect.bottom);
    borderPath.lineTo(scanRect.right - borderLength, scanRect.bottom);

    // Bottom Left
    borderPath.moveTo(scanRect.left + borderLength, scanRect.bottom);
    borderPath.lineTo(scanRect.left, scanRect.bottom);
    borderPath.lineTo(scanRect.left, scanRect.bottom - borderLength);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
