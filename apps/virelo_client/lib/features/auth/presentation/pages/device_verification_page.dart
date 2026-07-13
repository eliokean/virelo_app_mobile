import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virelo_design_system/virelo_design_system.dart';
import 'package:virelo_core/virelo_core.dart';
import '../../../../main.dart'; // Pour la navigation

class DeviceVerificationPage extends StatefulWidget {
  final String phone;

  const DeviceVerificationPage({Key? key, required this.phone}) : super(key: key);

  @override
  _DeviceVerificationPageState createState() => _DeviceVerificationPageState();
}

class _DeviceVerificationPageState extends State<DeviceVerificationPage> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = "L'OTP doit contenir 6 chiffres.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.verifyDevice(widget.phone, otp);

      // Si le code est bon, l'utilisateur a reçu son token, on le redirige vers l'accueil
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vérification Sécurité'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 64, color: AppColors.accent),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Nouvel Appareil Détecté',
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pour votre sécurité, nous avons détecté que vous vous connectez depuis un nouvel appareil. Un code a été envoyé.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              VireloTextField(
                controller: _otpController,
                hint: 'Code OTP (6 chiffres)',
                keyboardType: TextInputType.number,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorMessage!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              VireloPrimaryButton(
                label: 'Vérifier',
                onPressed: _verifyOtp,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
