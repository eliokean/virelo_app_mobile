import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import '../../../history/presentation/pages/history_page.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RecentActivityList extends StatefulWidget {
  const RecentActivityList({super.key});

  @override
  State<RecentActivityList> createState() => _RecentActivityListState();
}

class _RecentActivityListState extends State<RecentActivityList> {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedHistory();
    _fetchHistory();
  }

  Future<void> _loadCachedHistory() async {
    try {
      final cached = await _storage.read(key: 'cached_history');
      if (cached != null && mounted) {
        setState(() {
          _activities = jsonDecode(cached);
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await _apiClient.dio.get('/wallets/history');
      await _storage.write(key: 'cached_history', value: jsonEncode(response.data));
      if (mounted) {
        setState(() {
          _activities = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('Erreur lors de la récupération de l\'historique: $e');
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return "Aujourd'hui, ${DateFormat('HH:mm').format(date)}";
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        return "Hier, ${DateFormat('HH:mm').format(date)}";
      }
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  IconData _getIconForType(String type, bool isNegative) {
    if (type == 'c2c_transfer') {
      return isNegative ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft;
    }
    return LucideIcons.shoppingBag;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activité récente',
              style: AppTextStyles.labelLarge.copyWith(
                color: const Color(0xFF161A22),
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(
                LucideIcons.arrowRight,
                size: 20,
                color: Color(0xFF8B93A8),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFFB5E48C)))
        else if (_activities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text('Aucune activité récente.'),
          )
        else
          ..._activities.map((activity) {
            final isNegative = activity['is_negative'] ?? false;
            final amountStr = '${isNegative ? '-' : '+'}${activity['amount']} FCFA';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildActivityItem(
                icon: _getIconForType(activity['type'], isNegative),
                title: activity['title'] ?? 'Transaction',
                subtitle: _formatDate(activity['date']),
                amount: amountStr,
                isNegative: isNegative,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isNegative,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5), // Light grey
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: const Color(0xFF161A22),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: const Color(0xFF161A22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFF8B93A8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTextStyles.labelLarge.copyWith(
              color: isNegative ? const Color(0xFF161A22) : const Color(0xFF8DC973),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
