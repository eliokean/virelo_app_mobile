import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:dio/dio.dart';

class OfflineSyncQueuePage extends StatefulWidget {
  const OfflineSyncQueuePage({super.key});

  @override
  State<OfflineSyncQueuePage> createState() => _OfflineSyncQueuePageState();
}

class _OfflineSyncQueuePageState extends State<OfflineSyncQueuePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiClient _apiClient = ApiClient();
  
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
      final existingReceiptsStr = await _storage.read(key: 'offline_receipts') ?? '[]';
      final List<dynamic> rawList = jsonDecode(existingReceiptsStr);
      _receipts = rawList.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error loading receipts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncAll() async {
    if (_receipts.isEmpty || _isSyncing) return;
    setState(() => _isSyncing = true);

    List<Map<String, dynamic>> failedReceipts = [];
    int successCount = 0;

    for (var receipt in _receipts) {
      try {
        await _apiClient.dio.post('/offline/sync', data: receipt);
        successCount++;
      } catch (e) {
        debugPrint('Error syncing receipt: $e');
        if (e is DioException) {
          debugPrint('DioException details: ${e.response?.data}');
        }
        failedReceipts.add(receipt);
      }
    }

    // Save only the failed ones back to storage
    await _storage.write(key: 'offline_receipts', value: jsonEncode(failedReceipts));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount synchronisés, ${failedReceipts.length} échecs.'),
          backgroundColor: failedReceipts.isEmpty ? const Color(0xFFB5E48C) : Colors.orange,
        ),
      );
    }

    setState(() {
      _receipts = failedReceipts;
      _isSyncing = false;
    });
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
      bottomNavigationBar: _receipts.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSyncing ? null : _syncAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB5E48C),
                      foregroundColor: const Color(0xFF131517),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      disabledBackgroundColor: const Color(0xFF2C3138),
                    ),
                    child: _isSyncing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF131517),
                            ),
                          )
                        : Text(
                            'Synchroniser tout',
                            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}
