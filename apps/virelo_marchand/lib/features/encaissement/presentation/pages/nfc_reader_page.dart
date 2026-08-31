import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/nfc/nfc_payment_service.dart';
import 'package:virelo_core/crypto/offline_crypto_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/offline_sync/offline_authorization_payload.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
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
  double _receivedAmount = 0;
  late final NfcPaymentService _nfcService;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    final offlineStorage = OfflineStorageService(AuthService(ApiClient()));
    _nfcService = NfcPaymentService(OfflineCryptoService(offlineStorage));
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startNfcSession();
  }

  void _startNfcSession() async {
    await _nfcService.startListeningForPayment(
      (OfflineAuthorizationPayload payload) async {
        HapticFeedback.vibrate();
        if (mounted) setState(() => _isProcessing = true);
        await _processPayload(payload);
      },
      (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error),
          );
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

      _receivedAmount = payload.amount;

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
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } on DioException catch (e) {
      if (mounted) {
        String errorMsg = 'Erreur serveur (${e.response?.statusCode ?? 'inconnu'})';
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          errorMsg = e.response!.data['message'].toString();
        } else if (e.response?.data is Map && e.response?.data['error'] != null) {
          errorMsg = e.response!.data['error'].toString();
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMsg = e.message!;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de traitement NFC : $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _nfcService.stopListening();
    super.dispose();
  }

  String _formatAmount(double amt) {
    final intAmount = amt.toInt();
    final str = intAmount.toString();
    final result = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result.write(' ');
      result.write(str[i]);
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    final displayAmount = widget.amount != null && widget.amount! > 0
        ? '${_formatAmount(widget.amount!)} FCFA'
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF161A22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'TPE Sans Contact (NFC)',
          style: AppTextStyles.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _isSuccess
                ? _buildSuccessView()
                : _buildNfcListenerView(displayAmount),
          ),
        ),
      ),
    );
  }

  Widget _buildNfcListenerView(String? displayAmount) {
    return Column(
      key: const ValueKey('listener_view'),
      children: [
        const Spacer(flex: 1),

        if (displayAmount != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Montant à encaisser',
              style: AppTextStyles.labelMedium.copyWith(color: Colors.white70),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            displayAmount,
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Mode Débit Direct',
              style: AppTextStyles.labelMedium.copyWith(color: Colors.white70),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'En attente du client',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],

        const Spacer(flex: 2),

        // Ondes d'animation NFC
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Onde 3
                  Opacity(
                    opacity: (1.0 - _waveController.value).clamp(0.0, 1.0),
                    child: Container(
                      width: 140 + (_waveController.value * 120),
                      height: 140 + (_waveController.value * 120),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  // Onde 2
                  Opacity(
                    opacity: (1.0 - (_waveController.value * 0.7)).clamp(0.0, 1.0),
                    child: Container(
                      width: 140 + (_waveController.value * 70),
                      height: 140 + (_waveController.value * 70),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.5),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                  // Cercle central avec icône sans contact
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isProcessing
                          ? const SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.accent,
                              ),
                            )
                          : const Icon(
                              Icons.contactless,
                              size: 70,
                              color: AppColors.accent,
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const Spacer(flex: 2),

        // Carte d'instructions NFC
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: const Color(0xFF222731),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isProcessing ? 'Lecture NFC en cours...' : 'Récepteur NFC Actif',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Approchez le smartphone du client contre votre téléphone pour encaisser instantanément.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),

        const Spacer(flex: 1),

        // Bouton Annuler
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(
              'Fermer le terminal',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white70),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildSuccessView() {
    final finalAmount = _receivedAmount > 0 
        ? '${_formatAmount(_receivedAmount)} FCFA'
        : (widget.amount != null ? '${_formatAmount(widget.amount!)} FCFA' : 'Paiement');

    return Center(
      key: const ValueKey('success_view'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle2,
              color: AppColors.success,
              size: 80,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Encaissement NFC réussi !',
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vous avez encaissé $finalAmount avec succès.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
