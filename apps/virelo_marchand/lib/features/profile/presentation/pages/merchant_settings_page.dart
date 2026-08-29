import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/services/merchant_service.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'merchant_kyc_page.dart';

class MerchantSettingsPage extends StatefulWidget {
  final String merchantName;
  const MerchantSettingsPage({super.key, this.merchantName = 'Ma Boutique'});

  @override
  State<MerchantSettingsPage> createState() => _MerchantSettingsPageState();
}

class _MerchantSettingsPageState extends State<MerchantSettingsPage> {
  late AuthService _authService;
  late MerchantService _merchantService;
  late OfflineSyncService _offlineSyncService;

  String _merchantName = "Boutique";
  String _merchantPhone = "";
  final String _siret = "RCCM: En cours";
  String _kycStatus = 'unverified'; // 'unverified', 'pending', 'approved', 'rejected'
  bool _pushNotifications = true;
  bool _audioAlerts = true;
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  bool _isLoading = false;
  int _pendingCount = 0;
  double _pendingAmount = 0;

  @override
  void initState() {
    super.initState();
    _merchantName = widget.merchantName;
    final apiClient = ApiClient();
    _authService = AuthService(apiClient);
    _merchantService = MerchantService(apiClient);
    _offlineSyncService = OfflineSyncService(apiClient);

    _loadMerchantDetails();
    _checkBiometrics();
  }

