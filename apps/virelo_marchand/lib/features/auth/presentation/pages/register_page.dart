import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(ApiClient());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Pour les marchands, on modifie directement l'appel ou on ajoute user_type dans l'API cliente
      // Comme auth_service de core ne prend pas user_type par défaut, on va faire l'appel dio manuellement ici
      // ou utiliser une extension si besoin. Pour aller vite, on utilise apiClient.dio directement
      final response = await ApiClient().dio.post(
        '/auth/register',
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
          'password_confirmation': _passwordController.text.trim(),
          'user_type': 'merchant',
        },
      );

      final data = response.data;
      if (data != null && data['token'] != null) {
        await ApiClient().saveToken(data['token']);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inscription réussie en tant que marchand !'), backgroundColor: AppColors.success),
          );
          context.goNamed(RouteNames.dashboard);
        }
      }
    } catch (e) {
      String errorMessage = 'Erreur lors de l\'inscription';
      if (e is DioException) {
        if (e.response?.data is Map) {
          final data = e.response?.data as Map;
          if (data['message'] != null) {
            errorMessage = data['message'];
            if (data['errors'] != null) {
              errorMessage += '\n' + data['errors'].toString();
            }
          }
        } else {
          errorMessage = e.message ?? e.toString();
        }
      } else {
        errorMessage = e.toString();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage), 
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
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
                'Nouveau Marchand',
                style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Créez votre compte pour commencer à encaisser.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),

              VireloTextField(
                controller: _nameController,
                hint: 'Nom de la boutique',
                prefixIcon: LucideIcons.store,
              ),
              const SizedBox(height: AppSpacing.md),
              VireloTextField(
                controller: _emailController,
                hint: 'Email',
                prefixIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              VireloTextField(
                controller: _phoneController,
                hint: 'Téléphone',
                prefixIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              VireloTextField(
                controller: _passwordController,
                hint: 'Code secret (ex: 1234)',
                prefixIcon: LucideIcons.lock,
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
              
              const SizedBox(height: 48),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : VireloPrimaryButton(
                      label: 'S\'inscrire',
                      onPressed: _handleRegister,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
