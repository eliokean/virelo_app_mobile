import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_spacing.dart';

class VireloActionButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback? onPressed;
  final Color?   iconColor;

  const VireloActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Icon(
              icon,
              size: 22,
              color: iconColor ?? AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          )),
        ],
      ),
    );
  }
}
