import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import '../../../profile/presentation/pages/merchant_settings_page.dart';

class MerchantHeader extends StatelessWidget {
  final String merchantName;
  final VoidCallback? onSettingsChanged;

  const MerchantHeader({
    super.key,
    required this.merchantName,
    this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MerchantSettingsPage(merchantName: merchantName),
                  ),
                );
                onSettingsChanged?.call();
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.settings,
                  size: 20,
                  color: Color(0xFF161A22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
