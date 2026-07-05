import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/merchant_header.dart';
import '../widgets/merchant_balance_card.dart';
import '../widgets/merchant_activity_list.dart';
import 'withdrawal_page.dart';

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
  double _pendingAmount = 0;
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
      final pendingAmount = await _offlineSyncService.getPendingAmount();
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
          _pendingAmount = pendingAmount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final pendingCount = await _offlineSyncService.getPendingCount();
        final pendingAmount = await _offlineSyncService.getPendingAmount();
        setState(() {
          _merchantName = "Boutique";
          _balance = "0";
          _pendingSyncCount = pendingCount;
          _pendingAmount = pendingAmount;
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF161A22), // Dark middle section
        body: Column(
          children: [
            // Top Light Section
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE9E9F2),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    MerchantHeader(merchantName: _merchantName),
                    MerchantBalanceCard(
                      balance: _balance, 
                      isLoading: _isLoading,
                      onWithdrawal: () async {
                        final shouldRefresh = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WithdrawalPage(
                              currentBalance: double.tryParse(_balance) ?? 0,
                            ),
                          ),
                        );
                        if (shouldRefresh == true) {
                          _loadDashboardData();
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            
            // Middle Dark Section (Actions)
            const SizedBox(height: AppSpacing.lg),
            
            // Bannière de Sync si besoin
            if (_pendingSyncCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                child: _buildSyncBanner(),
              ),
              
            if (_pendingSyncCount > 0)
              const SizedBox(height: AppSpacing.md),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions',
                    style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOfflineActionCard(
                          context,
                          title: 'Encaisser (Scan)',
                          icon: LucideIcons.qrCode,
                          onTap: () {
                            context.pushNamed(RouteNames.receivePayment).then((_) {
                              _loadDashboardData();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildOfflineActionCard(
                          context,
                          title: 'Générer Facture',
                          icon: LucideIcons.receipt,
                          onTap: () {
                            // Implémentation future (QR statique marchand)
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildOfflineActionCard(
                          context,
                          title: 'Synchro',
                          icon: LucideIcons.uploadCloud,
                          isAccent: true,
                          onTap: _syncOfflineTransactions,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Bottom White Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    color: const Color(0xFF161A22),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.screenH),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MerchantActivityList(activities: _transactions, isLoading: _isLoading),
                          const SizedBox(height: AppSpacing.huge),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return Material(
      color: const Color(0xFF1F2228),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(
                icon,
                color: isAccent ? const Color(0xFF94A3B8) : const Color(0xFFB5E48C),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isAccent ? const Color(0xFF94A3B8) : const Color(0xFFB5E48C),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3138),
        borderRadius: BorderRadius.circular(16),
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
                  style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_pendingSyncCount encaissement(s) hors-ligne',
                  style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF8B93A8)),
                ),
                Text(
                  '+ ${_pendingAmount.toStringAsFixed(0)} FCFA à synchroniser',
                  style: AppTextStyles.labelSmall.copyWith(color: const Color(0xFFB5E48C), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (_isSyncing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
