import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_spacing.dart';
import '../widgets/wallet_header.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/wallet_actions_bar.dart';
import '../widgets/send_again_section.dart';
import '../widgets/recent_activity_list.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

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
              child: const SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    SizedBox(height: AppSpacing.md),
                    WalletHeader(),
                    BalanceHeroCard(),
                    SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            
            // Middle Dark Section (Action Bar)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: WalletActionsBar(),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.screenH),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SendAgainSection(),
                        const SizedBox(height: AppSpacing.xxl),
                        const RecentActivityList(),
                        const SizedBox(height: AppSpacing.huge),
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
