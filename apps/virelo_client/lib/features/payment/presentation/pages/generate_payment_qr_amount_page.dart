import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_primary_button.dart';
import 'generate_payment_qr_pin_page.dart';

class GeneratePaymentQrAmountPage extends StatefulWidget {
  const GeneratePaymentQrAmountPage({super.key});

  @override
  State<GeneratePaymentQrAmountPage> createState() => _GeneratePaymentQrAmountPageState();
}

class _GeneratePaymentQrAmountPageState extends State<GeneratePaymentQrAmountPage> {
  String _amount = '0';

  void _onDigitTap(String digit) {
    setState(() {
      if (_amount == '0') {
        _amount = digit;
      } else if (_amount.length < 7) {
        _amount += digit;
      }
    });
  }

  void _onDeleteTap() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payer en magasin',
          style: AppTextStyles.headlineMedium,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            Text(
              'Montant à payer',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _amount,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'FCFA',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(flex: 2),
            _buildKeypad(),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: VireloPrimaryButton(
                label: 'Continuer',
                icon: LucideIcons.arrowRight,
                onPressed: _handleContinue,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildKeypadButton('00'),
              _buildKeypadButton('0'),
              _buildKeypadButton('DEL', isDelete: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String value, {bool isDelete = false}) {
    return InkWell(
      onTap: () => isDelete ? _onDeleteTap() : _onDigitTap(value),
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: isDelete
            ? const Icon(LucideIcons.delete, color: AppColors.textPrimary)
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
      ),
    );
  }
}
