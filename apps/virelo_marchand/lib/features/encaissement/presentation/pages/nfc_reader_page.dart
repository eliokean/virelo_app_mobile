import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_core/nfc/nfc_payment_service.dart';
import 'package:virelo_core/crypto/offline_crypto_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/offline_sync/offline_authorization_payload.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../../core/services/auto_sync_manager.dart';

class NfcReaderPage extends StatefulWidget {
  const NfcReaderPage({Key? key}) : super(key: key);

  @override
  _NfcReaderPageState createState() => _NfcReaderPageState();
}

class _NfcReaderPageState extends State<NfcReaderPage> {
  bool _isProcessing = false;
  late final NfcPaymentService _nfcService;

  @override
  void initState() {
    super.initState();
    final offlineStorage = OfflineStorageService(AuthService(ApiClient()));
    _nfcService = NfcPaymentService(OfflineCryptoService(offlineStorage));
    _startNfcSession();
  }

  void _startNfcSession() async {
    await _nfcService.startListeningForPayment(
      (OfflineAuthorizationPayload payload) async {
        // Tag reçu !
        if (mounted) setState(() => _isProcessing = true);
        await _processPayload(payload);
      },
      (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
        }
      }
    );
  }

  Future<void> _processPayload(OfflineAuthorizationPayload payload) async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      if (isOffline) {
        // Direct to offline
        final offlineService = OfflineSyncService(ApiClient());
        // Dans ce contexte, "code" est le JSON du payload. Le TPE l'enregistre en format brut
        // pour la synchronisation
        final jsonString = jsonEncode(payload.toJson());
        await offlineService.saveTransaction(jsonString, payload.amount);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hors-ligne : paiement NFC mis en attente.'),
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
        '/offline/sync',
        data: payload.toJson(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paiement NFC réussi ! ${response.data['amount']} XOF encaissés.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de traitement NFC : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _nfcService.stopListening();
    super.dispose();
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
          'Sans Contact (NFC)',
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing) ...[
              const CircularProgressIndicator(color: AppColors.accent),
              const SizedBox(height: 24),
              Text(
                'Traitement en cours...',
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
              )
            ] else ...[
              const Icon(Icons.contactless, size: 100, color: AppColors.accent),
              const SizedBox(height: 32),
              Text(
                'Approchez le téléphone du client',
                style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Attente du signal NFC...',
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
              )
            ]
          ],
        ),
      ),
    );
  }
}
