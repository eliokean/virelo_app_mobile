import 'package:dio/dio.dart';
import '../network/api_client.dart';

class MerchantService {
  final ApiClient _apiClient;

  MerchantService(this._apiClient);

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _apiClient.dio.get('/merchant/dashboard/stats');
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return {};
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
      throw Exception(msg ?? 'Erreur lors de la récupération des statistiques');
    }
  }

  Future<List<dynamic>> getTransactions({int perPage = 15}) async {
    try {
      final response = await _apiClient.dio.get('/merchant/dashboard/transactions', queryParameters: {
        'per_page': perPage,
      });
      if (response.data is Map && response.data['data'] is List) {
        return response.data['data'];
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
      throw Exception(msg ?? 'Erreur lors de la récupération des transactions');
    }
  }
}
