import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_text_field.dart';
import 'package:virelo_design_system/widgets/virelo_primary_button.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final authService = AuthService(ApiClient());
      await authService.login(_phoneController.text.trim(), _passwordController.text.trim());
      
      if (mounted) {
        context.goNamed(RouteNames.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.store, size: 48, color: AppColors.accent),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Virelo Marchand',
                style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Connectez-vous à votre caisse',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              VireloTextField(
                controller: _phoneController,
                hint: 'Numéro de téléphone',
                prefixIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              VireloTextField(
                controller: _passwordController,
                hint: 'Code secret',
                prefixIcon: LucideIcons.lock,
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : VireloPrimaryButton(
                      label: 'Se connecter',
                      onPressed: _handleLogin,
                    ),
              
              const SizedBox(height: AppSpacing.xxl),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: Text(
                  'Devenir marchand ? S\'inscrire',
                  style: AppTextStyles.button.copyWith(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
