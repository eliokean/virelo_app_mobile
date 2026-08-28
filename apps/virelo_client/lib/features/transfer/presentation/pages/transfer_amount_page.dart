import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/virelo_design_system.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'show_offline_proof_page.dart';

class TransferAmountPage extends StatefulWidget {
  final String beneficiaryName;
  final String beneficiaryPhone;
  
  const TransferAmountPage({
    super.key,
    required this.beneficiaryName,
    required this.beneficiaryPhone,
  });

  @override
  State<TransferAmountPage> createState() => _TransferAmountPageState();
}

class _TransferAmountPageState extends State<TransferAmountPage> {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _amount = "0";
  double? _balance;
  bool _isLoadingBalance = true;
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    try {
      final response = await _apiClient.dio.get('/wallets/balance');
      if (mounted) {
        setState(() {
          _balance = double.parse(response.data['balance'].toString());
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
      }
    }
  }

  Future<void> _executeTransfer() async {
    if (_amount == "0" || _amount.isEmpty) return;
    
    setState(() => _isTransferring = true);
    
    try {
      final response = await _apiClient.dio.post('/transfers/phone', data: {
        'phone': widget.beneficiaryPhone.replaceAll(RegExp(r'\s+'), ''),
        'amount': double.parse(_amount.replaceAll(' ', '').replaceAll(',', '.')),
      });
      
      if (mounted) {
        setState(() => _isTransferring = false);
        
        final isPending = response.data['is_pending_claim'] == true;
        final message = isPending 
            ? 'Transfert en attente. Un SMS a été envoyé au destinataire pour l\'inviter à s\'inscrire.'
            : 'Transfert effectué avec succès !';
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isPending ? const Color(0xFFE65100) : const Color(0xFF8DC973),
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _isTransferring = false);
        final errorMsg = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() ?? 'Erreur réseau, passage en mode hors ligne...' : 'Erreur réseau, passage en mode hors ligne...';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.orange),
        );
        _handleOfflineFallback();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTransferring = false);
        _handleOfflineFallback();
      }
    }
  }

  Future<void> _handleOfflineFallback() async {
    final offlineToken = await _storage.read(key: 'offline_token');
    final escrowSecret = await _storage.read(key: 'escrow_secret');
    if (offlineToken == null || escrowSecret == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun budget hors ligne alloué. Veuillez vous connecter.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      final jwt = JWT({
        'sender_token': offlineToken,
        'receiver_phone': widget.beneficiaryPhone,
        'amount': _amount,
        'nonce': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      
      final signedPayload = jwt.sign(SecretKey(escrowSecret));
      
      // We will send a json string that contains the signature so the scanner easily parses it
      final qrData = jsonEncode({
        'amount': _amount,
        'sender_token': offlineToken,
        'signature': signedPayload,
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShowOfflineProofPage(
              beneficiaryName: widget.beneficiaryName,
              amount: _amount,
              signedPayload: qrData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur cryptographique: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_amount == "0" && digit != ".") {
        _amount = digit;
      } else {
        if (digit == "." && _amount.contains(".")) return;
        if (_amount.replaceFirst('.', '').length >= 9) return;
        _amount += digit;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _deleteDigit() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = "0";
      }
    });
    HapticFeedback.lightImpact();
  }

  String get _formattedAmount {
    if (_amount == "0") return "0";
    final parts = _amount.split('.');
    String whole = parts[0];
    final result = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) result.write(' ');
      result.write(whole[i]);
    }
    if (parts.length > 1) {
      result.write(',${parts[1]}');
    } else if (_amount.endsWith('.')) {
      result.write(',');
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1C1D), // Dark header background
        body: Column(
          children: [
            // Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                      ),
                    ),
                    Text(
                      'Envoyer',
                      style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 48), // Spacer
                  ],
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9FA), // Light surface
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    // Amount Display
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Color(0xFFE8E8E9),
                                  child: Icon(LucideIcons.user, size: 14, color: Color(0xFF161A22)),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Vers ${widget.beneficiaryName}',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: const Color(0xFF161A22),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8E8E9),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'FCFA',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: const Color(0xFF1A1C1D),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              child: Text(
                                _formattedAmount,
                                style: AppTextStyles.displayLarge.copyWith(
                                  fontSize: 64,
                                  color: const Color(0xFF1A1C1D),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (_isLoadingBalance)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B93A8)),
                            )
                          else
                            Text(
                              'Solde actuel: ${_balance?.toStringAsFixed(0) ?? 0} FCFA',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: const Color(0xFF8B93A8),
                                letterSpacing: 1.2,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Numpad & Next Button
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.screenH),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: Offset(0, -5),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNumpad(),
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: (_amount == "0" || _isTransferring) ? null : _executeTransfer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent, // Virelo Green
                                disabledBackgroundColor: AppColors.surfaceBorder,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: _isTransferring
                                  ? const CircularProgressIndicator(color: Color(0xFF161A22))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Envoyer $_formattedAmount FCFA',
                                          style: AppTextStyles.headlineMedium.copyWith(
                                            color: const Color(0xFF161A22),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        const Icon(LucideIcons.send, color: Color(0xFF161A22)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (int i = 1; i <= 9; i++) _buildNumpadButton(i.toString()),
        _buildNumpadButton('.'),
        _buildNumpadButton('0'),
        _buildNumpadButton('del', isIcon: true),
      ],
    );
  }

  Widget _buildNumpadButton(String value, {bool isIcon = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isIcon) {
            _deleteDigit();
          } else {
            _appendDigit(value);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: isIcon
              ? const Icon(LucideIcons.delete, size: 28, color: Color(0xFF1A1C1D))
              : Text(
                  value,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: const Color(0xFF1A1C1D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
