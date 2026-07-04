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
import '../widgets/send_again_section.dart';
import '../widgets/recent_activity_list.dart';
import '../widgets/offline_escrow_banner.dart';
import '../pages/allocate_offline_budget_page.dart';
import '../../../transfer/presentation/pages/request_offline_payment_page.dart';
import '../../../transfer/presentation/pages/scan_contact_page.dart';
import 'offline_sync_queue_page.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final WalletService _walletService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _balance = "0";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _walletService = WalletService(apiClient, AuthService(apiClient));
    _loadCachedBalance();
    _fetchBalance();
  }

  Future<void> _loadCachedBalance() async {
    try {
      final cached = await _storage.read(key: 'cached_balance');
      if (cached != null && mounted) {
        setState(() {
          _balance = cached;
          _isLoading = false;
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
                    const WalletHeader(),
                    BalanceHeroCard(balance: _balance, isLoading: _isLoading),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            
            // Middle Dark Section (Action Bar)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
              child: WalletActionsBar(onRefresh: _fetchBalance),
            ),
            OfflineEscrowBanner(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllocateOfflineBudgetPage()),
                );
                if (result == true) {
                  _fetchBalance();
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paiement Hors Ligne',
                    style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOfflineActionCard(
                          context,
                          title: 'Encaisser',
                          icon: LucideIcons.qrCode,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RequestOfflinePaymentPage()),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildOfflineActionCard(
                          context,
                          title: 'Payer',
                          icon: LucideIcons.camera,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ScanContactPage()),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildOfflineActionCard(
                          context,
                          title: 'Synchro',
                          icon: LucideIcons.uploadCloud,
                          isAccent: true,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const OfflineSyncQueuePage()),
                            );
                            _fetchBalance();
                          },
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
                    onRefresh: _fetchBalance,
                    color: const Color(0xFF161A22),
                    child: const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(AppSpacing.screenH),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SendAgainSection(),
                          SizedBox(height: AppSpacing.xxl),
                          RecentActivityList(),
                          SizedBox(height: AppSpacing.huge),
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
}
