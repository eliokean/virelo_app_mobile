import 'package:flutter/material.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';

class BalanceHeroCard extends StatelessWidget {
  final String balance;
  final bool isLoading;
  
  const BalanceHeroCard({
    super.key,
    required this.balance,
    this.isLoading = false,
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
          // Currency Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF161A22),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇨🇮', style: TextStyle(fontSize: 16, height: 1)),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.currency_exchange, color: Colors.white, size: 14),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'FCFA (XOF)',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
              ],
            ),
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
          // Variation Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8DC973), // Green from the image
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  '+2.10%',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Solde multi-devises estimé, sécurisé',
            style: AppTextStyles.labelSmall.copyWith(
              color: const Color(0xFF4A5168),
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
