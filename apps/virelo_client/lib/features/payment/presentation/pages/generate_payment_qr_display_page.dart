import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_primary_button.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/offline_sync/offline_authorization_payload.dart';
import 'package:virelo_core/crypto/offline_crypto_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/nfc/nfc_payment_service.dart';

import 'package:virelo_core/nfc/virelo_hce_client.dart';

class GeneratePaymentQrDisplayPage extends StatefulWidget {
  final double amount;
  final String token; // Le token obfusqué pour le QR
  final OfflineAuthorizationPayload payload; // Le payload complet pour le NFC

  const GeneratePaymentQrDisplayPage({
    super.key,
    required this.amount,
    required this.token,
    required this.payload,
  });

  @override
  State<GeneratePaymentQrDisplayPage> createState() => _GeneratePaymentQrDisplayPageState();
}

class _GeneratePaymentQrDisplayPageState extends State<GeneratePaymentQrDisplayPage> {
  Timer? _timer;
  bool _isProcessed = false;

  @override
  void initState() {
    super.initState();
    // Active l'émulation de carte NFC sans contact (HCE) pour transmission instantanée
    VireloHceClient.setPayload(widget.token);
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    VireloHceClient.clearPayload();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final response = await ApiClient().dio.post(
          '/transactions/check-token',
          data: {'token': widget.token},
        );
        
        if (response.data['status'] == 'processed') {
          _timer?.cancel();
          if (mounted) {
            setState(() {
              _isProcessed = true;
            });
            
            // Wait a bit to show the success animation then pop
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });
          }
        }
      } catch (e) {
        // Ignore errors during polling, we'll just try again on the next tick
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _isProcessed ? _buildSuccessView() : _buildQrView(),
          ),
        ),
      ),
    );
  }

  Widget _buildQrView() {
    return Column(
      key: const ValueKey('qr_view'),
      children: [
        const Spacer(flex: 1),
        Text(
          'Paiement de',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${widget.amount} FCFA',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        
        // QR Code Container
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              QrImageView(
                data: widget.token,
                version: QrVersions.auto,
                size: 250.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Présentez ce code au marchand',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.xl),

        // NFC BUTTON
        OutlinedButton.icon(
          onPressed: _startNfcTransmission,
          icon: const Icon(Icons.contactless),
          label: const Text('Approcher du TPE (NFC)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        const Spacer(flex: 2),
        VireloPrimaryButton(
          label: 'Terminé',
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  void _startNfcTransmission() async {
    final offlineStorage = OfflineStorageService(AuthService(ApiClient()));
    final nfcService = NfcPaymentService(OfflineCryptoService(offlineStorage));
    
    // Show a bottom sheet to tell the user to hold phone near TPE
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          height: 250,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.contactless, size: 64, color: AppColors.accent),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Approchez votre téléphone du TPE',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    );

    await nfcService.sendPaymentPayload(
      widget.payload,
      () {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement transmis avec succès !')));
      },
      (error) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
      }
    );
  }

  Widget _buildSuccessView() {
    return Center(
      key: const ValueKey('success_view'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
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
            'Paiement réussi !',
            style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Le marchand a bien encaissé ${widget.amount} FCFA.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
