import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart' as android_tags;
import 'package:nfc_manager/nfc_manager_ios.dart' as ios_tags;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/crypto/offline_crypto_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'show_offline_proof_page.dart';

class ScanContactPage extends StatefulWidget {
  const ScanContactPage({super.key});

  @override
  State<ScanContactPage> createState() => _ScanContactPageState();
}

class _ScanContactPageState extends State<ScanContactPage> {
  bool _isNfcAvailable = false;
  bool _isProcessingOfflinePayment = false;
  final MobileScannerController _cameraController = MobileScannerController();
  late final OfflineCryptoService _offlineCryptoService;

  @override
  void initState() {
    super.initState();
    final authService = AuthService(ApiClient());
    _offlineCryptoService = OfflineCryptoService(OfflineStorageService(authService));
    _initNfc();
  }

  Future<void> _initNfc() async {
    bool isAvailable = false;
    try {
      isAvailable = await NfcManager.instance.isAvailable();
    } catch (e) {
      // Ignore if NFC is not supported on this device
    }

    if (mounted) {
      setState(() {
        _isNfcAvailable = isAvailable;
      });
    }

    if (isAvailable) {
      try {
        NfcManager.instance.startSession(
          pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693, NfcPollingOption.iso18092},
          onDiscovered: (NfcTag tag) async {
            NfcManager.instance.stopSession();
            try {
              final ndefAndroid = android_tags.NdefAndroid.from(tag);
              final ndefIos = ios_tags.NdefIos.from(tag);
              final cachedMessage = ndefAndroid?.cachedNdefMessage ?? ndefIos?.cachedNdefMessage;

              if (cachedMessage != null) {
                for (var record in cachedMessage.records) {
                  // Assuming the payload is a text record or URI
                  final payloadStr = String.fromCharCodes(record.payload);
                  final uri = Uri.tryParse(payloadStr);
                  
                  if (uri != null && uri.scheme == 'virelo' && uri.host == 'offline_pay') {
                    final merchantId = uri.queryParameters['merchantId'] ?? 'UNKNOWN';
                    final amountStr = uri.queryParameters['amount'] ?? '0';
                    final amount = double.tryParse(amountStr) ?? 0.0;
                    
                    if (mounted) {
                      _handleOfflinePayment(merchantId, amount);
                    }
                    return;
                  }
                }
              }
            } catch (e) {
              // Failed to parse tag
            }
          }
        );
      } catch (e) {
        // Ignore session start errors
      }
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
              if (_isProcessingOfflinePayment) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawValue = barcode.rawValue;
                if (rawValue != null) {
                  final uri = Uri.tryParse(rawValue);
                  // Détection d'un paiement hors ligne
                  if (uri != null && uri.scheme == 'virelo' && uri.host == 'offline_pay') {
                    final merchantId = uri.queryParameters['merchantId'] ?? 'UNKNOWN';
                    final amountStr = uri.queryParameters['amount'] ?? '0';
                    final amount = double.tryParse(amountStr) ?? 0.0;
                    
                    _handleOfflinePayment(merchantId, amount);
                    return;
                  }
                  
                  // Supposons que le QR contienne virelo://pay?phone=XXXX
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
          ),
          
          if (_isProcessingOfflinePayment)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Génération du paiement sécurisé...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleOfflinePayment(String merchantId, double amount) async {
    if (!mounted) return;
    setState(() {
      _isProcessingOfflinePayment = true;
    });

    try {
      await _offlineCryptoService.initializeKeys();
      
      final authService = AuthService(ApiClient());
      final clientId = await authService.getUserId();
      
      if (clientId == null || clientId.isEmpty) {
        throw Exception("Vous devez être connecté pour effectuer un paiement hors ligne.");
      }

      final payload = await _offlineCryptoService.generateSignedPayload(
        clientId: clientId,
        merchantId: merchantId,
        amount: amount,
      );

      if (mounted) {
        setState(() {
          _isProcessingOfflinePayment = false;
        });
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ShowOfflineProofPage(
              beneficiaryName: "Marchand $merchantId",
              amount: amount.toString(),
              signedPayload: jsonEncode(payload.toJson()),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur hors ligne: $e')),
        );
        setState(() {
          _isProcessingOfflinePayment = false;
        });
      }
    }
  }
}
