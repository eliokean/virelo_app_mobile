import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';

class OfflineClientHistoryPage extends StatefulWidget {
  const OfflineClientHistoryPage({super.key});

  @override
  State<OfflineClientHistoryPage> createState() => _OfflineClientHistoryPageState();
}

class _OfflineClientHistoryPageState extends State<OfflineClientHistoryPage> {
  late OfflineStorageService _offlineStorage;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _offlineStorage = OfflineStorageService(AuthService(ApiClient()));
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      _transactions = await _offlineStorage.getOfflineTransactions();
    } catch (e) {
      debugPrint('Error loading offline history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
          'Historique Hors Ligne',
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB5E48C)))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  margin: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2228),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Paiements effectués sans internet',
                        style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF8B93A8)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${_transactions.length} transaction(s)',
                        style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune transaction.',
                            style: AppTextStyles.bodyLarge.copyWith(color: const Color(0xFF8B93A8)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final tx = _transactions[index];
                            final amount = tx['amount'] ?? 0;
                            final dateStr = tx['date'] ?? '';
                            final merchantId = tx['merchantId'] ?? 'Inconnu';
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
                                    child: const Icon(LucideIcons.store, color: Colors.white70, size: 20),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Marchand $merchantId',
                                          style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                                        ),
                                        if (date != null)
                                          Text(
                                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                            style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF8B93A8)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '- $amount FCFA',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: Colors.white,
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
    );
  }
}
