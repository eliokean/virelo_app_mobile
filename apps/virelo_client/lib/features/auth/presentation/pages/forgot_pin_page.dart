import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_text_field.dart';
import 'package:virelo_design_system/widgets/virelo_primary_button.dart';

class ForgotPinPage extends StatefulWidget {
  final String? initialPhone;
  const ForgotPinPage({super.key, this.initialPhone});

  @override
  State<ForgotPinPage> createState() => _ForgotPinPageState();
}

class _ForgotPinPageState extends State<ForgotPinPage> {
  late final TextEditingController _phoneController;
  bool _isSent = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_phoneController.text.trim().isEmpty) return;

    setState(() {
      _isSent = true;
    });

    // Simuler l'envoi d'un SMS ou appel API
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Un code de réinitialisation a été envoyé (simulation)')),
        );
        Navigator.pop(context);
      }
    });
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
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.shieldAlert,
                  size: 40,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Code PIN oublié ?',
                style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Saisissez votre numéro de téléphone. Nous vous enverrons un code pour réinitialiser votre PIN.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              VireloTextField(
                controller: _phoneController,
                hint: 'Numéro de téléphone',
                prefixIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              VireloPrimaryButton(
                label: _isSent ? 'Envoi en cours...' : 'Envoyer le code',
                icon: LucideIcons.send,
                isLoading: _isSent,
                onPressed: _isSent ? null : _handleSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
