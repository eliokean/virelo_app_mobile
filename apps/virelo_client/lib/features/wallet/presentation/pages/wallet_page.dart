import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/services/wallet_service.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/network/api_client.dart';
import '../widgets/wallet_header.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/wallet_actions_bar.dart';
import '../widgets/send_again_section.dart';
import '../widgets/recent_activity_list.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final WalletService _walletService;
  String _balance = "0";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _walletService = WalletService(apiClient, AuthService(apiClient));
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    try {
      final data = await _walletService.getBalance();
      if (mounted) {
        setState(() {
          _balance = data['balance']?.toString() ?? "0";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _balance = "0";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF161A22), // Dark middle section
        body: Column(
          children: [
            // Top Light Section
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE9E9F2),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    const WalletHeader(),
                    BalanceHeroCard(balance: _balance, isLoading: _isLoading),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            
            // Middle Dark Section (Action Bar)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: WalletActionsBar(onRefresh: _fetchBalance),
            ),

            // Bottom White Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                  child: const SingleChildScrollView(
                    padding: EdgeInsets.all(AppSpacing.screenH),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SendAgainSection(),
                        SizedBox(height: AppSpacing.xxl),
                        RecentActivityList(),
                        SizedBox(height: AppSpacing.huge),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
