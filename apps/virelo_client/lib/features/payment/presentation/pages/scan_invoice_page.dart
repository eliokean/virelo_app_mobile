import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'generate_payment_qr_pin_page.dart';

class ScanInvoicePage extends StatefulWidget {
  const ScanInvoicePage({super.key});

  @override
  State<ScanInvoicePage> createState() => _ScanInvoicePageState();
}

class _ScanInvoicePageState extends State<ScanInvoicePage> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() => _isProcessing = true);

        try {
          String merchantId = '1';
          String merchantName = 'Marchand';
          double amount = 0.0;

          if (code.contains('/pay?') || code.startsWith('http')) {
            final uri = Uri.parse(code);
            merchantId = uri.queryParameters['m'] ?? '1';
            merchantName = Uri.decodeComponent(uri.queryParameters['n'] ?? 'Marchand');
            amount = double.tryParse(uri.queryParameters['a'] ?? '0') ?? 0.0;
          } else {
            final invoiceData = jsonDecode(code);
            merchantId = invoiceData['merchantId']?.toString() ?? '1';
            merchantName = invoiceData['merchantName']?.toString() ?? 'Marchand';
            amount = (invoiceData['amount'] as num).toDouble();
          }

          if (amount <= 0) throw Exception("Montant de facture invalide");

          // Arrêter la caméra et passer à la page du PIN
          cameraController.stop();
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => GeneratePaymentQrPinPage(
                  amount: amount,
                  merchantId: merchantId,
                  merchantName: merchantName,
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Le QR Code scanné n'est pas une facture valide."),
                backgroundColor: AppColors.error,
              ),
            );
          }
          await Future.delayed(const Duration(seconds: 3));
          if (mounted) setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scanner la facture',
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFB5E48C), width: 4),
                borderRadius: BorderRadius.circular(20),
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_isProcessing)
                  const CircularProgressIndicator(color: Color(0xFFB5E48C))
                else
                  Text(
                    'Placez le QR Code de la facture dans le cadre',
                    style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
