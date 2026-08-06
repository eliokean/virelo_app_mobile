import 'package:flutter/material.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/pin_login_page.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'package:virelo_core/offline_sync/hive_manager.dart';
import 'core/services/offline_sync_service.dart';
import 'core/services/auto_sync_manager.dart';

import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Hive (Approche Hybride de Grade Entreprise)
  await HiveManager.openOfflineBox();

  // Initialisation de la localisation française pour les dates
  try {
    await initializeDateFormatting('fr_FR', null);
  } catch (_) {}

  runApp(const VireloApp());
}


class VireloApp extends StatefulWidget {
  const VireloApp({super.key});

  @override
  State<VireloApp> createState() => _VireloAppState();
}

class _VireloAppState extends State<VireloApp> {
  late final AuthService _authService;
  late final Future<bool> _hasPinFuture;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _authService = AuthService(apiClient);
    _hasPinFuture = _authService.hasLocalPin();

    final offlineStorage = OfflineStorageService(_authService);
    final offlineSync = OfflineSyncService(apiClient, offlineStorage);
    AutoSyncManager().initialize(offlineSync);
  }

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
      home: FutureBuilder<bool>(
        future: _hasPinFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            );
          }
          final hasPin = snapshot.data ?? false;
          if (hasPin) {
            return const PinLoginPage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
