import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_primary_button.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/offline_sync/offline_authorization_payload.dart';
import 'package:virelo_core/nfc/virelo_hce_client.dart';

class NfcTapToPayDisplayPage extends StatefulWidget {
  final double amount;
  final String token;
  final OfflineAuthorizationPayload payload;

  const NfcTapToPayDisplayPage({
    super.key,
    required this.amount,
    required this.token,
    required this.payload,
  });

  @override
  State<NfcTapToPayDisplayPage> createState() => _NfcTapToPayDisplayPageState();
}

class _NfcTapToPayDisplayPageState extends State<NfcTapToPayDisplayPage> with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _isProcessed = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Active l'émulation de carte NFC sans contact (HCE) pour transmission instantanée
    VireloHceClient.setPayload(widget.token);
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController.dispose();
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
            
            // Attendre un instant puis fermer
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });
          }
        }
      } catch (e) {
        // Ignorer les erreurs pendant le polling
      }
    });
  }

  String get _formattedAmount {
    final intAmount = widget.amount.toInt();
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
    return Scaffold(
      backgroundColor: const Color(0xFF161A22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Text(
          'Paiement Sans Contact (NFC)',
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _isProcessed ? _buildSuccessView() : _buildNfcTapView(),
          ),
        ),
      ),
    );
  }

  Widget _buildNfcTapView() {
    return Column(
      key: const ValueKey('nfc_view'),
      children: [
        const Spacer(flex: 1),
        
        // Montant
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Montant autorisé',
            style: AppTextStyles.labelMedium.copyWith(color: Colors.white70),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$_formattedAmount FCFA',
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
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
                    child: const Center(
                      child: Icon(
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
                    'Émission NFC Active',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Approchez le dos de votre smartphone du terminal marchand (TPE) pour valider le paiement.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),

        const Spacer(flex: 1),

        // Bouton Annuler / Fermer
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(
              'Annuler le paiement',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white70),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
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
            'Paiement NFC réussi !',
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Le terminal a bien validé votre règlement de $_formattedAmount FCFA.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
