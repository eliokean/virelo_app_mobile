import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import 'transfer_amount_page.dart';

class TransferContactPage extends StatefulWidget {
  const TransferContactPage({super.key});

  @override
  State<TransferContactPage> createState() => _TransferContactPageState();
}

class _TransferContactPageState extends State<TransferContactPage> {
  List<Contact> _contacts = [];
  bool _isLoadingContacts = false;

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

  void _selectContact(String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferAmountPage(beneficiaryName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1C1D),
        body: Column(
          children: [
            // Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                      ),
                    ),
                    Text(
                      'Bénéficiaire',
                      style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            icon: Icon(LucideIcons.search, color: Color(0xFF8B93A8)),
                            hintText: 'Rechercher un nom ou numéro',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                      child: InkWell(
                        onTap: _fetchContacts,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.contact, color: Color(0xFF161A22)),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Ouvrir les contacts',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: const Color(0xFF161A22),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: _isLoadingContacts 
                          ? const Center(child: CircularProgressIndicator())
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

  Widget _buildRecentContacts() {
    // Dummy recent contacts
    final recents = ['Jean Dupont', 'Marie Curie', 'Paul Pogba'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Text(
            'Récents',
            style: AppTextStyles.labelLarge.copyWith(
              color: const Color(0xFF8B93A8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            itemCount: recents.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (context, index) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE8E8E9),
                  child: Text(
                    recents[index].substring(0, 1),
                    style: AppTextStyles.headlineMedium.copyWith(color: const Color(0xFF161A22)),
                  ),
                ),
                title: Text(recents[index], style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                onTap: () => _selectContact(recents[index]),
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
            style: AppTextStyles.labelLarge.copyWith(
              color: const Color(0xFF8B93A8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            itemCount: _contacts.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (context, index) {
              final contact = _contacts[index];
              final name = contact.displayName ?? 'Inconnu';
              final firstChar = name.isNotEmpty ? name[0].toUpperCase() : '?';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE8E8E9),
                  child: Text(
                    firstChar,
                    style: AppTextStyles.headlineMedium.copyWith(color: const Color(0xFF161A22)),
                  ),
                ),
                title: Text(
                  name, 
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)
                ),
                subtitle: contact.phones.isNotEmpty 
                    ? Text(contact.phones.first.number, style: AppTextStyles.bodyMedium)
                    : null,
                onTap: () => _selectContact(name),
              );
            },
          ),
        ),
      ],
    );
  }
}
