import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/network/api_client.dart';
import '../../../auth/presentation/pages/login_page.dart';

class WalletHeader extends StatelessWidget {
  final String userName;

  const WalletHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salut ${userName.split(' ').first} !',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF161A22),
                  ),
                ),
                Text(
                  'Bienvenue dans votre\nportefeuille multi-devises',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF4A5168),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final authService = AuthService(ApiClient());
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: _buildIconButton(LucideIcons.logOut),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildIconButton(LucideIcons.bell),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: const Color(0xFF161A22),
      ),
    );
  }
}
