import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../history/presentation/pages/history_page.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activité récente',
              style: AppTextStyles.labelLarge.copyWith(
                color: const Color(0xFF161A22),
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(
                LucideIcons.arrowRight,
                size: 20,
                color: Color(0xFF8B93A8),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildActivityItem(
          icon: LucideIcons.dribbble,
          title: 'Dribbble',
          subtitle: 'Hier',
          amount: '-\$15',
          isNegative: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildActivityItem(
          icon: LucideIcons.arrowDownLeft,
          title: 'Hannah Jones',
          subtitle: 'Il y a 2h',
          amount: '+\$200',
          isNegative: false,
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isNegative,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5), // Light grey
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: const Color(0xFF161A22),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: const Color(0xFF161A22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFF8B93A8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTextStyles.labelLarge.copyWith(
              color: isNegative ? const Color(0xFF161A22) : const Color(0xFF8DC973),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