  Future<void> _loadMerchantDetails() async {
    try {
      final name = await _authService.getUserName();
      final stats = await _merchantService.getStats();
      final statsData = stats['data'] ?? stats;
      final pendingCount = await _offlineSyncService.getPendingCount();
      final pendingAmount = await _offlineSyncService.getPendingAmount();
      
      String kycStatus = 'unverified';
      try {
        final kycResponse = await ApiClient().dio.get('/kyb/status');
        kycStatus = kycResponse.data['status'] ?? 'unverified';
      } catch (_) {
        try {
          final fallback = await ApiClient().dio.get('/kyc/status');
          kycStatus = fallback.data['status'] ?? 'unverified';
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          if (statsData['merchant'] != null) {
            _merchantName = statsData['merchant']['name'] ?? _merchantName;
            _merchantPhone = statsData['merchant']['phone'] ?? _merchantPhone;
          } else if (name != null && name.isNotEmpty) {
            _merchantName = name;
          }
          _kycStatus = kycStatus;
          _pendingCount = pendingCount;
          _pendingAmount = pendingAmount;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkBiometrics() async {
    try {
      final available = await _authService.isBiometricsAvailable();
      if (mounted) {
        setState(() {
          _biometricsAvailable = available;
        });
      }
    } catch (_) {}
  }

  Future<void> _showNotificationsCenter() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications Caisse',
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
                const SizedBox(height: AppSpacing.md),
                _buildNotificationTile(
                  icon: LucideIcons.checkCircle2,
                  title: 'Encaissement validé',
                  description: 'Paiement sans contact de 5 000 FCFA reçu avec succès.',
                  time: 'Il y a 10 min',
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildNotificationTile(
                  icon: LucideIcons.wifi,
                  title: 'Terminal TPE Connecté',
                  description: 'Prêt pour les encaissements en ligne et hors-ligne.',
                  time: 'Aujourd\'hui',
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildNotificationTile(
                  icon: LucideIcons.shieldCheck,
                  title: 'Sécurité Caisse',
                  description: 'Session marchand active et chiffrée.',
                  time: 'Hier',
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String description,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF161A22).withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF161A22)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFF161A22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF8B93A8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTextStyles.labelSmall.copyWith(
              color: const Color(0xFF8B93A8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.logOut, color: Colors.red.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Fermer la Caisse',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter de votre espace marchand Virelo ?',
          style: TextStyle(color: Color(0xFF4A5168)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF8B93A8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _authService.logout();
      } catch (_) {}
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
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
        backgroundColor: const Color(0xFFF9F9FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF161A22)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Paramètres & Caisse',
            style: AppTextStyles.headlineMedium.copyWith(
              color: const Color(0xFF161A22),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF161A22)))
            : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                  vertical: AppSpacing.md,
                ),
                children: [
                  // Carte Boutique Marchand
                  _buildMerchantProfileCard(),
                  const SizedBox(height: AppSpacing.xl),

                  // Section Établissement & KYC
                  _buildSectionHeader('ÉTABLISSEMENT & VÉRIFICATION'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSettingsContainer(
                    children: [
                      _buildSettingsTile(
                        icon: LucideIcons.building,
                        title: 'Fiche Entreprise & KYC',
                        subtitle: 'RCCM, IFU, Immatriculation officielle',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildKycStatusBadge(),
                            const SizedBox(width: 6),
                            const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF8B93A8)),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MerchantKycPage()),
                          ).then((_) => _loadMerchantDetails());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section Terminal & Télécollecte
                  _buildSectionHeader('TERMINAL & SYNCHRONISATION'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSettingsContainer(
                    children: [
                      _buildSettingsTile(
                        icon: LucideIcons.uploadCloud,
                        title: 'Télécollecte Hors-Ligne',
                        subtitle: _pendingCount > 0
                            ? '$_pendingCount transaction(s) en attente (+${_pendingAmount.toInt()} FCFA)'
                            : 'Toutes les transactions sont synchronisées',
                        trailing: _pendingCount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Text(
                                  '$_pendingCount',
                                  style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : const Icon(LucideIcons.checkCircle2, color: Color(0xFF2E7D32), size: 20),
                        onTap: () async {
                          if (_pendingCount > 0) {
                            setState(() => _isLoading = true);
                            try {
                              await _offlineSyncService.syncPendingTransactions();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Synchronisation réussie !'), backgroundColor: Color(0xFF2E7D32)),
                              );
                              await _loadMerchantDetails();
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                              );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Aucune transaction en attente de synchronisation.')),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
                      _buildSwitchTile(
                        icon: LucideIcons.volume2,
                        title: 'Alertes Sonores de Caisse',
                        subtitle: 'Signal sonore lors d\'un encaissement validé',
                        value: _audioAlerts,
                        onChanged: (val) {
                          setState(() => _audioAlerts = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section Notifications
                  _buildSectionHeader('NOTIFICATIONS'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSettingsContainer(
                    children: [
                      _buildSettingsTile(
                        icon: LucideIcons.bell,
                        title: 'Historique des alertes',
                        subtitle: 'Consulter les notifications de caisse',
                        trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF8B93A8)),
                        onTap: _showNotificationsCenter,
                      ),
                      const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
                      _buildSwitchTile(
                        icon: LucideIcons.messageSquare,
                        title: 'Notifications Push',
                        subtitle: 'Alertes instantanées de paiement reçu',
                        value: _pushNotifications,
                        onChanged: (val) {
                          setState(() => _pushNotifications = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section Sécurité
                  _buildSectionHeader('SÉCURITÉ'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSettingsContainer(
                    children: [
                      if (_biometricsAvailable) ...[
                        _buildSwitchTile(
                          icon: LucideIcons.fingerprint,
                          title: 'Déverrouillage Biométrique',
                          subtitle: 'Accès rapide caissier / gérant',
                          value: _biometricsEnabled,
                          onChanged: (val) async {
                            if (val) {
                              final auth = await _authService.authenticateWithBiometrics();
                              if (!auth) return;
                            }
                            setState(() => _biometricsEnabled = val);
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Bouton Déconnexion
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade100, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade50.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.logOut, size: 20, color: Colors.red.shade700),
                      ),
                      title: Text(
                        'Fermer la Caisse (Déconnexion)',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Quitter la session marchand',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.red.shade300,
                        ),
                      ),
                      trailing: Icon(LucideIcons.chevronRight, size: 18, color: Colors.red.shade300),
                      onTap: _handleLogout,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Text(
                      'Virelo Marchand POS v1.0.0 • TPE Hybride',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF8B93A8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
      ),
    );
  }

  Widget _buildMerchantProfileCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB5E48C), Color(0xFF99D98C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.store, color: Color(0xFF161A22), size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _merchantName,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _merchantPhone.isNotEmpty ? _merchantPhone : _siret,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.checkCircle2, color: Color(0xFFB5E48C), size: 14),
                const SizedBox(width: 4),
                Text(
                  'Actif',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycStatusBadge() {
    Color bg;
    Color textColor;
    String label;

    switch (_kycStatus) {
      case 'approved':
        bg = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'Vérifié';
        break;
      case 'pending':
        bg = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF59E0B);
        label = 'En attente';
        break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        textColor = AppColors.error;
        label = 'À corriger';
        break;
      case 'unverified':
      default:
        bg = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        label = 'Non vérifié';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showBusinessInfoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Informations Entreprise',
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
                const SizedBox(height: AppSpacing.md),
                _buildInfoRow('Nom commercial', _merchantName),
                _buildInfoRow('Numéro RCCM', 'RB/COT/24-B-8932'),
                _buildInfoRow('Identifiant Fiscal (IFU)', '0202412984931'),
                _buildInfoRow('Type d\'activité', 'Commerce général / Vente au détail'),
                _buildInfoRow('Statut de conformité', 'Compte certifié & opérationnel'),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF8B93A8))),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                color: const Color(0xFF161A22),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.labelSmall.copyWith(
          color: const Color(0xFF8B93A8),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer({required List<Widget> children}) {
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
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: iconColor ?? const Color(0xFF161A22)),
      ),
      title: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: const Color(0xFF161A22),
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: const Color(0xFF8B93A8),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF161A22)),
      ),
      title: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: const Color(0xFF161A22),
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: const Color(0xFF8B93A8),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF161A22),
        activeTrackColor: const Color(0xFFB5E48C),
      ),
    );
  }
}
