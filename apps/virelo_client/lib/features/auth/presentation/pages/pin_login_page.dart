import 'package:flutter/material.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_pin_pad.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';
import 'login_page.dart';
import 'package:virelo_client/core/services/push_notification_service.dart';

class PinLoginPage extends StatefulWidget {
  const PinLoginPage({super.key});

  @override
  State<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends State<PinLoginPage> {
  String _pin = '';
  late final AuthService _authService;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(ApiClient());
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await _authService.isBiometricsAvailable();
    if (mounted) {
      setState(() => _biometricsAvailable = available);
      if (available) {
        _handleBiometrics(); // Tenter la biométrie automatiquement au lancement
      }
    }
  }

  Future<void> _handleBiometrics() async {
    final success = await _authService.authenticateWithBiometrics();
    if (success && mounted) {
      _navigateToWallet();
    }
  }

  void _onDigitTap(String digit) {
    if (_pin.length < 4) {
      setState(() => _pin += digit);
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeleteTap() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _verifyPin() async {
    final isValid = await _authService.verifyLocalPin(_pin);
    if (isValid && mounted) {
      _navigateToWallet();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code PIN incorrect'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _pin = '');
      }
    }
  }

  void _navigateToWallet() {
    PushNotificationService().sendTokenToBackend();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WalletPage()),
    );
  }

  void _logoutAndSwitchUser() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text(
              'Déverrouiller Virelo',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Saisissez votre code PIN',
              style: AppTextStyles.bodyMedium,
            ),
            const Spacer(flex: 2),
            
            VireloPinDots(pinLength: _pin.length),
            
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: _logoutAndSwitchUser,
              child: Text(
                'Oublié ? Se déconnecter',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent),
              ),
            ),
            
            const Spacer(flex: 3),
            VireloPinPad(
              onDigitTap: _onDigitTap,
              onDeleteTap: _onDeleteTap,
              showBiometric: _biometricsAvailable,
              onBiometricTap: _handleBiometrics,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
