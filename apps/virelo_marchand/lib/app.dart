import 'package:flutter/material.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'config/routes/app_router.dart';

class VireloMarchandApp extends StatelessWidget {
  const VireloMarchandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Virelo Marchand',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.surfaceCard,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
