import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_pin_pad.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'package:virelo_core/crypto/offline_crypto_service.dart';
import '../../../../core/services/auto_sync_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'generate_payment_qr_display_page.dart';

class GeneratePaymentQrPinPage extends StatefulWidget {
  final double amount;
  final String merchantId;
  final String merchantName;

  const GeneratePaymentQrPinPage({
    super.key, 
    required this.amount,
    this.merchantId = 'ANY',
    this.merchantName = 'un marchand',
  });

  @override
  State<GeneratePaymentQrPinPage> createState() => _GeneratePaymentQrPinPageState();
}

class _GeneratePaymentQrPinPageState extends State<GeneratePaymentQrPinPage> {
  String _pin = '';
  bool _isLoading = false;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _authService = AuthService(apiClient);
  }

  void _onDigitTap(String digit) {
    if (_isLoading) return;

    if (_pin.length < 4) {
      setState(() => _pin += digit);
      if (_pin.length == 4) {
        _generateToken();
      }
    }
  }

  void _onDeleteTap() {
    if (_isLoading) return;

    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _generateToken() async {
    setState(() => _isLoading = true);

    try {
      // 1. Verify PIN
      final isValid = await _authService.verifyLocalPin(_pin);
      if (!isValid) throw Exception('Code PIN incorrect');

      // 2. Si le client est en ligne et qu'il s'agit d'une facture marchand, payer directement en ligne
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);

      if (isOnline && widget.merchantId != 'ANY') {
        try {
          await ApiClient().dio.post('/transfers/merchant', data: {
            'merchant_id': widget.merchantId,
            'amount': widget.amount,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Paiement de ${widget.amount} FCFA effectué avec succès !'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
            return;
          }
        } on DioException catch (dioErr) {
          if (dioErr.response?.data is Map) {
            final msg = (dioErr.response!.data as Map)['message']?.toString();
            if (msg != null && (msg.contains('Solde insuffisant') || msg.contains('introuvable'))) {
              throw Exception(msg);
            }
          }
          // En cas d'erreur de connexion réseau, on bascule vers le mode hors-ligne
        }
      }

      // 3. Mode Hors-Ligne Cryptographique (Ed25519)
      final offlineStorage = OfflineStorageService(_authService);
      
      // Déduire du budget hors ligne
      await offlineStorage.deductOfflineBudget(widget.amount);

      // Générer la signature Ed25519 et le payload
      final cryptoService = OfflineCryptoService(offlineStorage);
      await cryptoService.initializeKeys();
      final userId = await _authService.getUserId() ?? "UNKNOWN_CLIENT";
      
      final payload = await cryptoService.generateSignedPayload(
        clientId: userId,
        merchantId: widget.merchantId,
        amount: widget.amount,
      );

      // Sauvegarder dans l'historique local
      await offlineStorage.saveOfflineTransaction({
        'type': 'PAYMENT_OFFLINE',
        'amount': widget.amount,
        'status': 'PENDING_MERCHANT_SYNC',
        'uuid': payload.uuid,
      });

      // Chiffrer le payload en Base64
      final encryptedToken = await cryptoService.encryptPayload(payload);

      // Déclencher la synchronisation automatique si possible
      AutoSyncManager().triggerSync();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GeneratePaymentQrDisplayPage(
              amount: widget.amount,
              token: encryptedToken,
              payload: payload,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _pin = '');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text(
              'Code PIN',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Confirmez le paiement de ${widget.amount} FCFA',
              style: AppTextStyles.bodyMedium,
            ),
            if (widget.merchantId != 'ANY')
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'vers ${widget.merchantName}',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            const Spacer(flex: 2),
            
            if (_isLoading)
              const CircularProgressIndicator(color: AppColors.accent)
            else
              VireloPinDots(pinLength: _pin.length),
            
            const Spacer(flex: 3),
            VireloPinPad(
              onDigitTap: _onDigitTap,
              onDeleteTap: _onDeleteTap,
              showBiometric: true,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
