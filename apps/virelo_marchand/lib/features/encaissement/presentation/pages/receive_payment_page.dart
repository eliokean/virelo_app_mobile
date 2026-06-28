import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/constants/api_constants.dart';
import 'package:dio/dio.dart';

class ReceivePaymentPage extends StatefulWidget {
  const ReceivePaymentPage({super.key});

  @override
  State<ReceivePaymentPage> createState() => _ReceivePaymentPageState();
}

class _ReceivePaymentPageState extends State<ReceivePaymentPage> {
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
          final response = await ApiClient().dio.post(
            ApiConstants.processOffline,
            data: {'token': code},
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Paiement réussi ! ${response.data['amount']} XOF encaissés.'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context); // Go back to dashboard
          }
        } catch (e) {
          String errorMessage = 'Erreur lors de l\'encaissement';
          if (e is DioException) {
            if (e.response?.data is Map) {
              errorMessage = e.response?.data['message'] ?? e.message;
            } else {
              errorMessage = e.message ?? e.toString();
            }
          } else {
            errorMessage = e.toString();
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
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
          'Scanner le QR Code',
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          // Overlay
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
                    'Placez le QR Code du client dans le cadre',
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

