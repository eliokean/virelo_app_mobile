import 'package:flutter/material.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/security/device_security_service.dart';
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
    // 1. Device Security Check
    final isSecure = await DeviceSecurityService.isDeviceSecure();
    if (!isSecure && mounted) {
      // In a real app, we would redirect to a specific error page or show a dialog
      // For now we'll just show an error and block
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text("Sécurité compromise"),
          content: Text("Cet appareil semble être rooté ou altéré. L'application Virelo ne peut pas s'exécuter pour des raisons de sécurité."),
        ),
      );
      return; // Stop execution
    }

    // 2. Auth Check
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
