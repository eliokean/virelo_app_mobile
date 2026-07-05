import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthService(this._apiClient);

  // ── AUTHENTICATION BACKEND ───────────────────────────────────

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {
          'phone': phone,
          'password': password,
        },
      );

      final data = response.data;
      if (data != null && data['token'] != null) {
        await _apiClient.saveToken(data['token']);
        if (data['user'] != null) {
          if (data['user']['id'] != null) {
            await _secureStorage.write(key: 'user_id', value: data['user']['id'].toString());
          }
          if (data['user']['name'] != null) {
            await _secureStorage.write(key: 'user_name', value: data['user']['name'].toString());
          }
        }
      }
      return data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur lors de la connexion');
    }
  }

  Future<Map<String, dynamic>> register(String name, String phone, String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );

      final data = response.data;
      if (data != null && data['token'] != null) {
        await _apiClient.saveToken(data['token']);
        if (data['user'] != null) {
          if (data['user']['id'] != null) {
            await _secureStorage.write(key: 'user_id', value: data['user']['id'].toString());
          }
          if (data['user']['name'] != null) {
            await _secureStorage.write(key: 'user_name', value: data['user']['name'].toString());
          }
        }
      }
      return data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur lors de l\'inscription');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiConstants.logout);
    } catch (e) {
      // Ignorer
    } finally {
      await _apiClient.clearToken();
      await _secureStorage.delete(key: 'user_pin');
      await _secureStorage.delete(key: 'user_id');
      await _secureStorage.delete(key: 'user_name');
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
}
