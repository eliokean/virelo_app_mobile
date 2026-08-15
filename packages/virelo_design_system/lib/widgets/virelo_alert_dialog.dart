import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_primary_button.dart';

enum VireloAlertType {
  kyc,
  limit,
  warning,
  error,
  info,
  success,
}

class VireloAlertDialog extends StatelessWidget {
  final VireloAlertType alertType;
  final String title;
  final String message;
  final String? badgeText;
  final String primaryButtonLabel;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryPressed;
  final IconData? customIcon;

  const VireloAlertDialog({
    super.key,
    this.alertType = VireloAlertType.warning,
    required this.title,
    required this.message,
    this.badgeText,
    this.primaryButtonLabel = 'Compris',
    this.onPrimaryPressed,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
    this.customIcon,
  });

  Color get _mainColor {
    switch (alertType) {
      case VireloAlertType.kyc:
        return const Color(0xFFFF9800); // Amber / Orange KYC
      case VireloAlertType.limit:
        return const Color(0xFFE53935); // Crimson Red Limit
      case VireloAlertType.warning:
        return const Color(0xFFFFA000);
      case VireloAlertType.error:
        return AppColors.error;
      case VireloAlertType.success:
        return const Color(0xFF00D084);
      case VireloAlertType.info:
        return AppColors.accent;
    }
  }

  IconData get _icon {
    if (customIcon != null) return customIcon!;
    switch (alertType) {
      case VireloAlertType.kyc:
        return LucideIcons.shieldAlert;
      case VireloAlertType.limit:
        return LucideIcons.lock;
      case VireloAlertType.warning:
        return LucideIcons.alertTriangle;
      case VireloAlertType.error:
        return LucideIcons.alertCircle;
      case VireloAlertType.success:
        return LucideIcons.checkCircle2;
      case VireloAlertType.info:
        return LucideIcons.info;
    }
  }

  String get _defaultBadge {
    if (badgeText != null) return badgeText!;
    switch (alertType) {
      case VireloAlertType.kyc:
        return 'VÉRIFICATION KYC REQUISE';
      case VireloAlertType.limit:
        return 'LIMITE DE SÉQUESTRE ATTEINTE';
      case VireloAlertType.warning:
        return 'AVERTISSEMENT';
      case VireloAlertType.error:
        return 'ERREUR';
      case VireloAlertType.success:
        return 'SUCCÈS';
      case VireloAlertType.info:
        return 'INFORMATION';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: const Color(0xFF1E232A), // Dark elegant card background
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _mainColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _mainColor.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge & Logo Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _mainColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: _mainColor.withOpacity(0.3), width: 1),
              ),
              child: Icon(
                _icon,
                size: 40,
                color: _mainColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Badge Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _mainColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _defaultBadge.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _mainColor,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Message Body
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF9EA3B0),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Actions Buttons
            SizedBox(
              width: double.infinity,
              child: VireloPrimaryButton(
                label: primaryButtonLabel,
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onPrimaryPressed != null) {
                    onPrimaryPressed!();
                  }
                },
              ),
            ),

            if (secondaryButtonLabel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onSecondaryPressed != null) {
                    onSecondaryPressed!();
                  }
                },
                child: Text(
                  secondaryButtonLabel!,
                  style: AppTextStyles.button.copyWith(
                    color: const Color(0xFF9EA3B0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Popups d'aide prédéfinis
  static Future<void> showKycRequired(
    BuildContext context, {
    String? title,
    String? message,
    VoidCallback? onCompleteKyc,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VireloAlertDialog(
        alertType: VireloAlertType.kyc,
        title: title ?? 'Vérification d\'identité requise',
        message: message ??
            'Votre profil n\'est pas encore vérifié. Soumettez votre pièce d\'identité (KYC) pour débloquer votre séquestre et augmenter vos plafonds jusqu\'à 500 000 FCFA.',
        badgeText: 'SÉCURITÉ & KYC',
        primaryButtonLabel: 'Compléter mon KYC',
        onPrimaryPressed: onCompleteKyc,
        secondaryButtonLabel: 'Plus tard',
      ),
    );
  }

  static Future<void> showLimitExceeded(
    BuildContext context, {
    String? title,
    String? message,
    VoidCallback? onUpgradeKyc,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VireloAlertDialog(
        alertType: VireloAlertType.limit,
        title: title ?? 'Plafond de Séquestre Atteint',
        message: message ??
            'Vous ne pouvez pas allouer plus de 50% de votre solde total au mode hors-ligne. Soumettez vos documents KYC pour augmenter votre limite.',
        badgeText: 'LIMITE D\'ALLOCATION',
        primaryButtonLabel: onUpgradeKyc != null ? 'Augmenter mes limites' : 'Compris',
        onPrimaryPressed: onUpgradeKyc,
        secondaryButtonLabel: onUpgradeKyc != null ? 'Fermer' : null,
      ),
    );
  }
}
