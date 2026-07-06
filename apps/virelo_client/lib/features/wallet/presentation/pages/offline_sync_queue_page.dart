import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/constants/api_constants.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:dio/dio.dart';

class OfflineSyncQueuePage extends StatefulWidget {
  const OfflineSyncQueuePage({super.key});

  @override
  State<OfflineSyncQueuePage> createState() => _OfflineSyncQueuePageState();
}

class _OfflineSyncQueuePageState extends State<OfflineSyncQueuePage> {
  final ApiClient _apiClient = ApiClient();
  late final _offlineStorage = OfflineStorageService(AuthService(_apiClient));
  
  List<Map<String, dynamic>> _receipts = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);
    try {
      final history = await _offlineStorage.getOfflineTransactions();
      _receipts = history.where((t) => t['status'] == 'PENDING_MERCHANT_SYNC').toList();
    } catch (e) {
      debugPrint('Error loading offline receipts: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncStatuses() async {
    if (_receipts.isEmpty || _isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      // 1. Tenter d'abord de pousser les transactions au serveur (Client-Push)
      // Au cas où le marchand ne l'aurait pas encore fait.
      for (var receipt in _receipts) {
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
          // Fire and forget, si ça existe déjà le serveur ignorera (anti-rejeu)
          await _apiClient.dio.post('/offline/client-push', data: payload);
        } catch (_) {} 
      }

      // 2. Vérifier le statut de toutes nos transactions en attente
      final uuids = _receipts.map((e) => e['uuid'].toString()).toList();
      final response = await _apiClient.dio.post(
        ApiConstants.offlineStatus,
        data: {'uuids': uuids},
      );

      final statuses = response.data['statuses'] as Map<String, dynamic>;
      int syncedCount = 0;

      for (var uuid in uuids) {
        final status = statuses[uuid];
        if (status == 'completed') {
          await _offlineStorage.removeOfflineTransaction(uuid);
          syncedCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$syncedCount transaction(s) validée(s) par le marchand.'),
            backgroundColor: syncedCount > 0 ? const Color(0xFFB5E48C) : Colors.orange,
            action: SnackBarAction(
              label: 'OK', 
              textColor: Colors.black, 
              onPressed: () {},
            ),
          ),
        );
      }
      
      await _loadReceipts(); // reload
    } catch (e) {
      debugPrint('Error syncing offline statuses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la vérification des statuts.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  double get _totalAmount {
    return _receipts.fold(0.0, (sum, item) {
      final amount = item['amount'];
      if (amount is num) return sum + amount.toDouble();
      if (amount is String) return sum + (double.tryParse(amount) ?? 0.0);
      return sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131517),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131517),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reçus Hors Ligne',
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB5E48C)))
          : Column(
              children: [
                // Résumé
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  margin: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2228),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total en attente',
                        style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF8B93A8)),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_totalAmount.toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.displaySmall.copyWith(
                          color: const Color(0xFFB5E48C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${_receipts.length} transaction(s)',
                        style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Liste des reçus
                Expanded(
                  child: _receipts.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune transaction en attente.',
                            style: AppTextStyles.bodyLarge.copyWith(color: const Color(0xFF8B93A8)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          itemCount: _receipts.length,
                          itemBuilder: (context, index) {
                            final receipt = _receipts[index];
                            final amount = receipt['amount'];
                            final dateStr = receipt['timestamp'] ?? '';
                            final date = DateTime.tryParse(dateStr);
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D21),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF2C3138)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D2E33),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(LucideIcons.wifiOff, color: Colors.white70, size: 20),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Paiement Client',
                                          style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                                        ),
                                        if (date != null)
                                          Text(
                                            '${date.day}/${date.month} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                            style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF8B93A8)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '+ $amount FCFA',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: const Color(0xFFB5E48C),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      // Removed manual sync button because of AutoSyncManager
    );
  }
}
