import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';

class WalletHeader extends StatelessWidget {
  const WalletHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salut Ben !',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF161A22),
                  ),
                ),
                Text(
                  'Bienvenue dans votre\nportefeuille multi-devises',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF4A5168),
                  ),
                ),
              ],
            ),
          ),
          _buildIconButton(LucideIcons.grid),
          const SizedBox(width: AppSpacing.sm),
          _buildIconButton(LucideIcons.bell),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: const Color(0xFF161A22),
      ),
    );
  }
}
