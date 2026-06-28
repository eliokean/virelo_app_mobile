import 'package:dio/dio.dart';
import '../network/api_client.dart';

class MerchantService {
  final ApiClient _apiClient;

  MerchantService(this._apiClient);

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _apiClient.dio.get('/merchant/dashboard/stats');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur lors de la récupération des statistiques');
    }
  }

  Future<List<dynamic>> getTransactions({int perPage = 15}) async {
    try {
      final response = await _apiClient.dio.get('/merchant/dashboard/transactions', queryParameters: {
        'per_page': perPage,
      });
      return response.data['data'] ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur lors de la récupération des transactions');
    }
  }
}
