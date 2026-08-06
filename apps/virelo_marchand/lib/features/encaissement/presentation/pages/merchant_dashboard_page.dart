import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/merchant_service.dart';
import '../../../../core/services/offline_sync_service.dart';
import 'generate_invoice_amount_page.dart';
import 'nfc_reader_page.dart';
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
  int _merchantId = 0;

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
      
      final wallet = statsData['wallet'];
      final txResponse = await _merchantService.getTransactions();
      final txData = txResponse;

      if (mounted) {
        setState(() {
          _merchantName = statsData['merchant']['name'] ?? 'Ma Boutique';
          _merchantId = statsData['merchant']['user_id'] ?? 0;
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

  void _showCollectOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Encaisser un Paiement',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: const Color(0xFF161A22),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Choisissez le moyen d\'encaissement avec le client :',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF8B93A8),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Option 1: QR Code Facture
                _buildCollectOptionTile(
                  icon: LucideIcons.qrCode,
                  iconColor: const Color(0xFF161A22),
                  iconBgColor: const Color(0xFFB5E48C),
                  title: 'Facture Dynamique (QR Code)',
                  subtitle: 'Saisissez un montant et faites scanner le code par le client',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GenerateInvoiceAmountPage(
                          merchantId: _merchantId,
                          merchantName: _merchantName,
                        ),
                      ),
                    ).then((_) => _loadDashboardData());
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Option 2: Sans Contact (NFC TPE)
                _buildCollectOptionTile(
                  icon: Icons.contactless,
                  iconColor: Colors.white,
                  iconBgColor: const Color(0xFF161A22),
                  title: 'Terminal Sans Contact (NFC)',
                  subtitle: 'Rapprochement direct du téléphone ou de la carte client',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NfcReaderPage(),
                      ),
                    ).then((_) => _loadDashboardData());
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollectOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9FA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEFEFEF)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 26),
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF8B93A8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(LucideIcons.chevronRight, size: 20, color: Color(0xFF8B93A8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF2D2E33),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    MerchantHeader(
                      merchantName: _merchantName,
                      onSettingsChanged: _loadDashboardData,
                    ),
                    MerchantBalanceCard(
                      balance: _balance, 
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            
            // Middle Dark Section (Actions & Télécollecte)
            // Bannière de Télécollecte si transactions offline en attente
            if (_pendingSyncCount > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                child: _buildSyncBanner(),
              ),
            ],

            // Barre d'actions factorisée : Encaisser + Retirer (Avec picto conforme à la charte client)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  // Action 1: ENCAISSER (Factorisé : QR + NFC)
                  Expanded(
                    child: _buildActionButton(
                      label: 'Encaisser',
                      icon: LucideIcons.arrowDownLeft,
                      onTap: () => _showCollectOptions(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Action 2: RETIRER (Déplacé dans la zone d'action)
                  Expanded(
                    child: _buildActionButton(
                      label: 'Retirer',
                      icon: LucideIcons.arrowUpRight,
                      onTap: () async {
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
                  ),
                ],
              ),
            ),

            // Bottom White Section (Transactions récentes)
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
              color: Colors.orange.withValues(alpha: 0.2),
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
            )
          else
            ElevatedButton(
              onPressed: _syncOfflineTransactions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB5E48C),
                foregroundColor: const Color(0xFF161A22),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Synchroniser', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
