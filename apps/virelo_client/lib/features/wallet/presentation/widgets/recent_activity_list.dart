import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import '../../../history/presentation/pages/history_page.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RecentActivityList extends StatelessWidget {
  final List<dynamic> activities;
  final bool isLoading;

  const RecentActivityList({
    super.key,
    required this.activities,
    this.isLoading = false,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return "Aujourd'hui, ${DateFormat('HH:mm').format(date)}";
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        return "Hier, ${DateFormat('HH:mm').format(date)}";
      }
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }



  IconData _getIconForType(String type, bool isNegative) {
    if (type == 'c2c_transfer' || type == 'offline') {
      return isNegative ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft;
    }
    return LucideIcons.shoppingBag;
  }

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
        if (isLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFFB5E48C)))
        else if (activities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text('Aucune activité récente.'),
          )
        else
          ...activities.take(5).map((activity) { // On prend les 5 plus récentes max
            final isNegative = activity['is_negative'] ?? true; // Défaut débit (scan paiement)
            final amountStr = '${isNegative ? '-' : '+'}${activity['amount']} FCFA';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildActivityItem(
                icon: _getIconForType(activity['type'] ?? 'offline', isNegative),
                title: activity['title'] ?? (activity['merchantId'] != null ? 'Paiement Hors Ligne' : 'Transaction'),
                subtitle: _formatDate(activity['date'] ?? activity['timestamp'] ?? DateTime.now().toIso8601String()),
                amount: amountStr,
                isNegative: isNegative,
                isPending: activity['uuid'] != null, // C'est une transaction offline si UUID est présent
              ),
            );
          }),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isNegative,
    bool isPending = false,
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
            decoration: BoxDecoration(
              color: isPending ? const Color(0xFFFFF3E0) : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPending ? LucideIcons.clock : icon,
              size: 24,
              color: isPending ? const Color(0xFFE65100) : const Color(0xFF161A22),
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
                  isPending ? "En attente de synchro" : subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isPending ? const Color(0xFFE65100) : const Color(0xFF8B93A8),
                    fontWeight: isPending ? FontWeight.w600 : FontWeight.normal,
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
