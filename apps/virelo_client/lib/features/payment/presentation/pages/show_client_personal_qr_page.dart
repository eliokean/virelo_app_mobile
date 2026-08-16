import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';

class ShowClientPersonalQrPage extends StatefulWidget {
  const ShowClientPersonalQrPage({super.key});

  @override
  State<ShowClientPersonalQrPage> createState() => _ShowClientPersonalQrPageState();
}

class _ShowClientPersonalQrPageState extends State<ShowClientPersonalQrPage> {
  String _userName = 'Client Virelo';
  String _userId = '0';
  String _phone = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = AuthService(ApiClient());
      final userName = await authService.getUserName();
      final userId = await authService.getUserId();

      if (mounted) {
        setState(() {
          _userName = userName ?? 'Client Virelo';
          _userId = userId ?? '0';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientQrData = jsonEncode({
      'type': 'client_account',
      'id': _userId,
      'name': _userName,
      'phone': _phone,
    });

    return Scaffold(
      backgroundColor: const Color(0xFF161A22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mon QR Code Client',
          style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              Text(
                _userName,
                style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Faites scanner ce code par le marchand pour régler votre achat',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              if (_isLoading)
                const CircularProgressIndicator(color: AppColors.accent)
              else
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: clientQrData,
                        version: QrVersions.auto,
                        size: 240.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _phone.isNotEmpty ? _phone : 'Compte Client Virelo',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: const Color(0xFF161A22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
