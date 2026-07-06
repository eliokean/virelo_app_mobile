import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_primary_button.dart';
import 'receive_payment_page.dart';

class DisplayInvoiceQrPage extends StatelessWidget {
  final int merchantId;
  final String merchantName;
  final double amount;

  const DisplayInvoiceQrPage({
    super.key,
    required this.merchantId,
    required this.merchantName,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    // Le QR code contient les infos pour le client
    final invoiceData = jsonEncode({
      'type': 'invoice',
      'merchantId': merchantId.toString(),
      'merchantName': merchantName,
      'amount': amount,
    });

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
                'Facture à payer',
                style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Demandez au client de scanner ce code pour régler $amount FCFA',
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
                  data: invoiceData,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: VireloPrimaryButton(
                  label: 'Scanner la preuve client',
                  icon: LucideIcons.qrCode,
                  onPressed: () {
                    // Aller vers la page pour scanner la preuve du client
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReceivePaymentPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
