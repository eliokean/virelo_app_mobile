import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_text_field.dart';
import 'package:virelo_design_system/widgets/virelo_primary_button.dart';
import 'register_pin_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterPinPage(
          name: name,
          phone: phone,
          email: email,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Créer un compte',
                style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Rejoignez Virelo en quelques secondes',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),

              VireloTextField(
                controller: _nameController,
                hint: 'Nom complet',
                prefixIcon: LucideIcons.user,
              ),
              const SizedBox(height: AppSpacing.lg),
              VireloTextField(
                controller: _phoneController,
                hint: 'Numéro de téléphone',
                prefixIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.lg),
              VireloTextField(
                controller: _emailController,
                hint: 'Adresse e-mail',
                prefixIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 48),
              VireloPrimaryButton(
                label: 'Continuer',
                icon: LucideIcons.arrowRight,
                onPressed: _handleContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
