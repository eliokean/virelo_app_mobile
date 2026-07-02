import 'package:flutter/material.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    final authService = AuthService(ApiClient());
    final hasPin = await authService.hasLocalPin();
    
    if (mounted) {
      if (hasPin) {
        context.goNamed('pin_login'); // We will add this to RouteNames
      } else {
        context.goNamed(RouteNames.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );
  }
}
