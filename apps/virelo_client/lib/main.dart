import 'dart:async';
import 'package:flutter/material.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/virelo_design_system.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/pin_login_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'package:virelo_core/offline_sync/hive_manager.dart';
import 'core/services/offline_sync_service.dart';
import 'core/services/auto_sync_manager.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:virelo_core/virelo_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await PushNotificationService().init();

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
  late final Future<({bool hasSeenOnboarding, bool hasPin})> _initialStateFuture;
  StreamSubscription<RemoteMessage>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _authService = AuthService(apiClient);
    _initialStateFuture = _checkInitialState();

    final offlineStorage = OfflineStorageService(_authService);
    final offlineSync = OfflineSyncService(apiClient, offlineStorage);
    AutoSyncManager().initialize(offlineSync);

    // Écoute des notifications In-App reçues en premier plan
    _notificationSubscription = PushNotificationService.onMessageStream.stream.listen((message) {
      final title = message.notification?.title ?? message.data['title'] ?? 'Paiement Reçu !';
      final body = message.notification?.body ?? message.data['body'] ?? 'Votre compte a été crédité.';
      final amount = message.data['amount']?.toString();

      VireloInAppNotification.show(
        title: title,
        message: body,
        amount: amount,
        type: InAppNotificationType.payment,
      );
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<({bool hasSeenOnboarding, bool hasPin})> _checkInitialState() async {
    final hasSeenOnboarding = await _authService.hasSeenOnboarding();
    final hasPin = await _authService.hasLocalPin();
    return (hasSeenOnboarding: hasSeenOnboarding, hasPin: hasPin);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: VireloInAppNotification.navigatorKey,
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
      home: FutureBuilder<({bool hasSeenOnboarding, bool hasPin})>(
        future: _initialStateFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            );
          }
          final state = snapshot.data;
          final hasSeenOnboarding = state?.hasSeenOnboarding ?? false;
          final hasPin = state?.hasPin ?? false;

          if (!hasSeenOnboarding) {
            return const OnboardingPage();
          } else if (hasPin) {
            return const PinLoginPage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
