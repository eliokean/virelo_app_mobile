import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import '../../../deposit/presentation/pages/deposit_amount_page.dart';
import '../../../transfer/presentation/pages/transfer_contact_page.dart';
import '../../../payment/presentation/pages/generate_payment_qr_amount_page.dart';

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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransferContactPage()),
                );
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GeneratePaymentQrAmountPage()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.qrCode,
                color: Color(0xFF161A22),
                size: 28,
              ),
              const SizedBox(height: 2),
              Text(
                'NFC',
                style: AppTextStyles.labelSmall.copyWith(
                  color: const Color(0xFF161A22),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
