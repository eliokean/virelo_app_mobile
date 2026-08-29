import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';

enum VireloAlertType {
  kyc,
  limit,
  frozen,
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
      case VireloAlertType.frozen:
        return const Color(0xFF00B4D8); // Ice Cyan / Blue
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
      case VireloAlertType.frozen:
        return const Color(0xFFE8F7FA);
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
      case VireloAlertType.frozen:
        return LucideIcons.shieldAlert;
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
      case VireloAlertType.frozen:
        return 'COMPTE GELÉ';
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: isLightMode ? Colors.white : const Color(0xFF1E222D),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Decorative Graphic
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 28, bottom: 20),
                decoration: BoxDecoration(
                  color: isLightMode ? _lightBgColor : _mainColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _mainColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _mainColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _icon,
                        size: 34,
                        color: _mainColor,
                      ),
                    ),
                  ),
                ),
              ),

              // Content Area
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  children: [
                    // Badge Text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _mainColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _defaultBadge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _mainColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: isLightMode ? const Color(0xFF161A22) : Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Message
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isLightMode ? const Color(0xFF5E6573) : const Color(0xFFA0A6B2),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _mainColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          primaryButtonLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // Secondary Action Button (Optional)
                    if (secondaryButtonLabel != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: TextButton(
                          onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: isLightMode ? const Color(0xFF707784) : const Color(0xFFA0A6B2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            secondaryButtonLabel!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPER STATIC METHODS ====================

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

  static Future<void> showAccountFrozen(
    BuildContext context, {
    String? title,
    String? message,
    VoidCallback? onContactSupport,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VireloAlertDialog(
        alertType: VireloAlertType.frozen,
        title: title ?? 'Compte Temporairement Gelé',
        message: message ??
            'Votre compte fait l\'objet d\'une mesure de sécurité conservatoire. Les transferts d\'argent, paiements et recharges sont temporairement suspendus.',
        badgeText: 'SÉCURITÉ & CONFORMITÉ',
        primaryButtonLabel: 'Compris',
        onPrimaryPressed: () => Navigator.of(context).pop(),
        secondaryButtonLabel: onContactSupport != null ? 'Contacter le Support' : null,
        onSecondaryPressed: onContactSupport,
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
