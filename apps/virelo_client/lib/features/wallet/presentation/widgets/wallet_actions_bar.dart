import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import '../../../deposit/presentation/pages/deposit_amount_page.dart';
import '../../../transfer/presentation/pages/transfer_contact_page.dart';
import '../../../payment/presentation/pages/scan_invoice_page.dart';
import '../../../payment/presentation/pages/generate_payment_qr_amount_page.dart';
import 'package:virelo_design_system/theme/app_colors.dart';

class WalletActionsBar extends StatelessWidget {
  final VoidCallback? onRefresh;
  const WalletActionsBar({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Envoyer',
              icon: LucideIcons.arrowRightLeft,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransferContactPage()),
                );
                onRefresh?.call();
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _buildScanButton(context),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildActionButton(
              label: 'Recharger',
              icon: LucideIcons.coins,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DepositAmountPage()),
                );
                if (result == true) {
                  onRefresh?.call();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF2D2E33),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return Container(
      height: 72,
      width: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPaymentOptions(context),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.scanLine,
                color: Color(0xFF161A22),
                size: 26,
              ),
              const SizedBox(height: 2),
              Text(
                'Payer',
                style: AppTextStyles.labelSmall.copyWith(
                  color: const Color(0xFF161A22),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Mode de paiement',
                    style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Choisissez comment vous souhaitez régler votre achat',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Option 1 : NFC Sans Contact Direct
                  Material(
                    color: const Color(0xFF2C3138),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GeneratePaymentQrAmountPage()),
                        );
                        onRefresh?.call();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.contactless, color: AppColors.accent, size: 28),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sans Contact (NFC)',
                                    style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Saisir le montant et approcher du terminal',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, color: Colors.white38),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Option 2 : Scanner la facture QR Code
                  Material(
                    color: const Color(0xFF2C3138),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScanInvoicePage()),
                        );
                        onRefresh?.call();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.qrCode, color: Color(0xFF6C63FF), size: 28),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scanner la Facture (QR)',
                                    style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Scanner le QR code affiché par le marchand',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, color: Colors.white38),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
