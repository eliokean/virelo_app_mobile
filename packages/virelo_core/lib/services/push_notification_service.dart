import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:virelo_core/network/api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Initialize local notifications for foreground display
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('ic_notification');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _localNotificationsPlugin.initialize(
      settings: initSettings,
    );

    // Listen to foreground messages (force local notification popup)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      _showLocalNotification(
        title: message.notification?.title ?? message.data['title'] ?? 'Notification Virelo',
        body: message.notification?.body ?? message.data['body'] ?? 'Nouveau message reçu',
        id: message.hashCode,
      );
    });

    _isInitialized = true;
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'virelo_channel_id',
      'Virelo Notifications',
      channelDescription: 'Notifications pour Virelo',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  /// Déclencher une notification système immédiate sans passer par Internet (Mode Hors-Ligne)
  Future<void> showOfflineNotification({
    required String title,
    required String body,
  }) async {
    await init();
    await _showLocalNotification(title: title, body: body);
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint("Erreur lors de la récupération du token FCM: $e");
      return null;
    }
  }

  Future<void> sendTokenToBackend() async {
    final token = await getToken();
    if (token != null) {
      try {
        final apiClient = ApiClient();
        await apiClient.dio.post('/auth/users/fcm-token', data: {'fcm_token': token});
        debugPrint("Token FCM envoyé au backend: $token");
      } catch (e) {
        debugPrint("Erreur lors de l'envoi du token FCM au backend: $e");
      }
    }
  }

  Future<void> removeToken() async {
    try {
      await _fcm.deleteToken();
      final apiClient = ApiClient();
      await apiClient.dio.post('/auth/users/fcm-token', data: {'fcm_token': null});
      debugPrint("Token FCM supprimé localement et sur le backend");
    } catch (e) {
      debugPrint("Erreur lors de la suppression du token FCM: $e");
    }
  }
}
