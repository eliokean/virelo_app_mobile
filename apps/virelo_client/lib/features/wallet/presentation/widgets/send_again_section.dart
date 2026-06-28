import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';

class SendAgainSection extends StatelessWidget {
  const SendAgainSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Récents',
          style: AppTextStyles.labelLarge.copyWith(
            color: const Color(0xFF161A22),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildInitialsAvatar('C.B.'),
            _buildInitialsAvatar('L.D.'),
            _buildInitialsAvatar('M.F.'),
            _buildInitialsAvatar('B.A.'),
            _buildInitialsAvatar('B.A.'),
            _buildAddButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.headlineMedium.copyWith(
            color: const Color(0xFF161A22),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: const BoxDecoration(
            color: Color(0xFF161A22),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: const Icon(
            LucideIcons.plus,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
