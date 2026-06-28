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
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur lors de la récupération du solde');
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
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur lors du rechargement');
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
