import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/pin_login_page.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'core/services/offline_sync_service.dart';
import 'core/services/auto_sync_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Hive (Approche Hybride de Grade Entreprise)
  await Hive.initFlutter();

  const secureStorage = FlutterSecureStorage();
  // Lecture de la clé AES-256 dans le stockage sécurisé (Keychain/Keystore)
  String? encryptionKeyString = await secureStorage.read(key: 'hive_aes_key');
  if (encryptionKeyString == null) {
    // Génération d'une nouvelle clé si elle n'existe pas
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: 'hive_aes_key',
      value: base64UrlEncode(key),
    );
    encryptionKeyString = base64UrlEncode(key);
  }

  final encryptionKeyUint8List = base64Url.decode(encryptionKeyString);

  // Ouverture du Coffre (Base de données chiffrée)
  await Hive.openBox('virelo_offline_box', encryptionCipher: HiveAesCipher(encryptionKeyUint8List));

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
