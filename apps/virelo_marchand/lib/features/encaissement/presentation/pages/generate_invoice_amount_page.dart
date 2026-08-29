import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'display_invoice_qr_page.dart';

class GenerateInvoiceAmountPage extends StatefulWidget {
  final int merchantId;
  final String merchantName;

  const GenerateInvoiceAmountPage({
    super.key,
    required this.merchantId,
    required this.merchantName,
  });

  @override
  State<GenerateInvoiceAmountPage> createState() => _GenerateInvoiceAmountPageState();
}

class _GenerateInvoiceAmountPageState extends State<GenerateInvoiceAmountPage> {
  String _amount = "0";

  void _appendDigit(String digit) {
    setState(() {
      if (_amount == "0") {
        if (digit == "00" || digit == "0") return;
        _amount = digit;
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

  void _addQuickAmount(int value) {
    setState(() {
      final current = int.tryParse(_amount) ?? 0;
      final next = current + value;
      if (next.toString().length <= 9) {
        _amount = next.toString();
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
    final doubleAmount = double.tryParse(_amount.replaceAll(' ', '')) ?? 0;
    if (doubleAmount <= 0) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DisplayInvoiceQrPage(
          merchantId: widget.merchantId,
          merchantName: widget.merchantName,
          amount: doubleAmount,
        ),
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
        backgroundColor: const Color(0xFF1A1C1D),
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
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
                      'Générer Facture QR',
                      style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E8E9),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                'FCFA',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: const Color(0xFF1A1C1D),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formattedAmount,
                                style: AppTextStyles.displayLarge.copyWith(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1C1D),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildQuickPill('+500', 500),
                                  _buildQuickPill('+1 000', 1000),
                                  _buildQuickPill('+2 000', 2000),
                                  _buildQuickPill('+5 000', 5000),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.lg),
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
                          const SizedBox(height: AppSpacing.lg),
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

  Widget _buildQuickPill(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1C1D),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE2E4E8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        onPressed: () => _addQuickAmount(value),
      ),
    );
  }

  Widget _buildNumpad() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      mainAxisSpacing: 4,
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
              ? const Icon(LucideIcons.delete, size: 26, color: Color(0xFF1A1C1D))
              : Text(
                  value,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: const Color(0xFF1A1C1D),
                    fontWeight: FontWeight.w600,
                    fontSize: 26,
                  ),
                ),
        ),
      ),
    );
  }
}
