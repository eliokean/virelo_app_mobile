import 'package:flutter/material.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MerchantBalanceCard extends StatelessWidget {
  final String balance;
  final bool isLoading;
  final VoidCallback? onWithdrawal;
  
  const MerchantBalanceCard({
    super.key,
    required this.balance,
    this.isLoading = false,
    this.onWithdrawal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Statut Boutique
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF161A22),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.store, color: Color(0xFFB5E48C), size: 14),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Caisse Principale',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Amount
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'FCFA ',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: const Color(0xFF161A22),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                isLoading 
                  ? const SizedBox(
                      height: 40, 
                      width: 40, 
                      child: CircularProgressIndicator(color: Color(0xFF161A22))
                    )
                  : Text(
                      _formatBalance(balance),
                      style: AppTextStyles.displayLarge.copyWith(
                        color: const Color(0xFF161A22),
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (onWithdrawal != null)
            ElevatedButton.icon(
              onPressed: onWithdrawal,
              icon: const Icon(LucideIcons.arrowUpRight, size: 18, color: Colors.white),
              label: const Text('Retirer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF161A22),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  String _formatBalance(String bal) {
    try {
      final doubleValue = double.parse(bal);
      final intValue = doubleValue.toInt();
      final stringValue = intValue.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < stringValue.length; i++) {
        if (i > 0 && (stringValue.length - i) % 3 == 0) buffer.write(' ');
        buffer.write(stringValue[i]);
      }
      return buffer.toString();
    } catch (e) {
      return bal;
    }
  }
}
