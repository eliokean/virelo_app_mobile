import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'generate_payment_qr_pin_page.dart';

class GeneratePaymentQrAmountPage extends StatefulWidget {
  const GeneratePaymentQrAmountPage({super.key});

  @override
  State<GeneratePaymentQrAmountPage> createState() => _GeneratePaymentQrAmountPageState();
}

class _GeneratePaymentQrAmountPageState extends State<GeneratePaymentQrAmountPage> {
  String _amount = "0";
  double _offlineBudget = 0.0;
  bool _isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final authService = AuthService(ApiClient());
      final offlineStorage = OfflineStorageService(authService);
      final budget = await offlineStorage.getOfflineBudget();
      if (mounted) {
        setState(() {
          _offlineBudget = budget;
          _isLoadingBalance = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
      }
    }
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_amount == "0") {
        if (digit != "0" && digit != "00") {
          _amount = digit;
        }
      } else {
        if (_amount.length + digit.length > 9) return;
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
    final result = StringBuffer();
    for (int i = 0; i < _amount.length; i++) {
      if (i > 0 && (_amount.length - i) % 3 == 0) result.write(' ');
      result.write(_amount[i]);
    }
    return result.toString();
  }

  void _handleContinue() {
    final amountValue = double.tryParse(_amount) ?? 0.0;
    if (amountValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant valide')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GeneratePaymentQrPinPage(amount: amountValue),
      ),
    );
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
                      'Paiement sans contact',
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
                          _isLoadingBalance 
                              ? const SizedBox(
                                  height: 14, 
                                  width: 14, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B93A8))
                                )
                              : Text(
                                  _offlineBudget > 0
                                      ? 'Budget hors-ligne: ${_offlineBudget.toInt()} FCFA'
                                      : 'Paiement sans contact NFC / QR',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: const Color(0xFF8B93A8),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ],
                      ),
                    ),

                    // Numpad & Continue Button
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
                              onPressed: _amount == "0" ? null : _handleContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
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
                                    'Continuer',
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
        _buildNumpadButton('00'),
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
