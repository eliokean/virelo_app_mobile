import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:dio/dio.dart';

class ReceiveOfflinePage extends StatefulWidget {
  const ReceiveOfflinePage({super.key});

  @override
  State<ReceiveOfflinePage> createState() => _ReceiveOfflinePageState();
}

class _ReceiveOfflinePageState extends State<ReceiveOfflinePage> {
  final MobileScannerController _cameraController = MobileScannerController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiClient _apiClient = ApiClient();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String rawData) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final payload = jsonDecode(rawData);
      
      // Verification factice de la signature pour le PoC
      if (payload['signature'] != null && payload['amount'] != null) {
        
        // Tentative de synchronisation immédiate si réseau disponible
        bool syncSuccess = false;
        try {
          await _apiClient.dio.post('/offline/sync', data: {
            'payload': rawData,
            'signature': payload['signature'],
          });
          syncSuccess = true;
        } catch (e) {
          // Erreur réseau ou API
        }

        // Sauvegarde locale du reçu
        final existingReceiptsStr = await _storage.read(key: 'offline_receipts') ?? '[]';
        final List<dynamic> receipts = jsonDecode(existingReceiptsStr);
        receipts.add(payload);
        await _storage.write(key: 'offline_receipts', value: jsonEncode(receipts));

        if (mounted) {
          _showSuccess(payload['amount'].toString(), syncSuccess);
        }
      } else {
        throw Exception('Payload invalide');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code Invalide ou corrompu')),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccess(String amount, bool synced) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161A22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB5E48C).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.checkCircle, color: Color(0xFFB5E48C), size: 48),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Paiement Sécurisé',
              style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              synced
                  ? 'Vous avez reçu $amount FCFA.\nLa transaction a été synchronisée avec succès !'
                  : 'Vous avez reçu $amount FCFA.\nLa transaction a été validée hors ligne et sera synchronisée dès votre retour réseau.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB5E48C),
                  foregroundColor: const Color(0xFF161A22),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Terminer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
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
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                  break;
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
                  const Icon(LucideIcons.scan, color: Colors.white, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Encaissement Hors Ligne',
                    style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Scannez le QR Code de Preuve présenté par l\'expéditeur.',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
