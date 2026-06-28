import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_spacing.dart';

class VireloTextField extends StatelessWidget {
  final String        hint;
  final IconData?     prefixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String?       Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool obscureText;

  const VireloTextField({
    super.key,
    required this.hint,
    this.prefixIcon,
    this.controller,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      keyboardType: keyboardType,
      validator:    validator,
      onChanged:    onChanged,
      obscureText:  obscureText,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
        filled:    true,
        fillColor: AppColors.surfaceCard,
        prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: AppColors.textTertiary)
          : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
