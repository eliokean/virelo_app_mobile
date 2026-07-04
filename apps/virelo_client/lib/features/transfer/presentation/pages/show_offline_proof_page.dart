import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'dart:async';

class ShowOfflineProofPage extends StatefulWidget {
  final String beneficiaryName;
  final String amount;
  final String signedPayload;

  const ShowOfflineProofPage({
    super.key,
    required this.beneficiaryName,
    required this.amount,
    required this.signedPayload,
  });

  @override
  State<ShowOfflineProofPage> createState() => _ShowOfflineProofPageState();
}

class _ShowOfflineProofPageState extends State<ShowOfflineProofPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Ferme la page automatiquement après 40 secondes
    _timer = Timer(const Duration(seconds: 40), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Preuve Hors Ligne',
                style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Demandez à ${widget.beneficiaryName} de scanner ce code pour recevoir les ${widget.amount} FCFA',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: widget.signedPayload,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const CircularProgressIndicator(color: Color(0xFFB5E48C)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'En attente du scan par le destinataire...',
                style: AppTextStyles.labelMedium.copyWith(color: const Color(0xFFB5E48C)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
