import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'transfer_amount_page.dart';
import 'scan_contact_page.dart';
import 'package:virelo_core/services/wallet_service.dart';

class TransferContactPage extends StatefulWidget {
  const TransferContactPage({super.key});

  @override
  State<TransferContactPage> createState() => _TransferContactPageState();
}

class _TransferContactPageState extends State<TransferContactPage> {
  List<Contact> _contacts = [];
  bool _isLoadingContacts = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _recentContacts = [];
  bool _isLoadingRecents = true;

  @override
  void initState() {
    super.initState();
    _fetchRecentContacts();
  }

  Future<void> _fetchRecentContacts() async {
    if (!mounted) return;
    setState(() => _isLoadingRecents = true);
    try {
      final response = await WalletService().getHistory();
      if (response['data'] != null) {
        final List data = response['data'];
        final recents = <Map<String, dynamic>>[];
        final phones = <String>{};
        
        for (var tx in data) {
          if (tx['type'] == 'c2c_transfer' && tx['is_negative'] == true && tx['phone'] != null) {
            final phone = tx['phone'] as String;
            if (!phones.contains(phone)) {
              phones.add(phone);
              recents.add({
                'name': tx['title'] ?? 'Inconnu',
                'phone': phone,
                'color': [0xFFD8B4E2, 0xFFF9C846, 0xFF76C893, 0xFF83C5BE, 0xFFE29578][recents.length % 5],
              });
            }
          }
        }
        if (mounted) {
          setState(() {
            _recentContacts = recents.take(10).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching recent contacts: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingRecents = false);
      }
    }
  }

  Future<void> _fetchContacts() async {
    setState(() => _isLoadingContacts = true);
    
    try {
      if (await Permission.contacts.request().isGranted) {
        final contacts = await FlutterContacts.getAll(properties: {ContactProperty.phone});
        setState(() {
          _contacts = contacts;
          _isLoadingContacts = false;
        });
      } else {
        setState(() => _isLoadingContacts = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission d\'accès aux contacts refusée')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingContacts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la lecture des contacts: $e')),
        );
      }
    }
  }

  void _selectContact(String name, String phone) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferAmountPage(beneficiaryName: name, beneficiaryPhone: phone),
      ),
    );
  }

  void _showNewNumberDialog() {
    String newNumber = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1D21),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3138),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Saisir un numéro',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2228),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2C3138)),
                  ),
                  child: TextField(
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Numéro de téléphone...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF8B93A8)),
                      border: InputBorder.none,
                      prefixIcon: const Icon(LucideIcons.phone, color: Color(0xFF8B93A8), size: 20),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                    ),
                    onChanged: (val) => newNumber = val,
                    onSubmitted: (val) {
                      if (val.isNotEmpty) {
                        Navigator.pop(context);
                        _selectContact('Nouveau Contact', val);
                      }
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (newNumber.isNotEmpty) {
                        Navigator.pop(context);
                        _selectContact('Nouveau Contact', newNumber);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: const Color(0xFF131517),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continuer',
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF131517), // Fond "Premium Dark" très profond
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Header
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF1F2228),
                              padding: const EdgeInsets.all(AppSpacing.sm),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'À qui envoyer ?',
                                style: AppTextStyles.headlineMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48), // Pour centrer le titre
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.md),

                  // Barre de Recherche
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2228),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                        decoration: InputDecoration(
                          icon: const Icon(LucideIcons.search, color: Color(0xFF8B93A8)),
                          hintText: 'Rechercher un nom, un pseudo...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF8B93A8)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),

                  // Actions Rapides (Saisir numéro / Scan QR & NFC)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                    child: Row(
                      children: [
                        Expanded(child: _buildQuickActionCard(
                          icon: LucideIcons.plus,
                          title: 'Nouveau\nnuméro',
                          color: const Color(0xFFB5E48C), // Virelo Green
                          onTap: _showNewNumberDialog,
                        )),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildQuickActionCard(
                          icon: LucideIcons.scanLine,
                          title: 'Scanner\nQR / NFC',
                          color: const Color(0xFF94A3B8), // Slate grey doux
                          onTap: () async {
                            final phone = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ScanContactPage()),
                            );
                            if (phone != null && phone is String) {
                              _selectContact('Contact Scanné', phone);
                            }
                          },
                        )),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
            
            // Zone Contenu (Récents & Contacts)
            SliverFillRemaining(
              hasScrollBody: true,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1D21), // Gris foncé très élégant pour contraster avec le fond pur
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    // Indicateur de glissement centré
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3138),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: _isLoadingContacts 
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB5E48C)))
                          : _contacts.isEmpty 
                            ? _buildRecentContacts()
                            : _buildContactsList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentContacts() {
    if (_isLoadingRecents) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFB5E48C)));
    }

    final recents = _recentContacts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favoris & Récents',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_contacts.isEmpty)
                TextButton(
                  onPressed: _fetchContacts,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB5E48C),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('Voir contacts', style: AppTextStyles.labelMedium),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: recents.isEmpty
            ? Center(
                child: Text(
                  'Aucun contact récent',
                  style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF8B93A8)),
                ),
              )
            : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            itemCount: recents.length,
            itemBuilder: (context, index) {
              final contact = recents[index];
              return _buildContactTile(
                name: contact['name'] as String,
                subtitle: contact['phone'] as String,
                avatarColor: Color(contact['color'] as int),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Text(
            'Tous les contacts',
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            itemCount: _contacts.length,
            itemBuilder: (context, index) {
              final contact = _contacts[index];
              final name = contact.displayName ?? 'Inconnu';
              final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
              
              final colors = [0xFFD8B4E2, 0xFFF9C846, 0xFF76C893, 0xFF83C5BE, 0xFFE29578];
              final avatarColor = Color(colors[name.length % colors.length]);

              return _buildContactTile(
                name: name,
                subtitle: phone,
                avatarColor: avatarColor,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required String name,
    required String subtitle,
    required Color avatarColor,
  }) {
    final firstChar = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return InkWell(
      onTap: () => _selectContact(name, subtitle),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2228),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  firstChar,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: avatarColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF8B93A8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Color(0xFF4A5168), size: 20),
          ],
        ),
      ),
    );
  }
}
