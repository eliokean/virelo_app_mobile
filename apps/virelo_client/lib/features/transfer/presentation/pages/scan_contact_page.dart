import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';

class ScanContactPage extends StatefulWidget {
  const ScanContactPage({super.key});

  @override
  State<ScanContactPage> createState() => _ScanContactPageState();
}

class _ScanContactPageState extends State<ScanContactPage> {
  bool _isNfcAvailable = false;
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _initNfc();
  }

  Future<void> _initNfc() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      _isNfcAvailable = isAvailable;
    });

    if (isAvailable) {
      NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693, NfcPollingOption.iso18092},
        onDiscovered: (NfcTag tag) async {
        // En vrai, il faudrait lire le NdefRecord et extraire le numéro
        // Pour le PoC, on va simuler une lecture réussie après détection du tag
        NfcManager.instance.stopSession();
        if (mounted) {
          Navigator.pop(context, "0769303718"); // Dummy number for PoC
        }
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    if (_isNfcAvailable) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawValue = barcode.rawValue;
                if (rawValue != null) {
                  // Supposons que le QR contienne virelo://pay?phone=XXXX
                  final uri = Uri.tryParse(rawValue);
                  if (uri != null && uri.queryParameters.containsKey('phone')) {
                    Navigator.pop(context, uri.queryParameters['phone']);
                    return;
                  }
                  // Ou juste le numéro
                  Navigator.pop(context, rawValue);
                  return;
                }
              }
            },
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFF161A22).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.scanLine, color: Colors.white, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Scannez un QR Code',
                    style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                  ),
                  if (_isNfcAvailable) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'ou approchez le téléphone d\'un tag NFC',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
