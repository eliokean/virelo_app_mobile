import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/merchant_service.dart';
import '../../../../config/routes/route_names.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/offline_sync_service.dart';

class MerchantDashboardPage extends StatefulWidget {
  const MerchantDashboardPage({super.key});

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage> {
  late final MerchantService _merchantService;
  late final OfflineSyncService _offlineSyncService;
  bool _isLoading = true;
  String _balance = "0";
  String _merchantName = "Chargement...";
  List<dynamic> _transactions = [];
  int _pendingSyncCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _merchantService = MerchantService(ApiClient());
    _offlineSyncService = OfflineSyncService(ApiClient());
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final pendingCount = await _offlineSyncService.getPendingCount();
      final statsResponse = await _merchantService.getStats();
      final statsData = statsResponse['data'] ?? statsResponse;
      
      // La balance actuelle du wallet
      final wallet = statsData['wallet'];
      
      final txResponse = await _merchantService.getTransactions();
      final txData = txResponse; // getTransactions already returns List<dynamic>

      if (mounted) {
        setState(() {
          _merchantName = statsData['merchant']['name'] ?? 'Ma Boutique';
          _balance = (wallet != null && wallet['balance'] != null) 
              ? double.parse(wallet['balance'].toString()).toStringAsFixed(0) 
              : "0";
          _transactions = txData;
          _pendingSyncCount = pendingCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final pendingCount = await _offlineSyncService.getPendingCount();
        setState(() {
          _merchantName = "Boutique";
          _balance = "0";
          _pendingSyncCount = pendingCount;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _syncOfflineTransactions() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      await _offlineSyncService.syncPendingTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synchronisation réussie !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131517), // Premium Dark
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _merchantName,
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2228),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
              onPressed: _loadDashboardData,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    // Hero Card (Recettes)
                    _buildHeroCard(),
                    
                    if (_pendingSyncCount > 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildSyncBanner(),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    
                    // Actions rapides
                    Text(
                      'Actions',
                      style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: LucideIcons.arrowDownLeft,
                            title: 'Encaisser',
                            color: const Color(0xFFB5E48C), // Accent green
                            onTap: () {
                              context.pushNamed(RouteNames.receivePayment).then((_) {
                                // Rafraîchir les données au retour
                                _loadDashboardData();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: LucideIcons.history,
                            title: 'Historique',
                            color: const Color(0xFF94A3B8), // Soft grey/blue
                            onTap: () => context.pushNamed(RouteNames.history),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.xxl),
                    
                    // Transactions Récentes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dernières ventes',
                          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () => context.pushNamed(RouteNames.history),
                          child: Text(
                            'Voir tout',
                            style: AppTextStyles.labelMedium.copyWith(color: const Color(0xFFB5E48C)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_transactions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            'Aucune vente récente.',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ..._transactions.map((tx) {
                        final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
                        final isIncome = true; // Pour l'instant, les marchands ne font qu'encaisser
                        
                        // Parse la date et formate l'heure
                        String timeStr = "";
                        if (tx['created_at'] != null) {
                          try {
                            final date = DateTime.parse(tx['created_at']).toLocal();
                            timeStr = DateFormat('HH:mm').format(date);
                          } catch (_) {}
                        }
                        
                        return _buildRecentTransaction(
                          'Client Virelo',
                          '+ ${amount.toStringAsFixed(0)} XOF',
                          timeStr,
                          isIncome
                        );
                      }),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2228),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2C3138)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB5E48C).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.trendingUp, color: Color(0xFFB5E48C), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Solde du Wallet',
                style: AppTextStyles.labelMedium.copyWith(color: const Color(0xFF8B93A8)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '$_balance XOF',
            style: AppTextStyles.displayLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Actif',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.wifiOff, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Télécollecte en attente',
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_pendingSyncCount transaction(s) hors-ligne',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.orange[200]),
                ),
              ],
            ),
          ),
          _isSyncing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2),
                )
              : ElevatedButton(
                  onPressed: _syncOfflineTransactions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Envoyer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon, 
    required String title, 
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2228),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2C3138)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransaction(String title, String amount, String time, bool isIncome) {
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
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF8B93A8)),
                  ),
                ],
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
