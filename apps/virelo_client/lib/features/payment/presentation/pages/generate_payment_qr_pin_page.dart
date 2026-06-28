import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_pin_pad.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/wallet_service.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'generate_payment_qr_display_page.dart';

class GeneratePaymentQrPinPage extends StatefulWidget {
  final double amount;

  const GeneratePaymentQrPinPage({super.key, required this.amount});

  @override
  State<GeneratePaymentQrPinPage> createState() => _GeneratePaymentQrPinPageState();
}

class _GeneratePaymentQrPinPageState extends State<GeneratePaymentQrPinPage> {
  String _pin = '';
  bool _isLoading = false;
  late final WalletService _walletService;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _walletService = WalletService(apiClient, AuthService(apiClient));
  }

  void _onDigitTap(String digit) {
    if (_isLoading) return;

    if (_pin.length < 4) {
      setState(() => _pin += digit);
      if (_pin.length == 4) {
        _generateToken();
      }
    }
  }

  void _onDeleteTap() {
    if (_isLoading) return;

    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _generateToken() async {
    setState(() => _isLoading = true);

    try {
      final token = await _walletService.generateOfflinePaymentToken(widget.amount, _pin);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GeneratePaymentQrDisplayPage(
              amount: widget.amount,
              token: token,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _pin = '');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text(
              'Code PIN',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Confirmez le paiement de ${widget.amount} FCFA',
              style: AppTextStyles.bodyMedium,
            ),
            const Spacer(flex: 2),
            
            if (_isLoading)
              const CircularProgressIndicator(color: AppColors.accent)
            else
              VireloPinDots(pinLength: _pin.length),
            
            const Spacer(flex: 3),
            VireloPinPad(
              onDigitTap: _onDigitTap,
              onDeleteTap: _onDeleteTap,
              showBiometric: false, // Pas de biométrie pour la génération hors ligne
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
