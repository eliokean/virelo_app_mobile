import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/transaction_details_bottom_sheet.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/merchant_service.dart';
import '../../../../core/services/offline_sync_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final MerchantService _merchantService;
  late final OfflineSyncService _offlineSyncService;

  bool _isLoading = true;
  List<dynamic> _transactions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _merchantService = MerchantService(ApiClient());
    _offlineSyncService = OfflineSyncService(ApiClient());
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final serverTx = await _merchantService.getTransactions(perPage: 50);
      
      // Récupérer également les transactions en attente hors ligne si disponibles
      await _offlineSyncService.getPendingCount();

      if (mounted) {
        setState(() {
          _transactions = serverTx;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) {
      return "Aujourd'hui";
    } else if (txDate == yesterday) {
      return "Hier";
    } else if (now.difference(txDate).inDays < 7) {
      return DateFormat('EEEE d MMMM', 'fr_FR').format(date);
    } else {
      return DateFormat('d MMMM yyyy', 'fr_FR').format(date);
    }
  }

  Map<String, List<dynamic>> _groupTransactions() {
    final Map<String, List<dynamic>> grouped = {};

    for (final tx in _transactions) {
      DateTime date;
      try {
        final dateStr = tx['created_at'] ?? tx['date'] ?? tx['timestamp'];
        date = dateStr != null ? DateTime.parse(dateStr.toString()) : DateTime.now();
      } catch (_) {
        date = DateTime.now();
      }

      final header = _formatDateHeader(date);
      if (!grouped.containsKey(header)) {
        grouped[header] = [];
      }
      grouped[header]!.add(tx);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = _groupTransactions();

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
          'Historique des Ventes',
          style: AppTextStyles.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 20),
            onPressed: _fetchTransactions,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFB5E48C),
          backgroundColor: const Color(0xFF1A1D21),
          onRefresh: _fetchTransactions,
          child: _buildBody(groupedTransactions),
        ),
      ),
    );
  }

  Widget _buildBody(Map<String, List<dynamic>> groupedTransactions) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB5E48C)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: Color(0xFFE29578), size: 48),
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: _fetchTransactions,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF131517),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D21),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF2C3138)),
                  ),
                  child: const Icon(LucideIcons.receipt, color: Color(0xFF8B93A8), size: 40),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Aucune transaction trouvée',
                  style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Vos prochains encaissements apparaîtront ici.',
                  style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF8B93A8)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
      children: [
        ...groupedTransactions.entries.expand((entry) {
          final header = entry.key;
          final transactions = entry.value;

          return [
            _buildDateSection(header, transactions.map((tx) {
              final double amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
              final formattedAmount = NumberFormat('#,###', 'fr_FR').format(amount).replaceAll(',', ' ');
              final amountStr = '+ $formattedAmount FCFA';

              final title = tx['title'] ?? 'Client Anonyme';
              final subtitle = tx['subtitle'] ?? 'Paiement Marchand';
              
              DateTime txDate;
              try {
                final dateStr = tx['created_at'] ?? tx['date'] ?? tx['timestamp'];
                txDate = dateStr != null ? DateTime.parse(dateStr.toString()) : DateTime.now();
              } catch (_) {
                txDate = DateTime.now();
              }
              final timeStr = DateFormat('HH:mm').format(txDate);

              final statusStr = tx['status']?.toString().toLowerCase();
              final isPending = statusStr == 'pending_merchant_validation' || 
                                statusStr == 'pending_merchant_sync' || 
                                statusStr == 'pending';

              return _buildTransactionItem(
                title: title,
                subtitle: isPending ? "En attente de télécollecte" : subtitle,
                amount: amountStr,
                time: timeStr,
                isPending: isPending,
                onTap: () {
                  TransactionDetailsBottomSheet.show(context, tx);
                },
              );
            }).toList()),
            const SizedBox(height: AppSpacing.lg),
          ];
        }),
        const SizedBox(height: AppSpacing.xxl),
      ],
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

  Widget _buildTransactionItem({
    required String title,
    required String subtitle,
    required String amount,
    required String time,
    bool isPending = false,
    VoidCallback? onTap,
  }) {
    const color = Color(0xFFB5E48C);
    final icon = isPending ? LucideIcons.clock : LucideIcons.arrowDownLeft;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isPending ? const Color(0xFFE65100).withValues(alpha: 0.3) : const Color(0xFF2C3138)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPending ? const Color(0xFFFFF3E0).withValues(alpha: 0.15) : color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon, 
                color: isPending ? const Color(0xFFE65100) : color, 
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$time • $subtitle',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isPending ? const Color(0xFFE65100) : const Color(0xFF8B93A8),
                      fontWeight: isPending ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: AppTextStyles.labelLarge.copyWith(
                color: isPending ? const Color(0xFFE65100) : color, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
