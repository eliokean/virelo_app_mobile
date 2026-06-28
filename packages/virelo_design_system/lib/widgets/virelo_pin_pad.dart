import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class VireloPinPad extends StatelessWidget {
  final void Function(String digit) onDigitTap;
  final VoidCallback onDeleteTap;
  final VoidCallback? onBiometricTap;
  final bool showBiometric;

  const VireloPinPad({
    super.key,
    required this.onDigitTap,
    required this.onDeleteTap,
    this.onBiometricTap,
    this.showBiometric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAction(
              showBiometric ? LucideIcons.fingerprint : null,
              onBiometricTap,
            ),
            _buildKey('0'),
            _buildAction(LucideIcons.delete, onDeleteTap),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildKey(digit)).toList(),
    );
  }

  Widget _buildKey(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDigitTap(digit),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 65,
          height: 65,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceCard.withOpacity(0.5),
          ),
          child: Text(
            digit,
            style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildAction(IconData? icon, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 65,
          height: 65,
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: 28, color: AppColors.textPrimary)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class VireloPinDots extends StatelessWidget {
  final int pinLength;
  final int maxLength;

  const VireloPinDots({
    super.key,
    required this.pinLength,
    this.maxLength = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        final isFilled = index < pinLength;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.accent : AppColors.surfaceCard,
            border: Border.all(
              color: isFilled ? AppColors.accent : AppColors.textTertiary,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}
