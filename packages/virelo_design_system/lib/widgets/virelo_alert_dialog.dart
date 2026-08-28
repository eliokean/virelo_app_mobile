import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';

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
  final bool isLightMode;

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
    this.isLightMode = true,
  });

  Color get _mainColor {
    switch (alertType) {
      case VireloAlertType.kyc:
        return const Color(0xFFFF9800); // Amber / Orange
      case VireloAlertType.limit:
        return const Color(0xFFFF4D4D); // Red
      case VireloAlertType.warning:
        return const Color(0xFFFFA000);
      case VireloAlertType.error:
        return const Color(0xFFFF4D4D); // Soft Red
      case VireloAlertType.success:
        return const Color(0xFF00D084); // Vibrant Green
      case VireloAlertType.info:
        return AppColors.accent;
    }
  }

  Color get _lightBgColor {
    switch (alertType) {
      case VireloAlertType.kyc:
      case VireloAlertType.warning:
        return const Color(0xFFFFF8E7);
      case VireloAlertType.limit:
      case VireloAlertType.error:
        return const Color(0xFFFFEBEB);
      case VireloAlertType.success:
        return const Color(0xFFE6F9F2);
      case VireloAlertType.info:
        return const Color(0xFFE8F4FD);
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
        return 'KYC REQUISE';
      case VireloAlertType.limit:
        return 'LIMITE ATTEINTE';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : const Color(0xFF1E232A),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Circular Illustration Icon Badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _lightBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _mainColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icon,
                    size: 32,
                    color: _mainColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Badge Tag (Optional)
            if (badgeText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _lightBgColor,
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
              const SizedBox(height: AppSpacing.sm),
            ],

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: isLightMode ? const Color(0xFF1D2939) : Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Message Body
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isLightMode ? const Color(0xFF667085) : const Color(0xFF9EA3B0),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Primary Action Button (Pill shaped)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mainColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onPrimaryPressed != null) {
                    onPrimaryPressed!();
                  }
                },
                child: Text(
                  primaryButtonLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isLightMode ? const Color(0xFF667085) : const Color(0xFF9EA3B0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Popups d'aide prédéfinis (Succès, Erreur, Warning, Info, KYC, Limites)
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String primaryButtonLabel = 'CONTINUER',
    VoidCallback? onPrimaryPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VireloAlertDialog(
        alertType: VireloAlertType.success,
        title: title,
        message: message,
        primaryButtonLabel: primaryButtonLabel,
        onPrimaryPressed: onPrimaryPressed,
      ),
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String primaryButtonLabel = 'RÉESSAYER',
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonLabel,
    VoidCallback? onSecondaryPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VireloAlertDialog(
        alertType: VireloAlertType.error,
        title: title,
        message: message,
        primaryButtonLabel: primaryButtonLabel,
        onPrimaryPressed: onPrimaryPressed,
        secondaryButtonLabel: secondaryButtonLabel,
        onSecondaryPressed: onSecondaryPressed,
      ),
    );
  }

  static Future<void> showWarning(
    BuildContext context, {
    required String title,
    required String message,
    String primaryButtonLabel = 'COMPRIS',
    VoidCallback? onPrimaryPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VireloAlertDialog(
        alertType: VireloAlertType.warning,
        title: title,
        message: message,
        primaryButtonLabel: primaryButtonLabel,
        onPrimaryPressed: onPrimaryPressed,
      ),
    );
  }

  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String primaryButtonLabel = 'OK',
    VoidCallback? onPrimaryPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VireloAlertDialog(
        alertType: VireloAlertType.info,
        title: title,
        message: message,
        primaryButtonLabel: primaryButtonLabel,
        onPrimaryPressed: onPrimaryPressed,
      ),
    );
  }

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
            'Votre profil n\'est pas encore vérifié. Soumettez votre pièce d\'identité (KYC) pour débloquer votre séquestre et allouer jusqu\'à 50% de vos fonds en mode hors-ligne.',
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
