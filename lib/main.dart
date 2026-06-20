import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'features/wallet/presentation/pages/wallet_page.dart';

void main() {
  runApp(const VireloApp());
}

class VireloApp extends StatelessWidget {
  const VireloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virelo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.surfaceCard,
        ),
        useMaterial3: true,
      ),
      home: const WalletPage(),
    );
  }
}
