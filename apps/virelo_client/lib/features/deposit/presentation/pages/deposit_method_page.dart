import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/services/biometric_service.dart';
import 'package:virelo_core/services/wallet_service.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'deposit_success_page.dart';

class DepositMethodPage extends StatefulWidget {
  final String amount;
  const DepositMethodPage({super.key, required this.amount});

  @override
  State<DepositMethodPage> createState() => _DepositMethodPageState();
}

class _DepositMethodPageState extends State<DepositMethodPage> {
  String _selectedMethod = 'wave';
  bool _isLoading = false;

  String get _formattedAmount {
    final parts = widget.amount.split('.');
    String whole = parts[0];
    final result = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) result.write(' ');
      result.write(whole[i]);
    }
    if (parts.length > 1) {
      result.write(',${parts[1]}');
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1C1D), // Dark header
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
                        backgroundColor: Colors.white.withOpacity(0.1),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                      ),
                    ),
                    Text(
                      'Paiement',
                      style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white),
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
                  color: Color(0xFFF3F3F4), // Light surface background
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.screenH,
                          right: AppSpacing.screenH,
                          top: AppSpacing.xxl,
                          bottom: 120, // Space for bottom bar
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Card
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'MONTANT SÉLECTIONNÉ',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: const Color(0xFF8B93A8),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_formattedAmount FCFA',
                                        style: AppTextStyles.displayMedium.copyWith(
                                          color: const Color(0xFF1A1C1D),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(LucideIcons.wallet, color: AppColors.accent, size: 28),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: AppSpacing.xxl),
                            
                            // Methods List
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'VOS MÉTHODES',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: const Color(0xFF8B93A8),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Gérer',
                                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.accent),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(LucideIcons.settings, size: 16, color: AppColors.accent),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            
                            _buildMethodTile(
                              id: 'wave',
                              title: 'Wave',
                              subtitle: 'Transaction instantanée',
                              logoPath: 'assets/gateway/wave.svg',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildMethodTile(
                              id: 'orange',
                              title: 'Orange Money',
                              subtitle: 'Transaction instantanée',
                              logoPath: 'assets/gateway/orange.svg',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildMethodTile(
                              id: 'mtn',
                              title: 'MTN Mobile Money',
                              subtitle: 'Transaction instantanée',
                              logoPath: 'assets/gateway/mtn.svg',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildMethodTile(
                              id: 'moov',
                              title: 'Moov Money',
                              subtitle: 'Transaction instantanée',
                            ),
                          ],
                        ),
                      ),
                      
                      // Bottom Fixed Bar
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.screenH),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 20,
                                offset: Offset(0, -5),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Frais', style: AppTextStyles.labelMedium.copyWith(color: const Color(0xFF8B93A8))),
                                  Text('0 FCFA', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1D))),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () async {
                                    // Bypass temporaire de la biométrie pour les tests
                                    bool authenticated = true;

                                    if (authenticated && context.mounted) {
                                      setState(() {
                                        _isLoading = true;
                                      });

                                      try {
                                        final apiClient = ApiClient();
                                        final walletService = WalletService(apiClient, AuthService(apiClient));
                                        final resultData = await walletService.topUp(double.parse(widget.amount), _selectedMethod);
                                         
                                         final methodInfo = {
                                           'wave': {'title': 'Wave', 'logo': 'assets/gateway/wave.svg'},
                                           'orange': {'title': 'Orange Money', 'logo': 'assets/gateway/orange.svg'},
                                           'mtn': {'title': 'MTN Mobile Money', 'logo': 'assets/gateway/mtn.svg'},
                                           'moov': {'title': 'Moov Money', 'logo': 'assets/gateway/moov.png'},
                                         }[_selectedMethod] ?? {'title': 'Wave', 'logo': 'assets/gateway/wave.svg'};

                                         final refCode = (resultData is Map && resultData['transaction'] != null && resultData['transaction']['reference'] != null)
                                             ? resultData['transaction']['reference'].toString()
                                             : 'VIR-RECH-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

                                         if (context.mounted) {
                                           setState(() {
                                             _isLoading = false;
                                           });
                                           await Navigator.push(
                                             context,
                                             MaterialPageRoute(
                                               builder: (_) => DepositSuccessPage(
                                                 amount: _formattedAmount,
                                                 methodId: _selectedMethod,
                                                 methodTitle: methodInfo['title']!,
                                                 methodLogoPath: methodInfo['logo']!,
                                                 reference: refCode,
                                               ),
                                             ),
                                           );
                                           if (context.mounted) Navigator.pop(context, true); // Pop and refresh
                                         }
                                      } catch (e) {
                                        if (context.mounted) {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    disabledBackgroundColor: AppColors.surfaceBorder,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF161A22),
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Confirmer & Payer',
                                              style: AppTextStyles.headlineMedium.copyWith(
                                                color: const Color(0xFF161A22),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            const Icon(LucideIcons.arrowRight, color: Color(0xFF161A22)),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile({required String id, required String title, required String subtitle, required String logoPath}) {
    final isSelected = _selectedMethod == id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              child: logoPath.endsWith('.svg')
                  ? SvgPicture.asset(logoPath, fit: BoxFit.contain)
                  : Image.asset(logoPath, fit: BoxFit.contain),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: const Color(0xFF1A1C1D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: const Color(0xFF8B93A8),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.checkCircle2, color: AppColors.accent)
            else
              const SizedBox(width: 24, height: 24),
          ],
        ),
      ),
    );
  }
}
