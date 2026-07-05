import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_core/services/wallet_service.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../payment/presentation/pages/generate_payment_qr_amount_page.dart';
import '../widgets/wallet_header.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/wallet_actions_bar.dart';
import '../widgets/send_again_section.dart';
import '../widgets/recent_activity_list.dart';
import '../widgets/offline_escrow_banner.dart';
import '../pages/allocate_offline_budget_page.dart';
import '../../../transfer/presentation/pages/request_offline_payment_page.dart';
import '../../../transfer/presentation/pages/scan_contact_page.dart';
import 'offline_sync_queue_page.dart';
import 'offline_client_history_page.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final WalletService _walletService;
  late final OfflineStorageService _offlineStorage;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  String _userName = "";
  String _balance = "0";
  double _offlineBudget = 0.0;
  List<dynamic> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    final authService = AuthService(apiClient);
    _walletService = WalletService(apiClient, authService);
    _offlineStorage = OfflineStorageService(authService);
    
    _loadCachedData();
    _fetchBalance();
    _fetchOfflineBudget();
  }

  Future<void> _loadCachedData() async {
    try {
      final name = await _storage.read(key: 'user_name') ?? "Client";
      final cachedBal = await _storage.read(key: 'cached_balance');
      final offlineHistory = await _offlineStorage.getOfflineTransactions();
      
      if (mounted) {
        setState(() {
          _userName = name;
          if (cachedBal != null) _balance = cachedBal;
          _activities = offlineHistory;
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchOfflineBudget() async {
    try {
      double budget = 0.0;
      
      try {
        final apiData = await _walletService.getOfflineBalance();
        final serverBalance = double.tryParse(apiData['offline_balance'].toString()) ?? 0.0;
        await _offlineStorage.saveOfflineBudget(serverBalance);
        budget = serverBalance;
      } catch (e) {
        debugPrint('==== ECHEC SYNC SERVER, FALLBACK LOCAL: $e ====');
        budget = await _offlineStorage.getOfflineBudget();
      }

      if (mounted) {
        setState(() {
          _offlineBudget = budget;
        });
      }
    } catch (_) {}
  }



  Future<void> _fetchBalance() async {
    try {
      final data = await _walletService.getBalance();
      final newBalance = data['balance']?.toString() ?? "0";
      await _storage.write(key: 'cached_balance', value: newBalance);
      
      if (mounted) {
        setState(() {
          _balance = newBalance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                    WalletHeader(userName: _userName),
                    BalanceHeroCard(balance: _balance, isLoading: _isLoading),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            
            // Middle Dark Section (Action Bar)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
              child: WalletActionsBar(
                onRefresh: () {
                  _fetchBalance();
                  _fetchOfflineBudget();
                  _loadCachedData();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: _buildOfflinePocket(),
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
                    onRefresh: () async {
                      await _fetchBalance();
                      await _fetchOfflineBudget();
                      await _loadCachedData(); // Recharger depuis Hive aussi
                    },
                    color: const Color(0xFF161A22),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.screenH),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RecentActivityList(activities: _activities, isLoading: _isLoading),
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

  Widget _buildOfflinePocket() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          // Header de la poche
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB5E48C).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.wifiOff, color: Color(0xFFB5E48C), size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Poche Hors Ligne', style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              GestureDetector(
                onTap: () async {
                   await Navigator.push(context, MaterialPageRoute(builder: (_) => const OfflineClientHistoryPage()));
                   _fetchOfflineBudget();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C3138),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Historique', style: AppTextStyles.labelSmall.copyWith(color: const Color(0xFF8B93A8))),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Budget
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$_offlineBudget', style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontSize: 32)),
              const SizedBox(width: 8),
              Text('FCFA', style: AppTextStyles.labelMedium.copyWith(color: const Color(0xFF8B93A8))),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Actions
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GeneratePaymentQrAmountPage())),
                  icon: const Icon(LucideIcons.qrCode, size: 18),
                  label: const Text('Payer', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB5E48C),
                    foregroundColor: const Color(0xFF161A22),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                     final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AllocateOfflineBudgetPage()));
                     if (result == true) { _fetchBalance(); _fetchOfflineBudget(); }
                  },
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Recharger', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3138),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: () async {
                   await Navigator.push(context, MaterialPageRoute(builder: (_) => const OfflineSyncQueuePage()));
                   _fetchBalance();
                },
                icon: const Icon(LucideIcons.uploadCloud, color: Colors.white, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3138),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
