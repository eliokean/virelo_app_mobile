import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131517), // Premium Dark
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Historique',
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
          children: [
            _buildDateSection('Aujourd\'hui', [
              _buildTransactionItem('Client Anonyme', '+ 4 500 XOF', '14:32', true),
              _buildTransactionItem('Client Anonyme', '+ 12 000 XOF', '12:15', true),
              _buildTransactionItem('Remboursement', '- 2 500 XOF', '09:40', false),
            ]),
            const SizedBox(height: AppSpacing.xl),
            _buildDateSection('Hier', [
              _buildTransactionItem('Paiement NFC', '+ 8 000 XOF', '18:20', true),
              _buildTransactionItem('Client Anonyme', '+ 1 500 XOF', '13:05', true),
            ]),
            const SizedBox(height: AppSpacing.xl),
            _buildDateSection('Semaine Dernière', [
              _buildTransactionItem('Règlement Fournisseur', '- 45 000 XOF', 'Jeu. 14:00', false),
              _buildTransactionItem('Client Anonyme', '+ 25 000 XOF', 'Mer. 11:30', true),
              _buildTransactionItem('Client Anonyme', '+ 3 000 XOF', 'Mer. 08:15', true),
            ]),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection(String date, List<Widget> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md, left: AppSpacing.sm),
          child: Text(
            date,
            style: AppTextStyles.labelMedium.copyWith(
              color: const Color(0xFF8B93A8),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...transactions,
      ],
    );
  }

  Widget _buildTransactionItem(String title, String amount, String time, bool isIncome) {
    final color = isIncome ? const Color(0xFFB5E48C) : const Color(0xFFE29578);
    final icon = isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C3138)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF8B93A8)),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
