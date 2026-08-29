import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/transaction_details_bottom_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class DepositSuccessPage extends StatelessWidget {
  final String amount;
  final String methodId;
  final String methodTitle;
  final String methodLogoPath;
  final String reference;

  const DepositSuccessPage({
    super.key,
    required this.amount,
    this.methodId = 'wave',
    this.methodTitle = 'Wave',
    this.methodLogoPath = 'assets/gateway/wave.svg',
    this.reference = '#DW-98234-LX',
  });

  String get _currentFormattedDate {
    final now = DateTime.now();
    return "Aujourd'hui, ${DateFormat('HH:mm').format(now)}";
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
                    const SizedBox(width: 48), // Spacer
                    Text(
                      'Portefeuille',
                      style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white),
                      onPressed: () => Navigator.pop(context, true),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9FA), // Light surface background
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 48),
                        child: Column(
                          children: [
                            // Success Icon
                            _buildPulseIcon(),
                            const SizedBox(height: AppSpacing.xxl),
                            
                            // Success Text
                            Text(
                              'Succès !',
                              style: AppTextStyles.displayLarge.copyWith(
                                color: const Color(0xFF1A1C1D),
                                fontSize: 36,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: AppTextStyles.bodyLarge.copyWith(color: const Color(0xFF8B93A8)),
                                children: [
                                  const TextSpan(text: 'Vous avez ajouté avec succès '),
                                  TextSpan(
                                    text: '$amount FCFA',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1D)),
                                  ),
                                  const TextSpan(text: ' à votre portefeuille.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 48),
                            
                            // Transaction Details
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow('Date', _currentFormattedDate),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildMethodRow('Méthode', methodTitle, methodLogoPath),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildDetailRow('ID Transaction', reference),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                    child: Divider(color: Color(0xFFE2E2E3), height: 1),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Montant Total',
                                        style: AppTextStyles.labelMedium.copyWith(
                                          color: const Color(0xFF8B93A8),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '$amount FCFA',
                                        style: AppTextStyles.headlineLarge.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Buttons
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.screenH),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Retour à l\'accueil',
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    color: const Color(0xFF161A22),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: TextButton(
                                onPressed: () {
                                  TransactionDetailsBottomSheet.show(context, {
                                    'title': 'Rechargement $methodTitle',
                                    'amount': amount.replaceAll(' ', ''),
                                    'is_negative': false,
                                    'status': 'completed',
                                    'reference': reference,
                                    'type': 'recharge',
                                    'date': DateTime.now().toIso8601String(),
                                  });
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFEEEEEF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  'Voir le reçu',
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    color: const Color(0xFF1A1C1D),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.labelMedium.copyWith(color: const Color(0xFF8B93A8))),
        Text(value, style: AppTextStyles.labelMedium.copyWith(color: const Color(0xFF1A1C1D), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMethodRow(String label, String method, String logoPath) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.labelMedium.copyWith(color: const Color(0xFF8B93A8))),
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              child: logoPath.endsWith('.svg')
                  ? SvgPicture.asset(logoPath, fit: BoxFit.contain)
                  : Image.asset(logoPath, fit: BoxFit.contain),
            ),
            const SizedBox(width: 8),
            Text(method, style: AppTextStyles.labelMedium.copyWith(color: const Color(0xFF1A1C1D), fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildPulseIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.checkCircle2,
                  color: Color(0xFF1A1C1D),
                  size: 48,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
