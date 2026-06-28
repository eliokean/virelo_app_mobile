import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF161A22)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Activité récente',
            style: AppTextStyles.headlineMedium.copyWith(color: const Color(0xFF161A22)),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            _buildDateHeader('Aujourd\'hui'),
            const SizedBox(height: AppSpacing.md),
            _buildActivityItem(
              icon: LucideIcons.dribbble,
              title: 'Dribbble',
              subtitle: 'Abonnement',
              amount: '-\$15',
              isNegative: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildActivityItem(
              icon: LucideIcons.arrowDownLeft,
              title: 'Hannah Jones',
              subtitle: 'Reçu',
              amount: '+\$200',
              isNegative: false,
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildDateHeader('Hier'),
            const SizedBox(height: AppSpacing.md),
            _buildActivityItem(
              icon: LucideIcons.shoppingCart,
              title: 'Carrefour',
              subtitle: 'Achat',
              amount: '-15 000 FCFA',
              isNegative: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildActivityItem(
              icon: LucideIcons.arrowUpRight,
              title: 'Momo Transfert',
              subtitle: 'Envoyé',
              amount: '-5 000 FCFA',
              isNegative: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        color: const Color(0xFF8B93A8),
        fontWeight: FontWeight.bold,
      ),
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
            color: Colors.black.withValues(alpha: 0.02),
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
