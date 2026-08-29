import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_spacing.dart';

class TransactionDetailsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailsBottomSheet({
    super.key,
    required this.transaction,
  });

  static void show(BuildContext context, Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailsBottomSheet(transaction: transaction),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Date inconnue';
    try {
      final date = DateTime.parse(dateValue.toString());
      return DateFormat('dd MMM yyyy à HH:mm').format(date);
    } catch (_) {
      return dateValue.toString();
    }
  }

  String _formatReference(String ref) {
    if (ref.length <= 8) return ref.toUpperCase();
    // Si c'est un UUID complet (ex: 123e4567-e89b-12d3-a456-426614174000)
    if (ref.contains('-') && ref.length >= 32) {
      final parts = ref.split('-');
      return 'VRL-${parts.first.toUpperCase()}';
    }
    // Sinon on prend les 8 premiers caractères
    return 'VRL-${ref.substring(0, 8).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final isNegative = transaction['is_negative'] ?? true;
    final dynamic rawAmount = transaction['amount'] ?? 0;
    final amountNum = double.tryParse(rawAmount.toString()) ?? 0;
    final formattedAmount = NumberFormat('#,###', 'fr_FR').format(amountNum).replaceAll(',', ' ');
    final amountStr = '${isNegative ? '-' : '+'}$formattedAmount FCFA';
    
    final title = transaction['title'] ?? (transaction['merchantId'] != null ? 'Paiement Hors Ligne' : 'Transaction');
    final statusStr = transaction['status']?.toString().toLowerCase() ?? 'completed';
    final isPending = statusStr == 'pending_merchant_validation' || 
                      statusStr == 'pending_merchant_sync' || 
                      statusStr == 'pending';
    
    final date = transaction['date'] ?? transaction['timestamp'] ?? transaction['created_at'];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poignée
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E4E8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // En-tête
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isNegative ? const Color(0xFF161A22) : AppColors.accent).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNegative ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                size: 32,
                color: isNegative ? const Color(0xFF161A22) : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(color: const Color(0xFF161A22)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            amountStr,
            textAlign: TextAlign.center,
            style: AppTextStyles.displaySmall.copyWith(
              color: isNegative ? const Color(0xFF161A22) : const Color(0xFF8DC973),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Détails
          _buildDetailRow('Date', _formatDate(date)),
          _buildDetailRow('Statut', isPending ? 'En attente' : 'Complété', 
            statusColor: isPending ? const Color(0xFFE65100) : AppColors.accent),
          if (transaction['reference'] != null || transaction['id'] != null)
            _buildDetailRow('Référence', _formatReference(transaction['reference']?.toString() ?? transaction['id'].toString())),
          if (transaction['type'] != null)
            _buildDetailRow('Type', transaction['type'].toString().toUpperCase()),

          const SizedBox(height: AppSpacing.xxl),
          
          // Bouton Fermer
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F2F5),
                foregroundColor: const Color(0xFF161A22),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: Text(
                'Fermer',
                style: AppTextStyles.button.copyWith(
                  color: const Color(0xFF161A22),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF8B93A8)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.labelLarge.copyWith(
                color: statusColor ?? const Color(0xFF161A22),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
