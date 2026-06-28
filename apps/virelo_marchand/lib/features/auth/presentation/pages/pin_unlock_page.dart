import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/services/biometric_service.dart';
import '../../../../config/routes/route_names.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _pin = '';
  final BiometricService _biometricService = BiometricService();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await _biometricService.canCheckBiometrics();
    if (mounted) {
      setState(() {
        _canCheckBiometrics = canCheck;
      });
      // Optionnel : déclencher la biométrie automatiquement à l'ouverture
      if (canCheck) {
        _authenticateWithBiometrics();
      }
    }
  }

  void _onKeyPress(String key) {
    if (_pin.length < 4) {
      setState(() {
        _pin += key;
      });
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeletePress() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _verifyPin() {
    // Pour la démo, on accepte "1234" ou on simule un appel API
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_pin == '1234') {
        context.goNamed(RouteNames.dashboard);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Code PIN incorrect (Astuce: 1234)'),
            backgroundColor: const Color(0xFFE29578),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() {
          _pin = ''; // Réinitialiser le PIN en cas d'erreur
        });
      }
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    final success = await _biometricService.authenticate('Veuillez vous authentifier pour accéder à votre caisse');
    if (success && mounted) {
      context.goNamed(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131517), // Premium Dark
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            // Logo / Titre
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB5E48C).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.store, size: 48, color: Color(0xFFB5E48C)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Boutique Centrale',
              style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Entrez votre code PIN pour déverrouiller',
              style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF8B93A8)),
            ),
            
            const Spacer(),
            
            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length ? const Color(0xFFB5E48C) : const Color(0xFF2C3138),
                    boxShadow: index < _pin.length ? [
                      const BoxShadow(
                        color: Color(0x33B5E48C),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ] : null,
                  ),
                );
              }),
            ),
            
            const Spacer(),
            
            // Numpad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              child: Column(
                children: [
                  _buildNumpadRow(['1', '2', '3']),
                  const SizedBox(height: AppSpacing.lg),
                  _buildNumpadRow(['4', '5', '6']),
                  const SizedBox(height: AppSpacing.lg),
                  _buildNumpadRow(['7', '8', '9']),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric button or empty space
                      _canCheckBiometrics 
                        ? _buildBiometricButton()
                        : const SizedBox(width: 70),
                      _buildNumpadButton('0'),
                      _buildNumpadDeleteButton(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _buildNumpadButton(k)).toList(),
    );
  }

  Widget _buildNumpadButton(String key) {
    return InkWell(
      onTap: () => _onKeyPress(key),
      customBorder: const CircleBorder(),
      splashColor: const Color(0xFFB5E48C).withValues(alpha: 0.2),
      highlightColor: const Color(0xFFB5E48C).withValues(alpha: 0.1),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: Text(
          key,
          style: AppTextStyles.displayMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildNumpadDeleteButton() {
    return InkWell(
      onTap: _onDeletePress,
      customBorder: const CircleBorder(),
      splashColor: const Color(0xFFE29578).withValues(alpha: 0.2),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: const Icon(LucideIcons.delete, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return InkWell(
      onTap: _authenticateWithBiometrics,
      customBorder: const CircleBorder(),
      splashColor: const Color(0xFFB5E48C).withValues(alpha: 0.2),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: const Icon(LucideIcons.fingerprint, color: Color(0xFFB5E48C), size: 32),
      ),
    );
  }
}
