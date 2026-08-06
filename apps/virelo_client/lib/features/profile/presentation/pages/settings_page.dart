import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../kyc/presentation/pages/kyc_upload_page.dart';
import '../../../wallet/presentation/pages/offline_sync_queue_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late AuthService _authService;

  String _userName = "Client";
  String _userPhone = "";
  bool _pushNotifications = true;
  bool _offlineAlerts = true;
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _authService = AuthService(apiClient);

    _loadUserData();
    _checkBiometrics();
  }

  Future<void> _loadUserData() async {
    try {
      final name = await _storage.read(key: 'user_name') ?? "Client";
      final phone = await _storage.read(key: 'user_phone') ?? "";
      final pushNotif = await _storage.read(key: 'setting_push_notif');
      final offlineNotif = await _storage.read(key: 'setting_offline_alerts');
      final bio = await _storage.read(key: 'setting_biometrics');

      if (mounted) {
        setState(() {
          _userName = name;
          _userPhone = phone;
          if (pushNotif != null) _pushNotifications = pushNotif == 'true';
          if (offlineNotif != null) _offlineAlerts = offlineNotif == 'true';
          if (bio != null) _biometricsEnabled = bio == 'true';
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
                      'Notifications récentes',
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
                  icon: LucideIcons.shieldCheck,
                  title: 'Sécurité de votre compte',
                  description: 'Votre session est active et sécurisée.',
                  time: 'Il y a 5 min',
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildNotificationTile(
                  icon: LucideIcons.wallet,
                  title: 'Solde mis à jour',
                  description: 'Votre portefeuille a été synchronisé.',
                  time: 'Aujourd\'hui',
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildNotificationTile(
                  icon: LucideIcons.wifi,
                  title: 'Transactions hors ligne prêtes',
                  description: 'Le protocole NFC/QR offline est opérationnel.',
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
              'Déconnexion',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter de votre compte Virelo ?',
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
            'Paramètres & Profil',
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
                  // Carte Profil Utilisateur
                  _buildUserProfileCard(),
                  const SizedBox(height: AppSpacing.xl),

                  // Section Compte & Identité (KYC)
                  _buildSectionHeader('COMPTE & VÉRIFICATION'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSettingsContainer(
                    children: [
                      _buildSettingsTile(
                        icon: LucideIcons.shieldAlert,
                        iconColor: const Color(0xFF161A22),
                        title: 'Vérification d\'identité (KYC)',
                        subtitle: 'Passeport, CNI, Attestation',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Vérifier',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF8B93A8)),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const KycUploadPage()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section Notifications
                  _buildSectionHeader('NOTIFICATIONS & ALERTES'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSettingsContainer(
                    children: [
                      _buildSettingsTile(
                        icon: LucideIcons.bell,
                        title: 'Centre de notifications',
                        subtitle: 'Consulter l\'historique des alertes',
                        trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF8B93A8)),
                        onTap: _showNotificationsCenter,
                      ),
                      const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
                      _buildSwitchTile(
                        icon: LucideIcons.messageSquare,
                        title: 'Notifications Push',
                        subtitle: 'Alertes instantanées de paiement',
                        value: _pushNotifications,
                        onChanged: (val) async {
                          setState(() => _pushNotifications = val);
                          await _storage.write(key: 'setting_push_notif', value: val.toString());
                        },
                      ),
                      const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
                      _buildSwitchTile(
                        icon: LucideIcons.wifiOff,
                        title: 'Alertes Hors-Ligne',
                        subtitle: 'Notifications lors de la reconnexion',
                        value: _offlineAlerts,
                        onChanged: (val) async {
                          setState(() => _offlineAlerts = val);
                          await _storage.write(key: 'setting_offline_alerts', value: val.toString());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section Sécurité & Données
                  _buildSectionHeader('SÉCURITÉ & DONNÉES'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSettingsContainer(
                    children: [
                      if (_biometricsAvailable) ...[
                        _buildSwitchTile(
                          icon: LucideIcons.fingerprint,
                          title: 'Authentification Biométrique',
                          subtitle: 'Déverrouillage rapide par empreinte / Face ID',
                          value: _biometricsEnabled,
                          onChanged: (val) async {
                            if (val) {
                              final auth = await _authService.authenticateWithBiometrics();
                              if (!auth) return;
                            }
                            setState(() => _biometricsEnabled = val);
                            await _storage.write(key: 'setting_biometrics', value: val.toString());
                          },
                        ),
                        const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
                      ],
                      _buildSettingsTile(
                        icon: LucideIcons.uploadCloud,
                        title: 'File de synchronisation hors-ligne',
                        subtitle: 'Gérer les transactions en attente',
                        trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF8B93A8)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OfflineSyncQueuePage()),
                          );
                        },
                      ),
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
                        'Se déconnecter',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Fermer la session actuelle',
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
                      'Virelo v1.0.0 • Protocole Hybride Sécurisé',
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

  Widget _buildUserProfileCard() {
    final initials = _userName.trim().isNotEmpty
        ? _userName.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : 'VI';

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
            child: Text(
              initials,
              style: AppTextStyles.headlineMedium.copyWith(
                color: const Color(0xFF161A22),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _userPhone.isNotEmpty ? _userPhone : 'Utilisateur Particulier',
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

