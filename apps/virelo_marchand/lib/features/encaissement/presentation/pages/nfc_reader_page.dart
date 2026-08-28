import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/virelo_design_system.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
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
  final double? amount;

  const NfcReaderPage({Key? key, this.amount}) : super(key: key);

  @override
  _NfcReaderPageState createState() => _NfcReaderPageState();
}

class _NfcReaderPageState extends State<NfcReaderPage> with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  bool _isSuccess = false;
  late final NfcPaymentService _nfcService;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    final offlineStorage = OfflineStorageService(AuthService(ApiClient()));
    _nfcService = NfcPaymentService(OfflineCryptoService(offlineStorage));
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startNfcSession();
  }

  void _startNfcSession() async {
    await _nfcService.startListeningForPayment(
      (OfflineAuthorizationPayload payload) async {
        // Retour haptique fort dès détection de l'antenne NFC !
        HapticFeedback.vibrate();
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
      if (payload.validUntil.isNotEmpty) {
        final validUntilDate = DateTime.tryParse(payload.validUntil);
        if (validUntilDate != null && DateTime.now().isAfter(validUntilDate.add(const Duration(seconds: 30)))) {
          throw Exception("Paiement NFC rejeté : le jeton a expiré !");
        }
      }

      final connectivityResult = await (Connectivity().checkConnectivity());
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      if (isOffline) {
        final offlineService = OfflineSyncService(ApiClient());
        final jsonString = jsonEncode(payload.toJson());
        await offlineService.saveTransaction(jsonString, payload.amount);

        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isSuccess = true;
          });
          HapticFeedback.heavyImpact();
          VireloInAppNotification.show(
            title: 'Paiement Sans Contact NFC',
            message: 'Client $clientId débité avec succès (Hors-ligne).',
            amount: payload.amount.toInt().toString(),
            type: InAppNotificationType.payment,
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context);
        }
        AutoSyncManager().triggerSync();
        return;
      }

      final response = await ApiClient().dio.post(
        '/offline/sync',
        data: payload.toJson(),
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
        HapticFeedback.heavyImpact();
        VireloInAppNotification.show(
          title: 'Paiement Sans Contact NFC',
          message: 'Client $clientId débité avec succès.',
          amount: payload.amount.toInt().toString(),
          type: InAppNotificationType.payment,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
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
    _pulseController.dispose();
    _nfcService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayAmount = widget.amount != null && widget.amount! > 0
        ? '${widget.amount!.toInt()} FCFA'
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF161A22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'TPE Sans Contact (NFC)',
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              SizedBox(height: AppSpacing.lg),
              if (displayAmount != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C3138),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Montant à encaisser',
                        style: AppTextStyles.labelSmall.copyWith(color: Colors.white60),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayAmount,
                        style: AppTextStyles.displayLarge.copyWith(color: AppColors.accent, fontSize: 32),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),

              // Animation d'onde ou Succès
              if (_isSuccess) ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.checkCircle2, size: 90, color: AppColors.accent),
                ),
                SizedBox(height: AppSpacing.xl),
                Text(
                  'Encaissé avec succès !',
                  style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ] else if (_isProcessing) ...[
                const CircularProgressIndicator(color: AppColors.accent, strokeWidth: 3),
                SizedBox(height: AppSpacing.xl),
                Text(
                  'Traitement du paiement en cours...',
                  style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                ),
              ] else ...[
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140 + (_pulseController.value * 60),
                          height: 140 + (_pulseController.value * 60),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withOpacity(0.2 * (1 - _pulseController.value)),
                          ),
                        ),
                        Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent,
                          ),
                          child: const Icon(Icons.contactless, size: 64, color: Color(0xFF161A22)),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: AppSpacing.huge),
                Text(
                  'Approchez la carte ou le téléphone',
                  style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Placer le dos de l\'appareil contre le terminal TPE',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
              ],

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
