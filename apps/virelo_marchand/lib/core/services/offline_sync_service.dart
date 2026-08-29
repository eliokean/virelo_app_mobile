import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/virelo_core.dart';

class OfflineSyncService {
  static const String _storageKey = 'offline_transactions';
  final ApiClient _apiClient;
  final Uuid _uuid = const Uuid();

  OfflineSyncService(this._apiClient);

  Future<void> saveTransaction(String token, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> transactionsJson = prefs.getStringList(_storageKey) ?? [];

    final now = DateTime.now();
    final localTimestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    
    final transaction = {
      'uuid_client': _uuid.v4(),
      'token': token,
      'amount': amount,
      'local_timestamp': localTimestamp,
    };

    transactionsJson.add(jsonEncode(transaction));
    await prefs.setStringList(_storageKey, transactionsJson);
  }

  Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(_storageKey) ?? [];
    
    return transactionsJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
  }

  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_storageKey) ?? []).length;
  }

  Future<double> getPendingAmount() async {
    final transactions = await getPendingTransactions();
    double total = 0;
    for (var tx in transactions) {
      total += (tx['amount'] as num).toDouble();
    }
    return total;
  }

  Future<void> syncPendingTransactions() async {
    final transactions = await getPendingTransactions();
    if (transactions.isEmpty) return;

    try {
      final batchId = 'batch_${_uuid.v4()}';
      
      // Capture GPS location if available
      double? lat;
      double? lng;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 3),
            );
            lat = pos.latitude;
            lng = pos.longitude;
          }
        }
      } catch (_) {}

      final payload = {
        'batch_id': batchId,
        'transactions': transactions,
        if (lat != null && lng != null) 'latitude': lat,
        if (lat != null && lng != null) 'longitude': lng,
        'location_name': lat != null ? 'Position GPS Réelle (Télécollecte)' : 'Abidjan, Côte d’Ivoire',
        'battery_level': 85,
      };

      final response = await _apiClient.dio.post(
        '/sync/telecollecte',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        // Success, clear local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_storageKey);
        
        // Trigger live ping in background
        TelemetryService().sendTerminalPing();
      } else {
        throw Exception('Échec de la synchronisation');
      }
    } catch (e) {
      throw Exception('Erreur de synchronisation: $e');
    }
  }
}
