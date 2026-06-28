import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'deposit_method_page.dart';

class DepositAmountPage extends StatefulWidget {
  const DepositAmountPage({super.key});

  @override
  State<DepositAmountPage> createState() => _DepositAmountPageState();
}

class _DepositAmountPageState extends State<DepositAmountPage> {
  String _amount = "0";

  void _appendDigit(String digit) {
    setState(() {
      if (_amount == "0" && digit != ".") {
        _amount = digit;
      } else {
        if (digit == "." && _amount.contains(".")) return;
        if (_amount.replaceFirst('.', '').length >= 9) return;
        _amount += digit;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _deleteDigit() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = "0";
      }
    });
    HapticFeedback.lightImpact();
  }

  String get _formattedAmount {
    if (_amount == "0") return "0";
    final parts = _amount.split('.');
    String whole = parts[0];
    final result = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) result.write(' ');
      result.write(whole[i]);
    }
    if (parts.length > 1) {
      result.write(',${parts[1]}');
    } else if (_amount.endsWith('.')) {
      result.write(',');
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
        backgroundColor: const Color(0xFF1A1C1D), // Dark header background
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
                      'Recharger',
                      style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 48), // Spacer
                  ],
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9FA), // Light surface
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    // Amount Display
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8E8E9),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'FCFA',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: const Color(0xFF1A1C1D),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              child: Text(
                                _formattedAmount,
                                style: AppTextStyles.displayLarge.copyWith(
                                  fontSize: 64,
                                  color: const Color(0xFF1A1C1D),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Solde actuel: 12 329 FCFA',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: const Color(0xFF8B93A8),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Numpad & Next Button
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.screenH),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                          _buildNumpad(),
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _amount == "0" ? null : () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => DepositMethodPage(amount: _amount)),
                                );
                                if (result == true) {
                                  if (context.mounted) Navigator.pop(context, true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent, // Virelo Green instead of HTML Lime
                                disabledBackgroundColor: AppColors.surfaceBorder,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Suivant',
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
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (int i = 1; i <= 9; i++) _buildNumpadButton(i.toString()),
        _buildNumpadButton('.'),
        _buildNumpadButton('0'),
        _buildNumpadButton('del', isIcon: true),
      ],
    );
  }

  Widget _buildNumpadButton(String value, {bool isIcon = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isIcon) {
            _deleteDigit();
          } else {
            _appendDigit(value);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: isIcon
              ? const Icon(LucideIcons.delete, size: 28, color: Color(0xFF1A1C1D))
              : Text(
                  value,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: const Color(0xFF1A1C1D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
