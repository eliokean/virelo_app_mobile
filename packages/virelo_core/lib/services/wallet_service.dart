import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';
import 'dart:convert';
import 'auth_service.dart';

class WalletService {
  final ApiClient _apiClient;
  final AuthService _authService;

  WalletService(this._apiClient, this._authService);

  Future<Map<String, dynamic>> getBalance() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.walletBalance);
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return {'balance': 0};
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
      throw Exception(msg ?? 'Erreur lors de la récupération du solde');
    }
  }

  Future<Map<String, dynamic>> getOfflineBalance() async {
    try {
      final response = await _apiClient.dio.get('/offline/balance');
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return {'offline_balance': 0.0};
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
      throw Exception(msg ?? 'Erreur lors de la récupération du solde hors ligne');
    }
  }

  Future<Map<String, dynamic>> getHistory({int page = 1, int perPage = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.walletHistory,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      } else if (response.data is List) {
        return {
          'data': List<dynamic>.from(response.data),
          'has_more': false,
          'current_page': page,
          'total': (response.data as List).length,
        };
      }
      return {'data': [], 'has_more': false, 'current_page': page, 'total': 0};
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
      throw Exception(msg ?? 'Erreur lors de la récupération de l\'historique');
    }
  }

  Future<Map<String, dynamic>> topUp(double amount, String provider) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.initiateRecharge,
        data: {
          'amount': amount,
          'provider': provider,
        },
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return {};
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
      throw Exception(msg ?? 'Erreur lors du rechargement');
    }
  }

  Future<String> generateOfflinePaymentToken(double amount, String pin) async {
    // 1. Vérification du PIN en local
    final isValid = await _authService.verifyLocalPin(pin);
    if (!isValid) {
      throw Exception('Code PIN incorrect');
    }

    // 2. Récupération du user_id
    final userId = await _authService.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non connecté ou ID manquant');
    }

    // 3. Construction du payload attendu par CryptoLogic.php
    final payload = {
      'user_id': int.parse(userId),
      'amount': amount,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    // 4. Encodage en JSON puis Base64
    final jsonString = jsonEncode(payload);
    final base64Token = base64Encode(utf8.encode(jsonString));

    return base64Token;
  }
}
