import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/network/api_client.dart';
import '../../../../config/routes/route_names.dart';
import 'package:go_router/go_router.dart';

class MerchantHeader extends StatelessWidget {
  final String merchantName;

  const MerchantHeader({super.key, required this.merchantName});

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
                  'Espace Marchand',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFF4A5168),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  merchantName,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF161A22),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final authService = AuthService(ApiClient());
              await authService.logout();
              if (context.mounted) {
                // Return to login logic, assuming you have a way to handle it or just clear auth and redirect
                // Here we just navigate back to Auth/Login if route exists
              }
            },
            child: _buildIconButton(LucideIcons.logOut),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildIconButton(LucideIcons.settings),
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
