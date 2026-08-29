import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:virelo_design_system/widgets/transaction_details_bottom_sheet.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/services/wallet_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late WalletService _walletService;
  late OfflineStorageService _offlineStorage;

  final List<dynamic> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  bool _isOfflineMode = false;
  int _currentPage = 1;
  static const int _perPage = 10;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    final authService = AuthService(apiClient);
    _walletService = WalletService(apiClient, authService);
    _offlineStorage = OfflineStorageService(authService);

    _loadInitialHistory();
  }

  Future<void> _loadInitialHistory() async {
    // 1. Charger immédiatement le cache local pour un affichage instantané hors-ligne
    try {
      final cachedHistory = await _offlineStorage.getFullCachedHistory();
      if (cachedHistory.isNotEmpty && mounted) {
        setState(() {
          _transactions.clear();
          _transactions.addAll(cachedHistory);
          _isLoading = false;
        });
      }
    } catch (_) {}

    // 2. Tenter de récupérer les données à jour depuis le serveur
    try {
      final res = await _walletService.getHistory(page: 1, perPage: _perPage);
      final List<dynamic> serverData = (res['data'] as List<dynamic>?) ?? [];
      final bool hasMoreServer = res['has_more'] == true;

      // Sauvegarder dans le cache local et nettoyer les transactions hors-ligne synchronisées
      if (serverData.isNotEmpty) {
        await _offlineStorage.saveCachedServerTransactions(serverData);
      }

      final offlineTx = await _offlineStorage.getOfflineTransactions();
      final combined = <dynamic>[...offlineTx, ...serverData];

      if (mounted) {
        setState(() {
          _transactions.clear();
          _transactions.addAll(combined);
          _hasMore = hasMoreServer;
          _isLoading = false;
          _isOfflineMode = false;
          _errorMessage = null;
          _currentPage = 1;
        });
      }
    } catch (e) {
      debugPrint('==== ERREUR CHARGEMENT HISTORIQUE SERVEUR (OFFLINE): $e ====');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Si on a déjà des données en cache ou offline, on bascule en mode offline sans bloquer l'écran
          if (_transactions.isNotEmpty) {
            _isOfflineMode = true;
            _errorMessage = null;
          } else {
            _errorMessage = "Impossible de charger l'historique.";
          }
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    if (_isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connexion internet requise pour charger l'historique plus ancien."),
          backgroundColor: Color(0xFF161A22),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final res = await _walletService.getHistory(page: nextPage, perPage: _perPage);
      final List<dynamic> serverData = (res['data'] as List<dynamic>?) ?? [];
      final bool hasMoreServer = res['has_more'] == true;

      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _transactions.addAll(serverData);
          _hasMore = hasMoreServer;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Erreur lors du chargement des transactions suivantes"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  static const List<String> _frenchMonths = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
  ];

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) {
      return "Aujourd'hui";
    } else if (txDate == yesterday) {
      return "Hier";
    } else {
      final dayStr = date.day.toString().padLeft(2, '0');
      final monthStr = _frenchMonths[date.month - 1];
      if (date.year == now.year) {
        return '$dayStr $monthStr';
      } else {
        return '$dayStr $monthStr ${date.year}';
      }
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

  Map<String, List<dynamic>> _groupTransactionsByDate() {
    final Map<String, List<dynamic>> grouped = {};

    for (final tx in _transactions) {
      DateTime date;
      final rawDate = tx['date'] ?? tx['timestamp'] ?? tx['created_at'];
      if (rawDate != null) {
        date = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
      } else {
        date = DateTime.now();
      }

      final header = _getDateHeader(date);
      if (!grouped.containsKey(header)) {
        grouped[header] = [];
      }
      grouped[header]!.add(tx);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupTransactionsByDate();

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
            'Historique complet',
            style: AppTextStyles.headlineMedium.copyWith(
              color: const Color(0xFF161A22),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFB5E48C)),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenH),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.wifiOff, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _errorMessage!,
                            style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF8B93A8)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton.icon(
                            onPressed: _loadInitialHistory,
                            icon: const Icon(LucideIcons.refreshCw, size: 18),
                            label: const Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF161A22),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _transactions.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadInitialHistory,
                        color: const Color(0xFF161A22),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF0F0F0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.history, size: 36, color: Color(0xFF8B93A8)),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Aucune transaction enregistrée',
                                    style: AppTextStyles.labelLarge.copyWith(color: const Color(0xFF161A22)),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Vos opérations récentes apparaîtront ici.',
                                    style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF8B93A8)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInitialHistory,
                        color: const Color(0xFF161A22),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenH,
                            vertical: AppSpacing.md,
                          ),
                          children: [
                            // Bandeau mode hors ligne
                            if (_isOfflineMode)
                              Container(
                                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFFFCC80), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.wifiOff, size: 18, color: Color(0xFFE65100)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Mode hors ligne • Données en cache local',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: const Color(0xFFE65100),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            ...grouped.entries.expand((entry) {
                              final header = entry.key;
                              final items = entry.value;

                              return [
                                _buildDateHeader(header),
                                const SizedBox(height: AppSpacing.sm),
                                ...items.map((activity) {
                                  final isNegative = activity['is_negative'] ?? true;
                                  final dynamic rawAmount = activity['amount'] ?? 0;
                                  final amountNum = double.tryParse(rawAmount.toString()) ?? 0;
                                  final formattedAmount =
                                      NumberFormat('#,###', 'fr_FR').format(amountNum).replaceAll(',', ' ');
                                  final amountStr = '${isNegative ? '-' : '+'}$formattedAmount FCFA';

                                  final statusStr = activity['status']?.toString().toLowerCase();
                                  final isPending = statusStr == 'pending_merchant_validation' || 
                                                    statusStr == 'pending_merchant_sync' || 
                                                    statusStr == 'pending';
                                  final subtitleText = isPending
                                      ? (statusStr == 'pending_merchant_validation' 
                                          ? 'En attente du marchand' 
                                          : 'En attente de synchro')
                                      : (activity['subtitle'] ??
                                          _formatTime(activity['date'] ?? activity['timestamp']));

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: _buildActivityItem(
                                      icon: _getIconForType(
                                        activity['type'] ??
                                            (activity['merchantId'] != null ? 'offline' : 'b2c_payment'),
                                        isNegative,
                                      ),
                                      title: activity['title'] ??
                                          (activity['merchantId'] != null
                                              ? 'Paiement Hors Ligne'
                                              : 'Transaction'),
                                      subtitle: subtitleText,
                                      amount: amountStr,
                                      isNegative: isNegative,
                                      isPending: isPending,
                                      onTap: () {
                                        TransactionDetailsBottomSheet.show(context, activity);
                                      },
                                    ),
                                  );
                                }),
                                const SizedBox(height: AppSpacing.md),
                              ];
                            }),

                            // Bouton "Voir plus" en bas des transactions
                            if (_hasMore && !_isOfflineMode)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Center(
                                  child: _isLoadingMore
                                      ? const Padding(
                                          padding: EdgeInsets.all(AppSpacing.md),
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF161A22),
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child: OutlinedButton(
                                            onPressed: _loadMore,
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFFE2E4E8), width: 1.5),
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(0xFF161A22),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Voir plus',
                                                  style: AppTextStyles.labelLarge.copyWith(
                                                    color: const Color(0xFF161A22),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  LucideIcons.chevronDown,
                                                  size: 18,
                                                  color: Color(0xFF161A22),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                              ),

                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        ),
                      ),
      ),
    );
  }

  String _formatTime(dynamic dateValue) {
    if (dateValue == null) return '';
    try {
      final date = DateTime.parse(dateValue.toString());
      return DateFormat('HH:mm').format(date);
    } catch (_) {
      return '';
    }
  }

  Widget _buildDateHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(
          color: const Color(0xFF8B93A8),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isNegative,
    bool isPending = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
      ),
    );
  }
}

