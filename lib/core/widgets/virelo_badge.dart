import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../constants/app_spacing.dart';

enum BadgeVariant { success, warning, error, info, offline }

class VireloBadge extends StatelessWidget {
  final String  label;
  final BadgeVariant variant;

  const VireloBadge({super.key, required this.label, required this.variant});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      BadgeVariant.success => (AppColors.successMuted,  AppColors.success),
      BadgeVariant.warning => (AppColors.warningMuted,  AppColors.warning),
      BadgeVariant.error   => (AppColors.errorMuted,    AppColors.error),
      BadgeVariant.info    => (AppColors.infoMuted,     AppColors.info),
      BadgeVariant.offline => (AppColors.warningMuted,  AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter', // Note: could use GoogleFonts.inter if explicitly imported, keeping simple here
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
