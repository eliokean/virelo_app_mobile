import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import '../../../history/presentation/pages/history_page.dart';
import 'package:intl/intl.dart';

class RecentActivityList extends StatelessWidget {
  final List<dynamic> activities;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const RecentActivityList({
    super.key,
    required this.activities,
    this.isLoading = false,
    this.onRefresh,
  });

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
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
    switch (type) {
      case 'c2c_transfer':
        return isNegative ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft;
      case 'recharge':
        return LucideIcons.plusCircle;
      case 'withdrawal':
        return LucideIcons.arrowUpRight;
      case 'offline':
        return LucideIcons.wifiOff;
      case 'b2c_payment':
      default:
        return LucideIcons.store;
    }
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
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
                onRefresh?.call();
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: CircularProgressIndicator(color: Color(0xFFB5E48C)),
            ),
          )
        else if (activities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'Aucune activité récente.',
              style: TextStyle(color: Color(0xFF8B93A8), fontSize: 14),
            ),
          )
        else
          ...activities.take(6).map((activity) {
            final isNegative = activity['is_negative'] ?? true;
            final dynamic rawAmount = activity['amount'] ?? 0;
            final amountNum = double.tryParse(rawAmount.toString()) ?? 0;
            final formattedAmount = NumberFormat('#,###', 'fr_FR').format(amountNum).replaceAll(',', ' ');
            final amountStr = '${isNegative ? '-' : '+'}$formattedAmount FCFA';

            final isPending = activity['uuid'] != null || activity['status'] == 'pending_merchant_validation';
            final subtitleText = isPending && activity['status'] == 'pending_merchant_validation' 
                ? 'En attente du marchand' 
                : (activity['subtitle'] ?? _formatDate(activity['date'] ?? activity['timestamp'] ?? ''));

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildActivityItem(
                icon: _getIconForType(activity['type'] ?? (activity['merchantId'] != null ? 'offline' : 'b2c_payment'), isNegative),
                title: activity['title'] ?? (activity['merchantId'] != null ? 'Paiement Hors Ligne' : 'Transaction'),
                subtitle: subtitleText,
                amount: amountStr,
                isNegative: isNegative,
                isPending: isPending,
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
            decoration: BoxDecoration(
              color: isPending ? const Color(0xFFFFF3E0) : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPending ? LucideIcons.clock : icon,
              size: 22,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isPending ? "En attente de synchro" : subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isPending ? const Color(0xFFE65100) : const Color(0xFF8B93A8),
                    fontWeight: isPending ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
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
