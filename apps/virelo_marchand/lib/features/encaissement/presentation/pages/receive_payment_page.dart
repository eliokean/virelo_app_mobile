import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../../core/services/auto_sync_manager.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'package:virelo_core/crypto/offline_crypto_service.dart';

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
          // Decode amount from token for local UI and offline storage
          double amount = 0;
          Map<String, dynamic> payload = {};
          try {
            // Le QR Code est chiffré en AES-GCM par le client, on doit le déchiffrer
            final cryptoService = OfflineCryptoService(OfflineStorageService(AuthService(ApiClient())));
            final decryptedPayload = await cryptoService.decryptPayload(code);
            payload = decryptedPayload.toJson();
            amount = decryptedPayload.amount;
          } catch (e) {
            throw Exception("Format de jeton invalide: $e. Code scanné: $code");
          }

          try {
            // First check connectivity explicitly
            final connectivityResult = await (Connectivity().checkConnectivity());
            final isOffline = connectivityResult.contains(ConnectivityResult.none);

            if (isOffline) {
              // Direct to offline
              final offlineService = OfflineSyncService(ApiClient());
              await offlineService.saveTransaction(jsonEncode(payload), amount);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hors-ligne : paiement mis en attente de synchronisation.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                Navigator.pop(context);
              }
              
              AutoSyncManager().triggerSync();
              return;
            }

            // If online, proceed with normal API request
            final response = await ApiClient().dio.post(
              '/offline/sync', // Nouveau endpoint Dual Offline
              data: payload,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Paiement réussi ! $amount XOF encaissés.'),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context); // Go back to dashboard
            }
          } on DioException catch (e) {
            // If it's a network error, we save offline (Telecollecte)
            if (e.type == DioExceptionType.connectionTimeout || 
                e.type == DioExceptionType.receiveTimeout || 
                e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.unknown ||
                (e.type == DioExceptionType.badResponse && 
                 [404, 500, 502, 503, 504].contains(e.response?.statusCode))) {
              
              final offlineService = OfflineSyncService(ApiClient());
              await offlineService.saveTransaction(jsonEncode(payload), amount);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hors-ligne : paiement mis en attente de synchronisation.'),
                    backgroundColor: Colors.orange, // Orange for offline
                  ),
                );
                Navigator.pop(context); // Go back to dashboard
              }
              AutoSyncManager().triggerSync();
            } else {
              rethrow; // Rethrow other API errors (e.g., 400 Bad Request)
            }
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

