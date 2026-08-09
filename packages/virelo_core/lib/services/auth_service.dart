import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';
import '../offline_sync/hive_manager.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  AuthService(this._apiClient);

  // ─── HELPER DEVICE INFO ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDeviceFingerprint() async {
    String deviceId = "unknown";
    bool hasKeystore = true; // Par défaut, on suppose qu'un tel récent l'a

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        // StrongBox dispo >= Android 9 (API 28)
        hasKeystore = androidInfo.version.sdkInt >= 28;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? "unknown_ios";
        hasKeystore = true; // Secure Enclave dispo
      }
    } catch (e) {
      // Fallback
    }

    return {
      'device_id': deviceId,
      'has_hardware_keystore': hasKeystore,
    };
  }

  // ── AUTHENTICATION BACKEND ───────────────────────────────────

  Future<Map<String, dynamic>> login(String phone, String password, {String? userType}) async {
    try {
      final deviceInfo = await getDeviceFingerprint();

      final Map<String, dynamic> requestData = {
        'phone': phone,
        'password': password,
        'device_id': deviceInfo['device_id'],
        'has_hardware_keystore': deviceInfo['has_hardware_keystore'],
      };
      
      if (userType != null) {
        requestData['user_type'] = userType;
      }

      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: requestData,
      );

      final data = response.data;
      if (data != null && data['token'] != null) {
        await _apiClient.saveToken(data['token']);
        if (data['user'] != null) {
          final userIdStr = data['user']['id']?.toString();
          if (userIdStr != null) {
            await _secureStorage.write(key: 'user_id', value: userIdStr);
          }
          if (data['user']['name'] != null) {
            await _secureStorage.write(key: 'user_name', value: data['user']['name'].toString());
          }
          if (data['user']['wallet'] != null && data['user']['wallet']['balance'] != null && userIdStr != null) {
             try {
               final balanceStr = data['user']['wallet']['balance'].toString();
               final box = await HiveManager.openOfflineBox();
               await box.put('offline_budget_$userIdStr', balanceStr);
             } catch (_) {}
          }
        }
      }
      return data;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map) {
        if (e.response?.statusCode == 403 || responseData['requires_device_verification'] == true) {
          return Map<String, dynamic>.from(responseData); // Renvoie les données pour la page OTP
        }
        throw Exception(responseData['message']?.toString() ?? 'Erreur lors de la connexion');
      }
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Impossible de joindre le serveur. Vérifiez la connexion et l\'URL backend.');
      }
      throw Exception('Erreur serveur (${e.response?.statusCode ?? 'inconnu'})');
    }
  }

  Future<Map<String, dynamic>> register(String name, String phone, String email, String password) async {
    try {
      final deviceInfo = await getDeviceFingerprint();

      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'device_id': deviceInfo['device_id'],
          'has_hardware_keystore': deviceInfo['has_hardware_keystore'],
        },
      );

      final data = response.data;
      if (data != null && data['token'] != null) {
        await _apiClient.saveToken(data['token']);
        if (data['user'] != null) {
          final userIdStr = data['user']['id']?.toString();
          if (userIdStr != null) {
            await _secureStorage.write(key: 'user_id', value: userIdStr);
          }
          if (data['user']['name'] != null) {
            await _secureStorage.write(key: 'user_name', value: data['user']['name'].toString());
          }
          if (data['user']['wallet'] != null && data['user']['wallet']['balance'] != null && userIdStr != null) {
             try {
               final balanceStr = data['user']['wallet']['balance'].toString();
               final box = await HiveManager.openOfflineBox();
               await box.put('offline_budget_$userIdStr', balanceStr);
             } catch (_) {}
          }
        }
      }
      return data;
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
      throw Exception(msg ?? 'Erreur lors de l\'inscription (${e.response?.statusCode ?? 'inconnu'})');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiConstants.logout);
    } catch (e) {
      // Ignorer
    } finally {
      final userId = await getUserId();
      if (userId != null) {
        try {
          final box = await HiveManager.openOfflineBox();
          await box.delete('offline_budget_$userId');
          await box.delete('offline_history_$userId');
        } catch (_) {}
      }
      await _apiClient.clearToken();
      await _secureStorage.delete(key: 'user_pin');
      await _secureStorage.delete(key: 'user_id');
      await _secureStorage.delete(key: 'user_name');
    }
  }

  Future<Map<String, dynamic>> verifyDevice(String phone, String otp) async {
    try {
      final deviceInfo = await getDeviceFingerprint();

      final response = await _apiClient.dio.post(
        '/verify-device', // Route API auth
        data: {
          'phone': phone,
          'otp': otp,
          'device_id': deviceInfo['device_id'],
          'has_hardware_keystore': deviceInfo['has_hardware_keystore'],
        },
      );

      final data = response.data;
      if (data != null && data['token'] != null) {
        await _apiClient.saveToken(data['token']);
        if (data['user'] != null) {
          final userIdStr = data['user']['id']?.toString();
          if (userIdStr != null) {
            await _secureStorage.write(key: 'user_id', value: userIdStr);
          }
          if (data['user']['name'] != null) {
            await _secureStorage.write(key: 'user_name', value: data['user']['name'].toString());
          }
          if (data['user']['wallet'] != null && data['user']['wallet']['balance'] != null && userIdStr != null) {
             try {
               final balanceStr = data['user']['wallet']['balance'].toString();
               final box = await HiveManager.openOfflineBox();
               await box.put('offline_budget_$userIdStr', balanceStr);
             } catch (_) {}
          }
        }
      }
      return data;
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
      throw Exception(msg ?? 'Code OTP invalide ou expiré (${e.response?.statusCode ?? 'inconnu'})');
    }
  }

  Future<String?> getUserId() async {
    return await _secureStorage.read(key: 'user_id');
  }

  Future<String?> getUserName() async {
    return await _secureStorage.read(key: 'user_name');
  }

  // ── GESTION DU PIN LOCAL ─────────────────────────────────────

  Future<void> saveLocalPin(String pin) async {
    await _secureStorage.write(key: 'user_pin', value: pin);
  }

  Future<bool> hasLocalPin() async {
    final pin = await _secureStorage.read(key: 'user_pin');
    return pin != null && pin.isNotEmpty;
  }

  Future<bool> verifyLocalPin(String inputPin) async {
    final storedPin = await _secureStorage.read(key: 'user_pin');
    return storedPin == inputPin;
  }

  // ── BIOMETRIE ────────────────────────────────────────────────

  Future<bool> isBiometricsAvailable() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return canCheck || isDeviceSupported;
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Déverrouillez Virelo avec votre empreinte',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // ── ONBOARDING ───────────────────────────────────────────────

  Future<bool> hasSeenOnboarding() async {
    final seen = await _secureStorage.read(key: 'has_seen_onboarding');
    return seen == 'true';
  }

  Future<void> setOnboardingSeen() async {
    await _secureStorage.write(key: 'has_seen_onboarding', value: 'true');
  }

  Future<void> resetOnboarding() async {
    await _secureStorage.delete(key: 'has_seen_onboarding');
  }
}

