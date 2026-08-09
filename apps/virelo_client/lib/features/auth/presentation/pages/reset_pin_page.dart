import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_text_field.dart';
import 'package:virelo_design_system/widgets/virelo_primary_button.dart';

class ResetPinPage extends StatefulWidget {
  final String phone;
  const ResetPinPage({super.key, required this.phone});

  @override
  State<ResetPinPage> createState() => _ResetPinPageState();
}

class _ResetPinPageState extends State<ResetPinPage> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _otpController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    final otp = _otpController.text.trim();
    final newPin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (otp.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: Colors.red),
      );
      return;
    }

    if (newPin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les codes PIN ne correspondent pas'), backgroundColor: Colors.red),
      );
      return;
    }

    if (newPin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le code PIN doit contenir au moins 4 chiffres'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.resetPin(widget.phone, otp, newPin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code PIN réinitialisé avec succès !'), backgroundColor: Colors.green),
        );
        // Retour à la page de connexion
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                'Réinitialisation du PIN',
                style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Saisissez le code reçu par SMS au ${widget.phone} et votre nouveau code PIN.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              VireloTextField(
                controller: _otpController,
                hint: 'Code de vérification (6 chiffres)',
                prefixIcon: LucideIcons.messageSquare,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              
              VireloTextField(
                controller: _pinController,
                hint: 'Nouveau code PIN',
                prefixIcon: LucideIcons.lock,
                keyboardType: TextInputType.number,
                obscureText: _obscurePin,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePin ? LucideIcons.eye : LucideIcons.eyeOff, color: AppColors.textSecondary),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              VireloTextField(
                controller: _confirmPinController,
                hint: 'Confirmer le code PIN',
                prefixIcon: LucideIcons.checkCircle,
                keyboardType: TextInputType.number,
                obscureText: _obscureConfirmPin,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPin ? LucideIcons.eye : LucideIcons.eyeOff, color: AppColors.textSecondary),
                  onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              VireloPrimaryButton(
                label: 'Réinitialiser',
                icon: LucideIcons.checkCircle2,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
