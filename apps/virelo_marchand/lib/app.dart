import 'dart:async';
import 'package:flutter/material.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/virelo_design_system.dart';
import 'package:virelo_core/virelo_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/routes/app_router.dart';

class VireloMarchandApp extends StatefulWidget {
  const VireloMarchandApp({super.key});

  @override
  State<VireloMarchandApp> createState() => _VireloMarchandAppState();
}

class _VireloMarchandAppState extends State<VireloMarchandApp> {
  StreamSubscription<RemoteMessage>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _notificationSubscription = PushNotificationService.onMessageStream.stream.listen((message) {
      final title = message.notification?.title ?? message.data['title'] ?? 'Paiement Reçu !';
      final body = message.notification?.body ?? message.data['body'] ?? 'Nouveau paiement encaissé.';
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
