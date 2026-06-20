# virelo — Guide de réalisation complet
### Application mobile de paiement NFC + QR Code · Offline-First · Flutter · Clean Architecture

> **Projet** : PFE — YAO Moye Eliott Kenan · ESATIC · GENIUS GROUPS · 2025-2026  
> **Stack** : Flutter (Dart) · BLoC · GetIt · GoRouter · Dio · SQLite · flutter_secure_storage · local_auth · firebase_messaging · smile_id · qr_flutter

---

## Table des matières

1. [Prérequis & setup de l'environnement](#1-prérequis--setup-de-lenvironnement)
2. [Création du projet & structure des dossiers](#2-création-du-projet--structure-des-dossiers)
3. [Dépendances (pubspec.yaml)](#3-dépendances-pubspecyaml)
4. [Core — Infrastructure transversale](#4-core--infrastructure-transversale)
5. [Config — DI, Routes, Environnements](#5-config--di-routes-environnements)
6. [Feature : Auth](#6-feature--auth)
7. [Feature : Wallet](#7-feature--wallet)
8. [Feature : Transfer (paiement NFC + QR)](#8-feature--transfer-paiement-nfc--qr)
9. [Feature : Offline & Télécollecte](#9-feature--offline--télécollecte)
10. [Feature : KYC (Smile ID)](#10-feature--kyc-smile-id)
11. [Feature : Deposit (recharge Mobile Money)](#11-feature--deposit-recharge-mobile-money)
12. [Feature : History](#12-feature--history)
13. [Feature : Notifications (FCM)](#13-feature--notifications-fcm)
14. [Feature : Profile](#14-feature--profile)
15. [Feature : Onboarding](#15-feature--onboarding)
16. [Feature : Card (cartes virtuelles)](#16-feature--card-cartes-virtuelles)
17. [Feature : Share (partage QR)](#17-feature--share-partage-qr)
18. [Feature : Billing](#18-feature--billing)
19. [Feature : Conversion (taux de change)](#19-feature--conversion-taux-de-change)
20. [Internationalisation (l10n)](#20-internationalisation-l10n)
21. [Tests](#21-tests)
22. [Build & déploiement](#22-build--déploiement)
23. [Checklist finale](#23-checklist-finale)

---

## 1. Prérequis & setup de l'environnement

### 1.1 Logiciels à installer

| Outil | Version minimale | Rôle |
|---|---|---|
| Flutter SDK | 3.22+ | Framework UI |
| Dart SDK | 3.4+ | Langage (inclus dans Flutter) |
| Android Studio | Hedgehog+ | Émulateur & SDK Android |
| VS Code | Dernière | Éditeur principal |
| Git | 2.40+ | Versioning |
| Postman | Dernière | Test des APIs |

```bash
# Vérifier l'installation Flutter
flutter doctor -v

# Résultats attendus : ✓ Flutter, ✓ Android toolchain, ✓ Android Studio
```

### 1.2 Activation des options Android requises

Dans `android/app/src/main/AndroidManifest.xml`, les permissions suivantes seront nécessaires :

```xml
<!-- NFC -->
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />

<!-- HCE (émulation de carte côté client) -->
<uses-feature android:name="android.hardware.nfc.hce" android:required="false" />

<!-- Biométrie -->
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />

<!-- Réseau -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Caméra (scan QR) -->
<uses-permission android:name="android.permission.CAMERA" />
```

Dans le même fichier, déclarer le service HCE pour l'application client :

```xml
<service
    android:name=".HcePaymentService"
    android:exported="true"
    android:permission="android.permission.BIND_NFC_SERVICE">
    <intent-filter>
        <action android:name="android.nfc.cardemulation.action.HOST_APDU_SERVICE" />
    </intent-filter>
    <meta-data
        android:name="android.nfc.cardemulation.host_apdu_service"
        android:resource="@xml/apduservice" />
</service>
```

Créer `android/app/src/main/res/xml/apduservice.xml` :

```xml
<host-apdu-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:description="@string/app_name"
    android:requireDeviceUnlock="true">
    <aid-group android:description="@string/app_name" android:category="payment">
        <aid-filter android:name="A000000004101011" />
    </aid-group>
</host-apdu-service>
```

---

## 2. Création du projet & structure des dossiers

### 2.1 Créer le projet

```bash
flutter create --org com.geniusgroups --project-name virelo virelo_app
cd virelo_app
```

### 2.2 Structure complète des dossiers

Créer manuellement l'arborescence suivante (ou via le script bash fourni en 2.3) :

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── auth_interceptor.dart
│   │   ├── connectivity_service.dart
│   │   └── network_info.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   ├── constants/
│   │   ├── api_constants.dart
│   │   ├── app_constants.dart
│   │   └── storage_keys.dart
│   └── utils/
│       ├── crypto_utils.dart
│       ├── date_utils.dart
│       ├── validators.dart
│       └── extensions.dart
│
├── config/
│   ├── di/
│   │   └── injection.dart
│   ├── env/
│   │   ├── env.dart
│   │   ├── env_dev.dart
│   │   └── env_prod.dart
│   └── routes/
│       ├── app_router.dart
│       └── route_names.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── user_model.dart
│   │   │   │   └── auth_token_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       ├── send_otp_usecase.dart
│   │   │       ├── verify_otp_usecase.dart
│   │   │       └── logout_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── pages/
│   │       │   ├── phone_input_page.dart
│   │       │   ├── otp_verification_page.dart
│   │       │   └── biometric_setup_page.dart
│   │       └── widgets/
│   │           ├── phone_field.dart
│   │           └── otp_input_field.dart
│   │
│   ├── wallet/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── wallet_remote_datasource.dart
│   │   │   │   └── wallet_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── wallet_model.dart
│   │   │   └── repositories/
│   │   │       └── wallet_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── wallet.dart
│   │   │   ├── repositories/
│   │   │   │   └── wallet_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_wallet_usecase.dart
│   │   │       └── update_local_balance_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── wallet_bloc.dart
│   │       │   ├── wallet_event.dart
│   │       │   └── wallet_state.dart
│   │       ├── pages/
│   │       │   └── wallet_page.dart
│   │       └── widgets/
│   │           ├── balance_card.dart
│   │           └── wallet_actions_row.dart
│   │
│   ├── transfer/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── transfer_remote_datasource.dart
│   │   │   │   └── transfer_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── transaction_model.dart
│   │   │   └── repositories/
│   │   │       └── transfer_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── transaction.dart
│   │   │   ├── repositories/
│   │   │   │   └── transfer_repository.dart
│   │   │   └── usecases/
│   │   │       ├── initiate_nfc_payment_usecase.dart
│   │   │       ├── initiate_qr_payment_usecase.dart
│   │   │       └── receive_payment_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── transfer_bloc.dart
│   │       │   ├── transfer_event.dart
│   │       │   └── transfer_state.dart
│   │       ├── pages/
│   │       │   ├── send_payment_page.dart
│   │       │   ├── receive_payment_page.dart
│   │       │   └── payment_success_page.dart
│   │       └── widgets/
│   │           ├── nfc_tap_widget.dart
│   │           ├── qr_display_widget.dart
│   │           └── amount_input_widget.dart
│   │
│   ├── deposit/
│   ├── kyc/
│   ├── card/
│   ├── billing/
│   ├── notifications/
│   ├── conversion/
│   ├── profile/
│   ├── history/
│   ├── onboarding/
│   └── share/
│
└── l10n/
    ├── app_en.arb
    ├── app_fr.arb
    └── app_sw.arb
```

### 2.3 Script bash de création des dossiers

```bash
#!/bin/bash
# Exécuter depuis la racine du projet Flutter

FEATURES=(auth wallet transfer deposit kyc card billing notifications conversion profile history onboarding share)
LAYERS=(data/datasources data/models data/repositories domain/entities domain/repositories domain/usecases presentation/bloc presentation/pages presentation/widgets)

for feature in "${FEATURES[@]}"; do
  for layer in "${LAYERS[@]}"; do
    mkdir -p "lib/features/$feature/$layer"
    touch "lib/features/$feature/$layer/.gitkeep"
  done
done

mkdir -p lib/core/{network,theme,constants,utils}
mkdir -p lib/config/{di,env,routes}
mkdir -p lib/l10n

echo "✅ Structure créée avec succès"
```

---

## 3. Dépendances (pubspec.yaml)

```yaml
name: virelo
description: Plateforme de paiement mobile offline NFC + QR Code — GENIUS GROUPS
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State management
  flutter_bloc: ^9.1.0
  equatable: ^2.0.5

  # Navigation
  go_router: ^14.8.0

  # HTTP client
  dio: ^5.8.0

  # Injection de dépendances
  get_it: ^8.0.0
  injectable: ^2.4.0

  # Stockage sécurisé (JWT, solde embarqué)
  flutter_secure_storage: ^9.2.0

  # Base de données locale offline
  sqflite: ^2.3.3+1
  path: ^1.9.0

  # Biométrie (empreinte / Face ID)
  local_auth: ^2.3.0

  # NFC
  nfc_manager: ^3.3.0

  # QR Code
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.2.3

  # Notifications push
  firebase_core: ^3.6.0
  firebase_messaging: ^15.0.0
  flutter_local_notifications: ^17.2.3

  # KYC Smile ID
  smile_id: ^11.2.0

  # Crypto (AES-256)
  encrypt: ^5.0.3
  pointycastle: ^3.9.1

  # Connectivité réseau
  connectivity_plus: ^6.1.1

  # Utilitaires
  intl: ^0.19.0
  uuid: ^4.5.1
  logger: ^2.5.0
  dartz: ^0.10.1         # Either pour gestion d'erreurs
  freezed_annotation: ^2.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
  build_runner: ^2.4.13
  injectable_generator: ^2.4.0
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  generate: true          # Active la génération l10n
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

---

## 4. Core — Infrastructure transversale

### 4.1 `lib/core/constants/api_constants.dart`

```dart
class ApiConstants {
  ApiConstants._();

  static const String baseUrlDev  = 'https://api-dev.virelo.ci/v1';
  static const String baseUrlProd = 'https://api.virelo.ci/v1';

  // Auth
  static const String sendOtp     = '/auth/otp/send';
  static const String verifyOtp   = '/auth/otp/verify';
  static const String refreshToken = '/auth/token/refresh';
  static const String logout      = '/auth/logout';

  // Wallet
  static const String wallet      = '/wallet';
  static const String balance     = '/wallet/balance';

  // Transfer
  static const String transfer    = '/transfer';
  static const String syncTransactions = '/transfer/sync';

  // Deposit
  static const String deposit     = '/deposit';

  // KYC
  static const String kycSubmit   = '/kyc/submit';

  // Notifications
  static const String fcmToken    = '/notifications/token';
}
```

### 4.2 `lib/core/constants/storage_keys.dart`

```dart
class StorageKeys {
  StorageKeys._();

  static const String accessToken   = 'access_token';
  static const String refreshToken  = 'refresh_token';
  static const String userId        = 'user_id';
  static const String encryptedBalance = 'encrypted_balance';
  static const String encryptionKey = 'aes_key';
  static const String biometricEnabled = 'biometric_enabled';
}
```

### 4.3 `lib/core/network/api_client.dart`

```dart
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({required String baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      GetIt.I<AuthInterceptor>(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print(obj),
      ),
    ]);
  }

  Dio get dio => _dio;
}
```

### 4.4 `lib/core/network/auth_interceptor.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 → tenter le refresh token
    if (err.response?.statusCode == 401) {
      final refreshed = await _tryRefreshToken(err.requestOptions);
      if (refreshed != null) {
        handler.resolve(refreshed);
        return;
      }
    }
    handler.next(err);
  }

  Future<Response?> _tryRefreshToken(RequestOptions options) async {
    // TODO: implémenter la logique de refresh
    return null;
  }
}
```

### 4.5 `lib/core/network/connectivity_service.dart`

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  Stream<bool> get onConnectivityChanged => _connectivity
    .onConnectivityChanged
    .map((results) => !results.contains(ConnectivityResult.none));

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
```

### 4.6 `lib/core/utils/crypto_utils.dart`

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

/// Chiffrement AES-256 pour les données sensibles (solde embarqué, tokens)
class CryptoUtils {
  final FlutterSecureStorage _storage;

  CryptoUtils(this._storage);

  /// Génère et sauvegarde une clé AES-256 au premier lancement
  Future<Key> _getOrCreateKey() async {
    String? storedKey = await _storage.read(key: StorageKeys.encryptionKey);
    if (storedKey != null) {
      return Key(base64.decode(storedKey));
    }
    final key = Key.fromSecureRandom(32); // 256 bits
    await _storage.write(
      key: StorageKeys.encryptionKey,
      value: base64.encode(key.bytes),
    );
    return key;
  }

  Future<String> encrypt(String plainText) async {
    final key = await _getOrCreateKey();
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // On stocke iv + données chiffrées ensemble
    return '${base64.encode(iv.bytes)}:${encrypted.base64}';
  }

  Future<String> decrypt(String cipherText) async {
    final key = await _getOrCreateKey();
    final parts = cipherText.split(':');
    final iv = IV(base64.decode(parts[0]));
    final encrypted = Encrypted.fromBase64(parts[1]);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// Chiffrement d'un montant pour le solde embarqué offline
  Future<String> encryptBalance(double amount) async {
    return await encrypt(amount.toStringAsFixed(2));
  }

  Future<double> decryptBalance(String cipherBalance) async {
    final plain = await decrypt(cipherBalance);
    return double.parse(plain);
  }
}
```

### 4.7 `lib/core/theme/app_colors.dart`

```dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Couleurs principales virelo
  static const Color primary      = Color(0xFF1A73E8);  // Bleu virelo
  static const Color primaryDark  = Color(0xFF1557B0);
  static const Color secondary    = Color(0xFF00C896);  // Vert succès
  static const Color accent       = Color(0xFFFFC107);  // Jaune recharge

  // Arrière-plans
  static const Color background   = Color(0xFFF8F9FE);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F9);

  // Texte
  static const Color textPrimary   = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFFB0B7C3);

  // États
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFF9800);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF1A73E8);

  // NFC / Paiement
  static const Color nfcActive   = Color(0xFF00C896);
  static const Color nfcWaiting  = Color(0xFF1A73E8);
  static const Color nfcError    = Color(0xFFEF4444);

  // Offline badge
  static const Color offlineBadge = Color(0xFFFF6B35);
}
```

### 4.8 `lib/core/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: AppColors.textPrimary,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
    ),
  );
}
```

---

## 5. Config — DI, Routes, Environnements

### 5.1 `lib/config/env/env.dart`

```dart
abstract class Env {
  String get baseUrl;
  String get appName;
  bool   get isDebug;
}
```

### 5.2 `lib/config/env/env_dev.dart`

```dart
import 'env.dart';

class EnvDev implements Env {
  @override String get baseUrl  => 'https://api-dev.virelo.ci/v1';
  @override String get appName  => 'virelo [DEV]';
  @override bool   get isDebug  => true;
}
```

### 5.3 `lib/config/env/env_prod.dart`

```dart
import 'env.dart';

class EnvProd implements Env {
  @override String get baseUrl  => 'https://api.virelo.ci/v1';
  @override String get appName  => 'virelo';
  @override bool   get isDebug  => false;
}
```

### 5.4 `lib/config/di/injection.dart`

```dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/network/api_client.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/utils/crypto_utils.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/send_otp_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/wallet/data/datasources/wallet_remote_datasource.dart';
import '../../features/wallet/data/datasources/wallet_local_datasource.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/domain/usecases/get_wallet_usecase.dart';
import '../../features/wallet/domain/usecases/update_local_balance_usecase.dart';
import '../../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../../features/transfer/data/datasources/transfer_remote_datasource.dart';
import '../../features/transfer/data/datasources/transfer_local_datasource.dart';
import '../../features/transfer/data/repositories/transfer_repository_impl.dart';
import '../../features/transfer/domain/repositories/transfer_repository.dart';
import '../../features/transfer/domain/usecases/initiate_nfc_payment_usecase.dart';
import '../../features/transfer/presentation/bloc/transfer_bloc.dart';
// ... importer les autres features de la même façon

final GetIt sl = GetIt.instance;

Future<void> initDependencies({required String baseUrl}) async {
  // ── Externes ───────────────────────────────────────────────
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  sl.registerSingleton<FlutterSecureStorage>(secureStorage);

  sl.registerSingleton<ConnectivityService>(ConnectivityService());
  sl.registerSingleton<CryptoUtils>(CryptoUtils(secureStorage));
  sl.registerSingleton<AuthInterceptor>(AuthInterceptor(secureStorage));
  sl.registerSingleton<ApiClient>(ApiClient(baseUrl: baseUrl));

  // SQLite — base de données locale offline
  final db = await _initDatabase();
  sl.registerSingleton<Database>(db);

  // ── Auth ───────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(sl<FlutterSecureStorage>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl(),
      local: sl(),
      connectivity: sl(),
    ),
  );
  sl.registerLazySingleton(() => SendOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerFactory(() => AuthBloc(
    sendOtp: sl(),
    verifyOtp: sl(),
    login: sl(),
  ));

  // ── Wallet ─────────────────────────────────────────────────
  sl.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSource(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<WalletLocalDataSource>(
    () => WalletLocalDataSource(sl<Database>(), sl<CryptoUtils>()),
  );
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(remote: sl(), local: sl(), connectivity: sl()),
  );
  sl.registerLazySingleton(() => GetWalletUseCase(sl()));
  sl.registerLazySingleton(() => UpdateLocalBalanceUseCase(sl()));
  sl.registerFactory(() => WalletBloc(getWallet: sl(), updateLocalBalance: sl()));

  // ── Transfer ───────────────────────────────────────────────
  sl.registerLazySingleton<TransferRemoteDataSource>(
    () => TransferRemoteDataSource(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<TransferLocalDataSource>(
    () => TransferLocalDataSource(sl<Database>(), sl<CryptoUtils>()),
  );
  sl.registerLazySingleton<TransferRepository>(
    () => TransferRepositoryImpl(remote: sl(), local: sl(), connectivity: sl()),
  );
  sl.registerLazySingleton(() => InitiateNfcPaymentUseCase(sl()));
  sl.registerFactory(() => TransferBloc(initiateNfcPayment: sl()));
}

Future<Database> _initDatabase() async {
  return openDatabase(
    'virelo.db',
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE pending_transactions (
          id TEXT PRIMARY KEY,
          merchant_id TEXT NOT NULL,
          client_id TEXT NOT NULL,
          amount REAL NOT NULL,
          currency TEXT NOT NULL DEFAULT 'XOF',
          encrypted_token TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          created_at TEXT NOT NULL,
          synced_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE wallet_cache (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          encrypted_balance TEXT NOT NULL,
          currency TEXT NOT NULL DEFAULT 'XOF',
          updated_at TEXT NOT NULL
        )
      ''');
    },
  );
}
```

### 5.5 `lib/config/routes/route_names.dart`

```dart
class RouteNames {
  RouteNames._();

  static const String splash       = '/';
  static const String onboarding   = '/onboarding';
  static const String phoneInput   = '/auth/phone';
  static const String otpVerify    = '/auth/otp';
  static const String biometric    = '/auth/biometric';
  static const String home         = '/home';
  static const String wallet       = '/wallet';
  static const String sendPayment  = '/transfer/send';
  static const String receivePayment = '/transfer/receive';
  static const String paymentSuccess = '/transfer/success';
  static const String deposit      = '/deposit';
  static const String history      = '/history';
  static const String profile      = '/profile';
  static const String kyc          = '/kyc';
  static const String notifications = '/notifications';
  static const String card         = '/card';
  static const String share        = '/share';
  static const String billing      = '/billing';
  static const String conversion   = '/conversion';
}
```

### 5.6 `lib/config/routes/app_router.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'route_names.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/phone_input_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/biometric_setup_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/transfer/presentation/pages/send_payment_page.dart';
import '../../features/transfer/presentation/pages/receive_payment_page.dart';
import '../../features/transfer/presentation/pages/payment_success_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/deposit/presentation/pages/deposit_page.dart';
// ... importer toutes les pages

class AppRouter {
  final FlutterSecureStorage _storage;
  AppRouter(this._storage);

  late final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    redirect: _guard,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const _SplashPage(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: RouteNames.phoneInput,
        builder: (_, __) => const PhoneInputPage(),
      ),
      GoRoute(
        path: RouteNames.otpVerify,
        builder: (context, state) => OtpVerificationPage(
          phone: state.extra as String,
        ),
      ),
      GoRoute(
        path: RouteNames.biometric,
        builder: (_, __) => const BiometricSetupPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => _HomeShell(child: child),
        routes: [
          GoRoute(path: RouteNames.home,    builder: (_, __) => const WalletPage()),
          GoRoute(path: RouteNames.wallet,  builder: (_, __) => const WalletPage()),
          GoRoute(path: RouteNames.history, builder: (_, __) => const HistoryPage()),
          GoRoute(path: RouteNames.profile, builder: (_, __) => const ProfilePage()),
        ],
      ),
      GoRoute(
        path: RouteNames.sendPayment,
        builder: (_, __) => const SendPaymentPage(),
      ),
      GoRoute(
        path: RouteNames.receivePayment,
        builder: (_, __) => const ReceivePaymentPage(),
      ),
      GoRoute(
        path: RouteNames.paymentSuccess,
        builder: (context, state) => PaymentSuccessPage(
          transaction: state.extra,
        ),
      ),
      GoRoute(
        path: RouteNames.deposit,
        builder: (_, __) => const DepositPage(),
      ),
    ],
  );

  Future<String?> _guard(BuildContext context, GoRouterState state) async {
    final token = await _storage.read(key: 'access_token');
    final isAuth = token != null && token.isNotEmpty;
    final isAuthRoute = state.fullPath?.startsWith('/auth') ?? false;
    final isOnboarding = state.fullPath == RouteNames.onboarding;
    final isSplash = state.fullPath == RouteNames.splash;

    if (isSplash || isOnboarding) return null;
    if (!isAuth && !isAuthRoute) return RouteNames.phoneInput;
    if (isAuth && isAuthRoute) return RouteNames.home;
    return null;
  }
}

class _HomeShell extends StatelessWidget {
  final Widget child;
  const _HomeShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.history_outlined), label: 'Historique'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}
```

---

## 6. Feature : Auth

### 6.1 Entity — `lib/features/auth/domain/entities/user.dart`

```dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final bool kycVerified;
  final bool biometricEnabled;
  final String role; // 'client' | 'merchant' | 'admin'

  const User({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.kycVerified = false,
    this.biometricEnabled = false,
    this.role = 'client',
  });

  @override
  List<Object?> get props => [id, phone, role];
}
```

### 6.2 Repository interface — `lib/features/auth/domain/repositories/auth_repository.dart`

```dart
import 'package:dartz/dartz.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<String, String>> sendOtp(String phone);
  Future<Either<String, User>>  verifyOtp(String phone, String otp);
  Future<Either<String, bool>>  setupBiometric();
  Future<Either<String, User>>  loginWithBiometric();
  Future<void> logout();
  Future<User?> getCachedUser();
}
```

### 6.3 Use cases

**`lib/features/auth/domain/usecases/send_otp_usecase.dart`**

```dart
import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class SendOtpUseCase {
  final AuthRepository _repo;
  const SendOtpUseCase(this._repo);

  Future<Either<String, String>> call(String phone) =>
      _repo.sendOtp(phone);
}
```

**`lib/features/auth/domain/usecases/verify_otp_usecase.dart`**

```dart
import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository _repo;
  const VerifyOtpUseCase(this._repo);

  Future<Either<String, User>> call(String phone, String otp) =>
      _repo.verifyOtp(phone, otp);
}
```

### 6.4 Model — `lib/features/auth/data/models/user_model.dart`

```dart
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.phone,
    super.name,
    super.email,
    super.kycVerified,
    super.biometricEnabled,
    super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:              json['id'] as String,
    phone:           json['phone'] as String,
    name:            json['name'] as String?,
    email:           json['email'] as String?,
    kycVerified:     json['kyc_verified'] as bool? ?? false,
    biometricEnabled: json['biometric_enabled'] as bool? ?? false,
    role:            json['role'] as String? ?? 'client',
  );

  Map<String, dynamic> toJson() => {
    'id':               id,
    'phone':            phone,
    'name':             name,
    'email':            email,
    'kyc_verified':     kycVerified,
    'biometric_enabled': biometricEnabled,
    'role':             role,
  };
}
```

### 6.5 Remote DataSource — `lib/features/auth/data/datasources/auth_remote_datasource.dart`

```dart
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/auth_token_model.dart';

class AuthRemoteDataSource {
  final Dio _dio;
  const AuthRemoteDataSource(this._dio);

  Future<String> sendOtp(String phone) async {
    final response = await _dio.post(
      ApiConstants.sendOtp,
      data: {'phone': phone},
    );
    return response.data['message'] as String;
  }

  Future<AuthTokenModel> verifyOtp(String phone, String otp) async {
    final response = await _dio.post(
      ApiConstants.verifyOtp,
      data: {'phone': phone, 'otp': otp},
    );
    return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
  }
}
```

### 6.6 Local DataSource — `lib/features/auth/data/datasources/auth_local_datasource.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/constants/storage_keys.dart';

class AuthLocalDataSource {
  final FlutterSecureStorage _storage;
  final LocalAuthentication  _biometric = LocalAuthentication();

  const AuthLocalDataSource(this._storage);

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: StorageKeys.accessToken,  value: access);
    await _storage.write(key: StorageKeys.refreshToken, value: refresh);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: StorageKeys.accessToken);

  Future<void> clearTokens() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
  }

  /// Authentification biométrique native (empreinte / Face ID)
  Future<bool> authenticateWithBiometric() async {
    final canAuth = await _biometric.canCheckBiometrics;
    if (!canAuth) return false;

    return _biometric.authenticate(
      localizedReason: 'Validez le paiement avec votre empreinte',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final canAuth = await _biometric.canCheckBiometrics;
      final enrolled = await _biometric.getAvailableBiometrics();
      return canAuth && enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
```

### 6.7 BLoC — `lib/features/auth/presentation/bloc/auth_bloc.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtpUseCase   _sendOtp;
  final VerifyOtpUseCase _verifyOtp;
  final LoginUseCase     _login;

  AuthBloc({
    required SendOtpUseCase   sendOtp,
    required VerifyOtpUseCase verifyOtp,
    required LoginUseCase     login,
  })  : _sendOtp   = sendOtp,
        _verifyOtp = verifyOtp,
        _login     = login,
        super(AuthInitial()) {
    on<SendOtpRequested>(_onSendOtp);
    on<OtpVerifyRequested>(_onVerifyOtp);
    on<BiometricLoginRequested>(_onBiometricLogin);
  }

  Future<void> _onSendOtp(
    SendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _sendOtp(event.phone);
    result.fold(
      (failure) => emit(AuthError(failure)),
      (message) => emit(OtpSent(phone: event.phone)),
    );
  }

  Future<void> _onVerifyOtp(
    OtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _verifyOtp(event.phone, event.otp);
    result.fold(
      (failure) => emit(AuthError(failure)),
      (user)    => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onBiometricLogin(
    BiometricLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _login(null);
    result.fold(
      (failure) => emit(AuthError(failure)),
      (user)    => emit(AuthAuthenticated(user)),
    );
  }
}
```

### 6.8 Events & States

**`lib/features/auth/presentation/bloc/auth_event.dart`**

```dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override List<Object?> get props => [];
}

class SendOtpRequested extends AuthEvent {
  final String phone;
  SendOtpRequested(this.phone);
  @override List<Object?> get props => [phone];
}

class OtpVerifyRequested extends AuthEvent {
  final String phone;
  final String otp;
  OtpVerifyRequested(this.phone, this.otp);
  @override List<Object?> get props => [phone, otp];
}

class BiometricLoginRequested extends AuthEvent {}
```

**`lib/features/auth/presentation/bloc/auth_state.dart`**

```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  @override List<Object?> get props => [];
}

class AuthInitial       extends AuthState {}
class AuthLoading       extends AuthState {}
class OtpSent          extends AuthState {
  final String phone;
  OtpSent({required this.phone});
  @override List<Object?> get props => [phone];
}
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
  @override List<Object?> get props => [user];
}
class AuthError         extends AuthState {
  final String message;
  AuthError(this.message);
  @override List<Object?> get props => [message];
}
```

### 6.9 Page — `lib/features/auth/presentation/pages/phone_input_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/di/injection.dart';
import '../../../../config/routes/route_names.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({super.key});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final _controller = TextEditingController();
  final _formKey    = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpSent) {
            context.push(RouteNames.otpVerify, extra: state.phone);
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),
                      Text(
                        'Votre numéro\nde téléphone',
                        style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nous vous enverrons un code de vérification',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _controller,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '+225 07 00 00 00 00',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Numéro requis';
                          if (v.length < 8) return 'Numéro invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: state is AuthLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthBloc>().add(
                                  SendOtpRequested(_controller.text.trim()),
                                );
                              }
                            },
                        child: state is AuthLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Recevoir le code'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## 7. Feature : Wallet

### 7.1 Entity — `lib/features/wallet/domain/entities/wallet.dart`

```dart
import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String id;
  final String userId;
  final double balance;       // Solde serveur (en ligne)
  final double localBalance;  // Solde embarqué (offline, chiffré)
  final String currency;      // 'XOF' par défaut
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.localBalance,
    this.currency = 'XOF',
    required this.updatedAt,
  });

  Wallet copyWith({double? localBalance}) => Wallet(
    id: id,
    userId: userId,
    balance: balance,
    localBalance: localBalance ?? this.localBalance,
    currency: currency,
    updatedAt: DateTime.now(),
  );

  @override
  List<Object?> get props => [id, userId, balance, currency];
}
```

### 7.2 Local DataSource — `lib/features/wallet/data/datasources/wallet_local_datasource.dart`

```dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/utils/crypto_utils.dart';
import '../models/wallet_model.dart';

class WalletLocalDataSource {
  final Database    _db;
  final CryptoUtils _crypto;

  WalletLocalDataSource(this._db, this._crypto);

  /// Sauvegarde du solde chiffré en AES-256 (RG 3 : soustraction solde embarqué)
  Future<void> saveLocalBalance(String userId, double balance) async {
    final encryptedBalance = await _crypto.encryptBalance(balance);
    final existing = await _db.query(
      'wallet_cache',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (existing.isEmpty) {
      await _db.insert('wallet_cache', {
        'id':                userId,
        'user_id':           userId,
        'encrypted_balance': encryptedBalance,
        'currency':          'XOF',
        'updated_at':        DateTime.now().toIso8601String(),
      });
    } else {
      await _db.update(
        'wallet_cache',
        {
          'encrypted_balance': encryptedBalance,
          'updated_at':        DateTime.now().toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  /// Lecture du solde local déchiffré
  Future<double?> getLocalBalance(String userId) async {
    final rows = await _db.query(
      'wallet_cache',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (rows.isEmpty) return null;
    final encrypted = rows.first['encrypted_balance'] as String;
    return _crypto.decryptBalance(encrypted);
  }

  /// Décrémenter le solde après un paiement offline (RG 3)
  Future<bool> deductBalance(String userId, double amount) async {
    final current = await getLocalBalance(userId);
    if (current == null || current < amount) return false; // Solde insuffisant
    await saveLocalBalance(userId, current - amount);
    return true;
  }
}
```

### 7.3 BLoC — `lib/features/wallet/presentation/bloc/wallet_bloc.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_wallet_usecase.dart';
import '../../domain/usecases/update_local_balance_usecase.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetWalletUseCase          _getWallet;
  final UpdateLocalBalanceUseCase _updateBalance;

  WalletBloc({
    required GetWalletUseCase          getWallet,
    required UpdateLocalBalanceUseCase updateLocalBalance,
  })  : _getWallet     = getWallet,
        _updateBalance = updateLocalBalance,
        super(WalletInitial()) {
    on<LoadWallet>(_onLoadWallet);
    on<DeductLocalBalance>(_onDeductBalance);
  }

  Future<void> _onLoadWallet(
    LoadWallet event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());
    final result = await _getWallet(event.userId);
    result.fold(
      (failure) => emit(WalletError(failure)),
      (wallet)  => emit(WalletLoaded(wallet)),
    );
  }

  Future<void> _onDeductBalance(
    DeductLocalBalance event,
    Emitter<WalletState> emit,
  ) async {
    if (state is WalletLoaded) {
      final current = (state as WalletLoaded).wallet;
      final result  = await _updateBalance(
        current.userId,
        current.localBalance - event.amount,
      );
      result.fold(
        (failure) => emit(WalletError(failure)),
        (wallet)  => emit(WalletLoaded(wallet)),
      );
    }
  }
}
```

### 7.4 Widget — `lib/features/wallet/presentation/widgets/balance_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/wallet.dart';

class BalanceCard extends StatefulWidget {
  final Wallet wallet;
  final bool   isOffline;

  const BalanceCard({
    super.key,
    required this.wallet,
    this.isOffline = false,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Solde disponible',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Row(
                children: [
                  if (widget.isOffline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.offlineBadge,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'HORS LIGNE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _hidden = !_hidden),
                    child: Icon(
                      _hidden ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _hidden
              ? '••••••'
              : '${_formatAmount(widget.isOffline
                  ? widget.wallet.localBalance
                  : widget.wallet.balance)} ${widget.wallet.currency}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          if (widget.isOffline)
            const Text(
              'Solde local · Synchronisation en attente',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final result = <String>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.add(' ');
      result.add(parts[i]);
    }
    return result.join();
  }
}
```

---

## 8. Feature : Transfer (paiement NFC + QR)

### 8.1 Entity — `lib/features/transfer/domain/entities/transaction.dart`

```dart
import 'package:equatable/equatable.dart';

enum TransactionStatus { pending, synced, failed }
enum PaymentMethod { nfc, qrCode, physicalCard }

class Transaction extends Equatable {
  final String            id;
  final String            merchantId;
  final String            clientId;
  final double            amount;
  final String            currency;
  final String            encryptedToken; // jeton AES-256
  final TransactionStatus status;
  final PaymentMethod     method;
  final DateTime          createdAt;
  final DateTime?         syncedAt;

  const Transaction({
    required this.id,
    required this.merchantId,
    required this.clientId,
    required this.amount,
    this.currency = 'XOF',
    required this.encryptedToken,
    this.status = TransactionStatus.pending,
    required this.method,
    required this.createdAt,
    this.syncedAt,
  });

  Transaction copyWith({TransactionStatus? status, DateTime? syncedAt}) =>
    Transaction(
      id:             id,
      merchantId:     merchantId,
      clientId:       clientId,
      amount:         amount,
      currency:       currency,
      encryptedToken: encryptedToken,
      status:         status ?? this.status,
      method:         method,
      createdAt:      createdAt,
      syncedAt:       syncedAt ?? this.syncedAt,
    );

  @override
  List<Object?> get props => [id, amount, status];
}
```

### 8.2 Use Case NFC — `lib/features/transfer/domain/usecases/initiate_nfc_payment_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../entities/transaction.dart';
import '../repositories/transfer_repository.dart';

class InitiateNfcPaymentUseCase {
  final TransferRepository _repo;
  const InitiateNfcPaymentUseCase(this._repo);

  /// [merchantId] : ID du marchand
  /// [clientId]   : ID du client (lu via NFC HCE)
  /// [amount]     : Montant à encaisser
  Future<Either<String, Transaction>> call({
    required String merchantId,
    required String clientId,
    required double amount,
  }) => _repo.initiateNfcPayment(
    merchantId: merchantId,
    clientId:   clientId,
    amount:     amount,
  );
}
```

### 8.3 Local DataSource — `lib/features/transfer/data/datasources/transfer_local_datasource.dart`

```dart
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/crypto_utils.dart';
import '../models/transaction_model.dart';

class TransferLocalDataSource {
  final Database    _db;
  final CryptoUtils _crypto;

  TransferLocalDataSource(this._db, this._crypto);

  /// Sauvegarde d'une transaction offline (RG 4)
  Future<TransactionModel> savePendingTransaction({
    required String merchantId,
    required String clientId,
    required double amount,
  }) async {
    final id    = const Uuid().v4();
    final token = await _crypto.encrypt(
      '{"id":"$id","from":"$clientId","to":"$merchantId","amount":$amount,"ts":"${DateTime.now().toIso8601String()}"}',
    );

    final data = {
      'id':              id,
      'merchant_id':     merchantId,
      'client_id':       clientId,
      'amount':          amount,
      'currency':        'XOF',
      'encrypted_token': token,
      'status':          'pending',
      'created_at':      DateTime.now().toIso8601String(),
    };
    await _db.insert('pending_transactions', data);
    return TransactionModel.fromJson(data);
  }

  /// Récupère toutes les transactions en attente (pour la télécollecte)
  Future<List<TransactionModel>> getPendingTransactions() async {
    final rows = await _db.query(
      'pending_transactions',
      where: 'status = ?',
      whereArgs: ['pending'],
    );
    return rows.map(TransactionModel.fromJson).toList();
  }

  /// Marquer une transaction comme synchronisée (RG 4)
  Future<void> markAsSynced(String transactionId) async {
    await _db.update(
      'pending_transactions',
      {
        'status':    'synced',
        'synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }
}
```

### 8.4 Page NFC — `lib/features/transfer/presentation/pages/send_payment_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../../../config/di/injection.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/transfer_bloc.dart';
import '../bloc/transfer_event.dart';
import '../bloc/transfer_state.dart';
import '../widgets/nfc_tap_widget.dart';
import '../widgets/amount_input_widget.dart';

/// Page côté MARCHAND : saisir le montant et encaisser par NFC
class SendPaymentPage extends StatefulWidget {
  const SendPaymentPage({super.key});

  @override
  State<SendPaymentPage> createState() => _SendPaymentPageState();
}

class _SendPaymentPageState extends State<SendPaymentPage> {
  double? _amount;
  bool    _nfcListening = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TransferBloc>(),
      child: BlocConsumer<TransferBloc, TransferState>(
        listener: (context, state) {
          if (state is TransferSuccess) {
            _stopNfc();
            context.pushReplacement(
              RouteNames.paymentSuccess,
              extra: state.transaction,
            );
          }
          if (state is TransferError) {
            _stopNfc();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Encaisser')),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  AmountInputWidget(
                    onAmountChanged: (v) => setState(() => _amount = v),
                  ),
                  const SizedBox(height: 32),
                  NfcTapWidget(isActive: _nfcListening),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: Icon(_nfcListening ? Icons.stop : Icons.nfc),
                    label: Text(_nfcListening
                      ? 'Annuler'
                      : 'Activer le NFC'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _nfcListening
                        ? AppColors.error
                        : AppColors.primary,
                    ),
                    onPressed: _amount == null
                      ? null
                      : () => _nfcListening
                        ? _stopNfc()
                        : _startNfc(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _startNfc(BuildContext context) {
    setState(() => _nfcListening = true);
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        // Lire l'ID client depuis le tag NFC (HCE)
        final identifier = tag.data['nfca']?['identifier'] as List<int>?;
        if (identifier != null && _amount != null) {
          final clientId = identifier.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
          context.read<TransferBloc>().add(
            InitiateNfcPayment(
              merchantId: 'MERCHANT_001', // TODO: récupérer depuis le profil
              clientId:   clientId,
              amount:     _amount!,
            ),
          );
        }
      },
    );
  }

  void _stopNfc() {
    NfcManager.instance.stopSession();
    setState(() => _nfcListening = false);
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }
}
```

### 8.5 Widget NFC — `lib/features/transfer/presentation/widgets/nfc_tap_widget.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NfcTapWidget extends StatefulWidget {
  final bool isActive;
  const NfcTapWidget({super.key, required this.isActive});

  @override
  State<NfcTapWidget> createState() => _NfcTapWidgetState();
}

class _NfcTapWidgetState extends State<NfcTapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double>   _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Icon(Icons.nfc, size: 80, color: Colors.grey.shade300);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) => Transform.scale(
        scale: _animation.value,
        child: child,
      ),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.nfcActive.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.nfcActive, width: 2),
        ),
        child: const Icon(Icons.nfc, size: 60, color: AppColors.nfcActive),
      ),
    );
  }
}
```

### 8.6 Widget QR — `lib/features/transfer/presentation/widgets/qr_display_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Affiche le QR code du client (fallback si pas de NFC)
class QrDisplayWidget extends StatelessWidget {
  final String data;       // Données chiffrées AES-256
  final double size;

  const QrDisplayWidget({
    super.key,
    required this.data,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF1A73E8),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF1A1F36),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Montrez ce QR code au marchand',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 9. Feature : Offline & Télécollecte

### 9.1 Service de télécollecte — `lib/features/transfer/data/datasources/sync_service.dart`

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/network/connectivity_service.dart';
import 'transfer_remote_datasource.dart';
import 'transfer_local_datasource.dart';

/// Service de télécollecte automatique (RG 4)
/// Déclenché dès le retour de la connectivité réseau
class SyncService {
  final ConnectivityService    _connectivity;
  final TransferLocalDataSource  _local;
  final TransferRemoteDataSource _remote;

  late StreamSubscription<bool> _subscription;

  SyncService(this._connectivity, this._local, this._remote);

  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        syncPendingTransactions();
      }
    });
  }

  void stopListening() => _subscription.cancel();

  /// Synchronise toutes les transactions en attente vers le serveur
  Future<SyncResult> syncPendingTransactions() async {
    final pending = await _local.getPendingTransactions();
    if (pending.isEmpty) return SyncResult(synced: 0, failed: 0);

    int synced = 0;
    int failed  = 0;

    for (final tx in pending) {
      try {
        await _remote.syncTransaction(tx);
        await _local.markAsSynced(tx.id);
        synced++;
      } catch (_) {
        failed++;
      }
    }

    return SyncResult(synced: synced, failed: failed);
  }
}

class SyncResult {
  final int synced;
  final int failed;
  SyncResult({required this.synced, required this.failed});
}
```

### 9.2 Repository implementation — `lib/features/transfer/data/repositories/transfer_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../datasources/transfer_remote_datasource.dart';
import '../datasources/transfer_local_datasource.dart';
import '../../../wallet/data/datasources/wallet_local_datasource.dart';

class TransferRepositoryImpl implements TransferRepository {
  final TransferRemoteDataSource _remote;
  final TransferLocalDataSource  _local;
  final WalletLocalDataSource    _walletLocal;
  final ConnectivityService      _connectivity;

  TransferRepositoryImpl({
    required TransferRemoteDataSource remote,
    required TransferLocalDataSource  local,
    required WalletLocalDataSource    walletLocal,
    required ConnectivityService      connectivity,
  })  : _remote       = remote,
        _local        = local,
        _walletLocal  = walletLocal,
        _connectivity = connectivity;

  @override
  Future<Either<String, Transaction>> initiateNfcPayment({
    required String merchantId,
    required String clientId,
    required double amount,
  }) async {
    // RG 3 : Déduire le solde local immédiatement
    final deducted = await _walletLocal.deductBalance(clientId, amount);
    if (!deducted) {
      return Left('Solde insuffisant');
    }

    final isOnline = await _connectivity.isConnected;

    if (isOnline) {
      // Mode en ligne : traitement immédiat via API
      try {
        final tx = await _remote.processPayment(
          merchantId: merchantId,
          clientId:   clientId,
          amount:     amount,
        );
        return Right(tx);
      } catch (e) {
        // Fallback en mode offline si l'API échoue
        final tx = await _local.savePendingTransaction(
          merchantId: merchantId,
          clientId:   clientId,
          amount:     amount,
        );
        return Right(tx);
      }
    } else {
      // Mode offline : stocker localement (RG 2, RG 4)
      final tx = await _local.savePendingTransaction(
        merchantId: merchantId,
        clientId:   clientId,
        amount:     amount,
      );
      return Right(tx);
    }
  }
}
```

---

## 10. Feature : KYC (Smile ID)

### 10.1 Use case — `lib/features/kyc/domain/usecases/submit_kyc_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../repositories/kyc_repository.dart';

class SubmitKycUseCase {
  final KycRepository _repo;
  const SubmitKycUseCase(this._repo);

  Future<Either<String, bool>> call({
    required String userId,
    required String country,
    required String idType, // 'national_id' | 'passport' | 'drivers_license'
  }) => _repo.submitKyc(
    userId:  userId,
    country: country,
    idType:  idType,
  );
}
```

### 10.2 Page KYC — `lib/features/kyc/presentation/pages/kyc_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:smile_id/smile_id.dart';
import '../../../../core/theme/app_colors.dart';

class KycPage extends StatefulWidget {
  const KycPage({super.key});

  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  bool _isLoading = false;

  Future<void> _startKyc() async {
    setState(() => _isLoading = true);
    try {
      // SmileID SDK — vérification d'identité
      await SmileId.initialize(
        partnerId: 'GENIUS_GROUPS_PARTNER_ID', // Remplacer par vrai ID
        authToken: 'AUTH_TOKEN',               // Généré côté serveur
        production: false,
      );

      // Lancement du flux KYC SmileID
      // Le SDK gère le scan du document + selfie liveness check
      final result = await SmileId.doSmileIdSelfieAndDocumentCapture(
        jobId: 'JOB_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'USER_ID', // TODO: récupérer depuis le profil
        country: 'CI',
        idType: 'NATIONAL_ID',
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vérification soumise avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur KYC : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification d\'identité')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vérifiez votre identité',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pour sécuriser votre compte et activer les plafonds élevés, '
              'nous avons besoin de vérifier votre identité. '
              'Munissez-vous de votre CNI ou passeport.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _StepItem(number: '1', label: "Photo de votre pièce d'identité"),
            const SizedBox(height: 16),
            _StepItem(number: '2', label: 'Selfie en direct (liveness check)'),
            const SizedBox(height: 16),
            _StepItem(number: '3', label: 'Validation automatique en quelques secondes'),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _startKyc,
              child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Démarrer la vérification'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String label;

  const _StepItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(label)),
      ],
    );
  }
}
```

---

## 11. Feature : Deposit (recharge Mobile Money)

### 11.1 Entity — `lib/features/deposit/domain/entities/deposit.dart`

```dart
enum MobileMoneyProvider { wave, orangeMoney, mtn, moov }

class Deposit {
  final String               id;
  final double               amount;
  final MobileMoneyProvider  provider;
  final String               phoneNumber;
  final String               status; // 'pending' | 'success' | 'failed'
  final DateTime             createdAt;

  const Deposit({
    required this.id,
    required this.amount,
    required this.provider,
    required this.phoneNumber,
    required this.status,
    required this.createdAt,
  });

  String get providerName => switch (provider) {
    MobileMoneyProvider.wave        => 'Wave',
    MobileMoneyProvider.orangeMoney => 'Orange Money',
    MobileMoneyProvider.mtn         => 'MTN MoMo',
    MobileMoneyProvider.moov        => 'Moov Money',
  };
}
```

### 11.2 Page Deposit — `lib/features/deposit/presentation/pages/deposit_page.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/deposit.dart';

class DepositPage extends StatefulWidget {
  const DepositPage({super.key});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  MobileMoneyProvider? _selectedProvider;
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recharger mon wallet')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choisir l\'opérateur',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 16),
            _ProviderGrid(
              selected: _selectedProvider,
              onSelect: (p) => setState(() => _selectedProvider = p),
            ),
            const SizedBox(height: 24),
            const Text('Montant à recharger',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ex: 5000',
                suffixText: 'XOF',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedProvider == null ? null : _processDeposit,
              child: const Text('Confirmer la recharge'),
            ),
          ],
        ),
      ),
    );
  }

  void _processDeposit() {
    // TODO: appel API virelo pour initier le débit Mobile Money
    // Le serveur Laravel orchestre avec l'opérateur choisi
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

class _ProviderGrid extends StatelessWidget {
  final MobileMoneyProvider? selected;
  final void Function(MobileMoneyProvider) onSelect;

  const _ProviderGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final providers = [
      (MobileMoneyProvider.wave,        'Wave',         const Color(0xFF1A6FE8)),
      (MobileMoneyProvider.orangeMoney, 'Orange Money', const Color(0xFFFF6600)),
      (MobileMoneyProvider.mtn,         'MTN MoMo',     const Color(0xFFFFCC00)),
      (MobileMoneyProvider.moov,        'Moov Money',   const Color(0xFF003399)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      physics: const NeverScrollableScrollPhysics(),
      children: providers.map((p) {
        final isSelected = selected == p.$1;
        return GestureDetector(
          onTap: () => onSelect(p.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? p.$3.withOpacity(0.1) : Colors.white,
              border: Border.all(
                color: isSelected ? p.$3 : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                p.$2,
                style: TextStyle(
                  color: isSelected ? p.$3 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

---

## 12. Feature : History

### 12.1 Page — `lib/features/history/presentation/pages/history_page.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../transfer/domain/entities/transaction.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 0, // TODO: BLoC
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => const _TransactionTile(),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.nfc, color: AppColors.primary, size: 20),
      ),
      title: const Text('Paiement NFC',
        style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('14 juin 2026 · 08:32',
        style: TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Text(
        '-500 XOF',
        style: TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

---

## 13. Feature : Notifications (FCM)

### 13.1 Service — `lib/features/notifications/data/datasources/notification_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging          _fcm   = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Demande de permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configuration des notifications locales
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      const InitializationSettings(android: androidInit),
    );

    // Canal dédié aux paiements (priorité haute)
    const channel = AndroidNotificationChannel(
      'payments',
      'Paiements',
      description: 'Confirmations et alertes de paiement',
      importance: Importance.max,
    );
    await _local
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

    // Réception des messages en premier plan
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'payments',
          'Paiements',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<String?> getToken() => _fcm.getToken();
}
```

---

## 14. Feature : Profile

### 14.1 Page — `lib/features/profile/presentation/pages/profile_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                const Text('Eliott YAO',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Text('+225 07 00 00 00 00',
                  style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _ProfileSection(title: 'Sécurité', items: [
            _ProfileItem(
              icon: Icons.fingerprint,
              label: 'Biométrie',
              onTap: () {},
            ),
            _ProfileItem(
              icon: Icons.verified_user_outlined,
              label: 'Vérification d\'identité (KYC)',
              onTap: () => context.push(RouteNames.kyc),
            ),
          ]),
          const SizedBox(height: 16),
          _ProfileSection(title: 'Mon compte', items: [
            _ProfileItem(
              icon: Icons.card_membership_outlined,
              label: 'Mes cartes virtuelles',
              onTap: () => context.push(RouteNames.card),
            ),
            _ProfileItem(
              icon: Icons.share_outlined,
              label: 'Partager mon QR Code',
              onTap: () => context.push(RouteNames.share),
            ),
          ]),
          const SizedBox(height: 16),
          _ProfileSection(title: 'Application', items: [
            _ProfileItem(
              icon: Icons.language,
              label: 'Langue',
              onTap: () {},
            ),
            _ProfileItem(
              icon: Icons.logout,
              label: 'Se déconnecter',
              color: AppColors.error,
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String        title;
  final List<Widget>  items;

  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color?   color;
  final VoidCallback onTap;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
      title: Text(label, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
```

---

## 15. Feature : Onboarding

### 15.1 Page — `lib/features/onboarding/presentation/pages/onboarding_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  final _pages = const [
    _OnboardingSlide(
      icon: Icons.nfc,
      title: 'Payez en un geste',
      description:
          'Approchez votre téléphone du terminal du marchand. '
          'Le paiement s\'effectue en moins d\'une seconde, '
          'même sans connexion internet.',
      color: AppColors.primary,
    ),
    _OnboardingSlide(
      icon: Icons.wifi_off,
      title: '100% Offline First',
      description:
          'virelo fonctionne même sans réseau. '
          'Vos transactions sont sécurisées localement '
          'et synchronisées dès le retour de la connexion.',
      color: AppColors.secondary,
    ),
    _OnboardingSlide(
      icon: Icons.fingerprint,
      title: 'Sécurisé par biométrie',
      description:
          'Chaque paiement est validé par votre empreinte digitale '
          'ou votre visage. Personne d\'autre ne peut payer '
          'à votre place.',
      color: AppColors.accent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: _pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Indicateurs de page
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i
                            ? AppColors.primary
                            : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (_page < _pages.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.go(RouteNames.phoneInput);
                      }
                    },
                    child: Text(
                      _page < _pages.length - 1 ? 'Suivant' : 'Commencer',
                    ),
                  ),
                  if (_page < _pages.length - 1) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go(RouteNames.phoneInput),
                      child: const Text('Passer'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   description;
  final Color    color;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: color),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 16. Feature : Card (cartes virtuelles)

Les cartes virtuelles sont générées côté serveur. Côté Flutter, la page affiche la liste et le détail.

```dart
// lib/features/card/domain/entities/virtual_card.dart
class VirtualCard {
  final String id;
  final String maskedNumber;  // ex: **** **** **** 4242
  final String expiryDate;    // ex: 12/27
  final String holderName;
  final bool   isActive;

  const VirtualCard({
    required this.id,
    required this.maskedNumber,
    required this.expiryDate,
    required this.holderName,
    required this.isActive,
  });
}
```

---

## 17. Feature : Share (partage QR)

```dart
// lib/features/share/presentation/pages/share_page.dart
import 'package:flutter/material.dart';
import '../../../transfer/presentation/widgets/qr_display_widget.dart';

class SharePage extends StatelessWidget {
  final String userId;
  const SharePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Le QR code encode l'ID utilisateur chiffré
    final qrData = 'virelo://pay?to=$userId';
    return Scaffold(
      appBar: AppBar(title: const Text('Mon QR Code')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrDisplayWidget(data: qrData, size: 240),
            const SizedBox(height: 24),
            const Text(
              'Montrez ce code au marchand\npour payer sans NFC',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 18. Feature : Billing

```dart
// lib/features/billing/domain/entities/bill.dart
class Bill {
  final String id;
  final String label;       // ex: 'Facture CIE n°123456'
  final double amount;
  final String status;      // 'unpaid' | 'paid'
  final DateTime dueDate;

  const Bill({
    required this.id,
    required this.label,
    required this.amount,
    required this.status,
    required this.dueDate,
  });
}
```

---

## 19. Feature : Conversion (taux de change)

```dart
// lib/features/conversion/domain/entities/exchange_rate.dart
class ExchangeRate {
  final String from;      // 'XOF'
  final String to;        // 'EUR', 'USD', 'GNF'...
  final double rate;
  final DateTime updatedAt;

  const ExchangeRate({
    required this.from,
    required this.to,
    required this.rate,
    required this.updatedAt,
  });

  double convert(double amount) => amount * rate;
}
```

---

## 20. Internationalisation (l10n)

### 20.1 `lib/l10n/app_fr.arb`

```json
{
  "@@locale": "fr",
  "appName": "virelo",
  "welcomeTitle": "Bienvenue sur virelo",
  "phoneInputLabel": "Votre numéro de téléphone",
  "otpSentMessage": "Code envoyé au {phone}",
  "@otpSentMessage": {
    "placeholders": {
      "phone": { "type": "String" }
    }
  },
  "balanceLabel": "Solde disponible",
  "offlineMode": "Mode hors ligne",
  "syncPending": "Synchronisation en attente",
  "paymentSuccess": "Paiement réussi",
  "paymentAmount": "{amount} {currency}",
  "@paymentAmount": {
    "placeholders": {
      "amount": { "type": "String" },
      "currency": { "type": "String" }
    }
  },
  "nfcActivate": "Activer le NFC",
  "nfcWaiting": "En attente du client...",
  "depositTitle": "Recharger mon wallet",
  "kycTitle": "Vérification d'identité",
  "profileTitle": "Profil",
  "historyTitle": "Historique",
  "logoutButton": "Se déconnecter",
  "errorGeneric": "Une erreur est survenue",
  "insufficientBalance": "Solde insuffisant",
  "biometricPrompt": "Validez le paiement avec votre empreinte"
}
```

### 20.2 `lib/l10n/app_en.arb`

```json
{
  "@@locale": "en",
  "appName": "virelo",
  "welcomeTitle": "Welcome to virelo",
  "phoneInputLabel": "Your phone number",
  "otpSentMessage": "Code sent to {phone}",
  "@otpSentMessage": {
    "placeholders": {
      "phone": { "type": "String" }
    }
  },
  "balanceLabel": "Available balance",
  "offlineMode": "Offline mode",
  "syncPending": "Sync pending",
  "paymentSuccess": "Payment successful",
  "paymentAmount": "{amount} {currency}",
  "@paymentAmount": {
    "placeholders": {
      "amount": { "type": "String" },
      "currency": { "type": "String" }
    }
  },
  "nfcActivate": "Enable NFC",
  "nfcWaiting": "Waiting for customer...",
  "depositTitle": "Top up my wallet",
  "kycTitle": "Identity verification",
  "profileTitle": "Profile",
  "historyTitle": "History",
  "logoutButton": "Log out",
  "errorGeneric": "An error occurred",
  "insufficientBalance": "Insufficient balance",
  "biometricPrompt": "Confirm payment with your fingerprint"
}
```

### 20.3 `lib/l10n/app_sw.arb`

```json
{
  "@@locale": "sw",
  "appName": "virelo",
  "balanceLabel": "Salio linalopo",
  "offlineMode": "Hali ya nje ya mtandao",
  "paymentSuccess": "Malipo yamefanikiwa"
}
```

### 20.4 `l10n.yaml` (à la racine du projet)

```yaml
arb-dir: lib/l10n
template-arb-file: app_fr.arb
output-localization-file: app_localizations.dart
```

---

## 21. Tests

### 21.1 Test unitaire BLoC Auth

**`test/features/auth/auth_bloc_test.dart`**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:virelo/features/auth/domain/entities/user.dart';
import 'package:virelo/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:virelo/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:virelo/features/auth/domain/usecases/login_usecase.dart';
import 'package:virelo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:virelo/features/auth/presentation/bloc/auth_event.dart';
import 'package:virelo/features/auth/presentation/bloc/auth_state.dart';

class MockSendOtpUseCase   extends Mock implements SendOtpUseCase {}
class MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}
class MockLoginUseCase     extends Mock implements LoginUseCase {}

void main() {
  late MockSendOtpUseCase   mockSendOtp;
  late MockVerifyOtpUseCase mockVerifyOtp;
  late MockLoginUseCase     mockLogin;

  setUp(() {
    mockSendOtp   = MockSendOtpUseCase();
    mockVerifyOtp = MockVerifyOtpUseCase();
    mockLogin     = MockLoginUseCase();
  });

  AuthBloc buildBloc() => AuthBloc(
    sendOtp:   mockSendOtp,
    verifyOtp: mockVerifyOtp,
    login:     mockLogin,
  );

  group('SendOtpRequested', () {
    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, OtpSent] quand le numéro est valide',
      build: buildBloc,
      setUp: () {
        when(() => mockSendOtp('+225070000000'))
          .thenAnswer((_) async => const Right('OTP envoyé'));
      },
      act: (bloc) => bloc.add(SendOtpRequested('+225070000000')),
      expect: () => [
        isA<AuthLoading>(),
        isA<OtpSent>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthError] quand le serveur retourne une erreur',
      build: buildBloc,
      setUp: () {
        when(() => mockSendOtp('+225000000000'))
          .thenAnswer((_) async => const Left('Numéro invalide'));
      },
      act: (bloc) => bloc.add(SendOtpRequested('+225000000000')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );
  });

  group('OtpVerifyRequested', () {
    const tUser = User(id: 'u1', phone: '+225070000000');

    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthAuthenticated] avec un OTP correct',
      build: buildBloc,
      setUp: () {
        when(() => mockVerifyOtp('+225070000000', '123456'))
          .thenAnswer((_) async => const Right(tUser));
      },
      act: (bloc) => bloc.add(OtpVerifyRequested('+225070000000', '123456')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
    );
  });
}
```

### 21.2 Test unitaire CryptoUtils

**`test/core/utils/crypto_utils_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:virelo/core/utils/crypto_utils.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage mockStorage;
  late CryptoUtils       cryptoUtils;

  setUp(() {
    mockStorage  = MockSecureStorage();
    cryptoUtils  = CryptoUtils(mockStorage);

    when(() => mockStorage.read(key: any(named: 'key')))
      .thenAnswer((_) async => null);
    when(() => mockStorage.write(
      key:   any(named: 'key'),
      value: any(named: 'value'),
    )).thenAnswer((_) async {});
  });

  test('chiffre et déchiffre un montant correctement', () async {
    const original = 2500.0;
    final encrypted = await cryptoUtils.encryptBalance(original);
    expect(encrypted, isNot(equals('2500.00')));

    // Simuler la lecture de la clé lors du déchiffrement
    when(() => mockStorage.read(key: 'aes_key'))
      .thenAnswer((_) async => null); // Force regen clé pour ce test

    // Le déchiffrement doit retrouver le même montant
    // Note: Dans ce test la clé est regénérée donc on teste le cycle complet
    final decrypted = await cryptoUtils.decryptBalance(encrypted);
    expect(decrypted, closeTo(original, 0.01));
  });

  test('deux chiffrements du même texte donnent des résultats différents (IV aléatoire)', () async {
    const text = 'données sensibles';
    final enc1 = await cryptoUtils.encrypt(text);
    final enc2 = await cryptoUtils.encrypt(text);
    expect(enc1, isNot(equals(enc2)));
  });
}
```

### 21.3 Test du service de télécollecte

**`test/features/transfer/sync_service_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:virelo/features/transfer/data/datasources/sync_service.dart';
import 'package:virelo/features/transfer/data/datasources/transfer_local_datasource.dart';
import 'package:virelo/features/transfer/data/datasources/transfer_remote_datasource.dart';
import 'package:virelo/features/transfer/data/models/transaction_model.dart';
import 'package:virelo/core/network/connectivity_service.dart';

class MockConnectivity        extends Mock implements ConnectivityService {}
class MockTransferLocal       extends Mock implements TransferLocalDataSource {}
class MockTransferRemote      extends Mock implements TransferRemoteDataSource {}

void main() {
  late MockConnectivity   mockConnectivity;
  late MockTransferLocal  mockLocal;
  late MockTransferRemote mockRemote;
  late SyncService        syncService;

  setUp(() {
    mockConnectivity = MockConnectivity();
    mockLocal        = MockTransferLocal();
    mockRemote       = MockTransferRemote();
    syncService = SyncService(mockConnectivity, mockLocal, mockRemote);
  });

  test('synchronise les transactions en attente et les marque comme traitées', () async {
    final pending = [
      TransactionModel.fake(id: 'tx1', amount: 500),
      TransactionModel.fake(id: 'tx2', amount: 250),
    ];

    when(() => mockLocal.getPendingTransactions())
      .thenAnswer((_) async => pending);
    when(() => mockRemote.syncTransaction(any()))
      .thenAnswer((_) async => {});
    when(() => mockLocal.markAsSynced(any()))
      .thenAnswer((_) async => {});

    final result = await syncService.syncPendingTransactions();

    expect(result.synced, equals(2));
    expect(result.failed,  equals(0));
    verify(() => mockLocal.markAsSynced('tx1')).called(1);
    verify(() => mockLocal.markAsSynced('tx2')).called(1);
  });
}
```

---

## 22. Build & déploiement

### 22.1 Commandes essentielles

```bash
# Récupérer les dépendances
flutter pub get

# Générer le code (injection, JSON, freezed)
dart run build_runner build --delete-conflicting-outputs

# Générer les fichiers l10n
flutter gen-l10n

# Lancer en développement
flutter run --dart-define=ENV=dev

# Tests unitaires
flutter test

# Tests avec couverture
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Build APK debug (test sur appareil)
flutter build apk --debug

# Build APK release signé
flutter build apk --release \
  --dart-define=ENV=prod

# Build App Bundle (Play Store)
flutter build appbundle --release \
  --dart-define=ENV=prod
```

### 22.2 Signature Android (release)

Créer `android/key.properties` (ne pas committer dans Git) :

```properties
storePassword=VOTRE_MOT_DE_PASSE
keyPassword=VOTRE_MOT_DE_PASSE_CLE
keyAlias=virelo
storeFile=../virelo-release.jks
```

Modifier `android/app/build.gradle` :

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias      keystoreProperties['keyAlias']
            keyPassword   keystoreProperties['keyPassword']
            storeFile     keystoreProperties['storeFile']
                          ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig     signingConfigs.release
            minifyEnabled     true
            shrinkResources   true
        }
    }
}
```

### 22.3 `.gitignore` (éléments importants)

```gitignore
# Clés & secrets
android/key.properties
*.jks
*.keystore
.env
.env.*
**/google-services.json

# Build
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies

# Coverage
coverage/
```

---

## 23. Checklist finale

### Avant la soutenance

- [ ] `flutter doctor` sans erreurs
- [ ] `flutter test` — tous les tests passent
- [ ] APK installé sur un vrai appareil Android NFC
- [ ] Test de paiement NFC physique (marchand ↔ client) fonctionnel
- [ ] Test de paiement QR Code fonctionnel
- [ ] Test mode offline : couper le Wi-Fi/données → paiement OK → réactiver → sync automatique
- [ ] Test biométrie : empreinte valide ✓ / empreinte invalide ✗
- [ ] Solde embarqué décrémenté immédiatement (RG 3)
- [ ] Transactions en attente marquées "synced" après télécollecte (RG 4)
- [ ] Recharge Mobile Money testée (au moins un opérateur)
- [ ] KYC Smile ID testé en mode sandbox

### Correspondance Règles de Gestion → Code

| RG | Description | Fichier implémentant |
|----|-------------|---------------------|
| RG 1 | Authentification biométrique obligatoire | `auth_local_datasource.dart` — `authenticateWithBiometric()` |
| RG 2 | Mode hybride Online/Offline-First | `transfer_repository_impl.dart` — `initiateNfcPayment()` |
| RG 3 | Déduction immédiate du solde embarqué | `wallet_local_datasource.dart` — `deductBalance()` |
| RG 4 | Télécollecte asynchrone | `sync_service.dart` — `syncPendingTransactions()` |
| RG 5 | Fallback QR Code / carte physique | `qr_display_widget.dart` + `share_page.dart` |
| RG 6 | Recharge via virelo (tous opérateurs) | `deposit_page.dart` + `deposit_remote_datasource.dart` |

### Correspondance Architecture → Mémoire

| Couche Clean Arch | Package Flutter | Section mémoire |
|---|---|---|
| Présentation | `flutter_bloc`, `go_router` | Chap. 6 — Clean Architecture |
| Domaine | Dart pur, `dartz` | Chap. 5 — Modélisation |
| Data (Remote) | `dio`, `smile_id`, `firebase_messaging` | Chap. 6 — Technologies |
| Data (Local) | `sqflite`, `flutter_secure_storage`, `local_auth` | Chap. 6 — Technologies |
| Config / DI | `get_it` | Chap. 6 — Architecture Flutter |

---

*Document généré pour le PFE de YAO Moye Eliott Kenan — ESATIC / GENIUS GROUPS — 2025-2026*
