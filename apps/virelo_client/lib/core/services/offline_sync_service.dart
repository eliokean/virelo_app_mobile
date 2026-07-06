import 'package:flutter/foundation.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/constants/api_constants.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';

class OfflineSyncService {
  final ApiClient _apiClient;
  final OfflineStorageService _offlineStorage;
  bool _isSyncing = false;

  OfflineSyncService(this._apiClient, this._offlineStorage);

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final history = await _offlineStorage.getOfflineTransactions();
      final receipts = history.where((t) => t['status'] == 'PENDING_MERCHANT_SYNC').toList();
      
      if (receipts.isEmpty) {
        _isSyncing = false;
        return;
      }

      // 1. Tenter d'abord de pousser les transactions au serveur (Client-Push)
      for (var receipt in receipts) {
        if (receipt['uuid'] == null || receipt['clientSignature'] == null) continue;
        
        try {
          final payload = {
            'merchantId': receipt['merchantId'] ?? receipt['receiverId'] ?? 'ANY',
            'amount': receipt['amount'],
            'uuid': receipt['uuid'],
            'sequenceNumber': receipt['sequenceNumber'],
            'timestamp': receipt['timestamp'],
            'clientPublicKey': receipt['clientPublicKey'],
            'clientSignature': receipt['clientSignature'],
          };
          // Fire and forget
          await _apiClient.dio.post('/offline/client-push', data: payload);
        } catch (e) {
          debugPrint('Error pushing client transaction: $e');
        } 
      }

      // 2. Vérifier le statut
      final uuids = receipts.map((e) => e['uuid'].toString()).toList();
      final response = await _apiClient.dio.post(
        ApiConstants.offlineStatus,
        data: {'uuids': uuids},
      );

      final statuses = response.data['statuses'] as Map<String, dynamic>;

      for (var uuid in uuids) {
        final status = statuses[uuid];
        if (status == 'completed') {
          await _offlineStorage.removeOfflineTransaction(uuid);
        }
      }
    } catch (e) {
      debugPrint('Error during background auto-sync: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
