import 'package:flutter/material.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BalanceHeroCard extends StatefulWidget {
  final String balance;
  final bool isLoading;
  
  const BalanceHeroCard({
    super.key,
    required this.balance,
    this.isLoading = false,
  });

  @override
  State<BalanceHeroCard> createState() => _BalanceHeroCardState();
}

class _BalanceHeroCardState extends State<BalanceHeroCard> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _loadVisibilityState();
  }

  Future<void> _loadVisibilityState() async {
    try {
      final val = await _storage.read(key: 'balance_visible');
      if (val != null && mounted) {
        setState(() {
          _isVisible = val == 'true';
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleVisibility() async {
    final newState = !_isVisible;
    setState(() {
      _isVisible = newState;
    });
    await _storage.write(key: 'balance_visible', value: newState.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Currency Chip and Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF161A22),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🇨🇮', style: TextStyle(fontSize: 16, height: 1)),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.currency_exchange, color: Colors.white, size: 14),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'FCFA (XOF)',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                onPressed: _toggleVisibility,
                icon: Icon(
                  _isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                  color: const Color(0xFF161A22),
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Amount
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'FCFA ',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: const Color(0xFF161A22),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                widget.isLoading 
                  ? const SizedBox(
                      height: 40, 
                      width: 40, 
                      child: CircularProgressIndicator(color: Color(0xFF161A22))
                    )
                  : Text(
                      _isVisible ? _formatBalance(widget.balance) : '••••••',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: const Color(0xFF161A22),
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBalance(String bal) {
    try {
      final doubleValue = double.parse(bal);
      final intValue = doubleValue.toInt();
      final stringValue = intValue.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < stringValue.length; i++) {
        if (i > 0 && (stringValue.length - i) % 3 == 0) buffer.write(' ');
        buffer.write(stringValue[i]);
      }
      return buffer.toString();
    } catch (e) {
      return bal;
    }
  }
}
