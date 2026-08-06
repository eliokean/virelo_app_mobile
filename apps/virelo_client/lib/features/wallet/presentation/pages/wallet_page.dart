import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_core/services/wallet_service.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/wallet_header.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/wallet_actions_bar.dart';
import '../widgets/recent_activity_list.dart';
import '../pages/allocate_offline_budget_page.dart';
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
    _fetchRecentActivities();
  }

  Future<void> _loadCachedData() async {
    try {
      final name = await _storage.read(key: 'user_name') ?? "Client";
      final cachedBal = await _storage.read(key: 'cached_balance');
      final cachedHistory = await _offlineStorage.getFullCachedHistory();
      
      if (mounted) {
        setState(() {
          _userName = name;
          if (cachedBal != null) _balance = cachedBal;
          if (_activities.isEmpty && cachedHistory.isNotEmpty) {
            _activities = cachedHistory.take(6).toList();
          }
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchRecentActivities() async {
    try {
      final historyData = await _walletService.getHistory(page: 1, perPage: 6);
      final List<dynamic> serverTx = (historyData['data'] as List<dynamic>?) ?? [];
      
      // Sauvegarder dans le cache local pour consultation hors-ligne
      if (serverTx.isNotEmpty) {
        await _offlineStorage.saveCachedServerTransactions(serverTx);
      }

      // Récupérer les éventuelles transactions hors-ligne locales
      final offlineTx = await _offlineStorage.getOfflineTransactions();
      
      // Les transactions hors-ligne non synchronisées en priorité, puis serveur
      final combined = <dynamic>[...offlineTx, ...serverTx];
      
      if (mounted) {
        setState(() {
          _activities = combined.take(6).toList();
        });
      }
    } catch (e) {
      debugPrint('==== ERREUR FETCH RECENT ACTIVITIES (FALLBACK OFFLINE): $e ====');
      final fallback = await _offlineStorage.getFullCachedHistory();
      if (mounted && fallback.isNotEmpty) {
        setState(() {
          _activities = fallback.take(6).toList();
        });
      }
    }
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

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchBalance(),
      _fetchOfflineBudget(),
      _fetchRecentActivities(),
    ]);
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
                    BalanceHeroCard(
                      balance: _balance,
                      offlineBudget: _offlineBudget,
                      isLoading: _isLoading,
                      onOfflineTap: _showOfflineOptions,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            
            // Middle Dark Section (Action Bar)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: WalletActionsBar(
                onRefresh: () {
                  _refreshAll();
                },
              ),
            ),

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
                    onRefresh: _refreshAll,
                    color: const Color(0xFF161A22),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.screenH),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RecentActivityList(
                            activities: _activities,
                            isLoading: _isLoading,
                            onRefresh: _fetchRecentActivities,
                          ),
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

  void _showOfflineOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB5E48C).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.wifiOff, color: Color(0xFFB5E48C), size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Séquestre Hors-Ligne',
                              style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Budget sécurisé pour payer sans réseau',
                              style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3138),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Montant disponible hors-ligne',
                          style: AppTextStyles.labelSmall.copyWith(color: const Color(0xFF8B93A8)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${_offlineBudget.toInt()}',
                              style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontSize: 32),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'FCFA',
                              style: AppTextStyles.labelMedium.copyWith(color: const Color(0xFF8B93A8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Recharger
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3138),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
                    ),
                    title: Text('Allouer / Recharger le budget', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                    subtitle: Text('Sécuriser un nouveau montant', style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
                    trailing: const Icon(LucideIcons.chevronRight, color: Colors.white38),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AllocateOfflineBudgetPage()),
                      );
                      if (result == true) {
                        _refreshAll();
                      }
                    },
                  ),
                  const Divider(color: Color(0xFF2C3138)),
                  // Historique
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3138),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.history, color: Colors.white, size: 20),
                    ),
                    title: Text('Historique des paiements offline', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                    subtitle: Text('Voir les transactions locales', style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
                    trailing: const Icon(LucideIcons.chevronRight, color: Colors.white38),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OfflineClientHistoryPage()),
                      );
                      _refreshAll();
                    },
                  ),
                  const Divider(color: Color(0xFF2C3138)),
                  // File de synchronisation
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3138),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.uploadCloud, color: Colors.white, size: 20),
                    ),
                    title: Text('File de synchronisation', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                    subtitle: Text('Synchroniser avec le serveur', style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
                    trailing: const Icon(LucideIcons.chevronRight, color: Colors.white38),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OfflineSyncQueuePage()),
                      );
                      _refreshAll();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
