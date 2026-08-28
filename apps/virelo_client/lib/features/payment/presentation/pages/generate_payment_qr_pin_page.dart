import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/virelo_design_system.dart';
import 'package:virelo_design_system/widgets/virelo_pin_pad.dart';
import 'package:virelo_design_system/widgets/virelo_alert_dialog.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'package:virelo_core/crypto/offline_crypto_service.dart';
import 'package:virelo_core/services/biometric_service.dart';
import '../../../../core/services/auto_sync_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'generate_payment_qr_display_page.dart';
import 'nfc_tap_to_pay_display_page.dart';

class GeneratePaymentQrPinPage extends StatefulWidget {
  final double amount;
  final String merchantId;
  final String merchantName;
  final bool isNfc;

  const GeneratePaymentQrPinPage({
    super.key, 
    required this.amount,
    this.merchantId = 'ANY',
    this.merchantName = 'un marchand',
    this.isNfc = true,
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

  Future<void> _onBiometricTap() async {
    if (_isLoading) return;
    final authenticated = await BiometricService().authenticate(
      'Veuillez vous authentifier pour valider ce paiement',
    );
    if (authenticated) {
      _generateToken(byPassPinCheck: true);
    }
  }

  Future<void> _generateToken({bool byPassPinCheck = false}) async {
    setState(() => _isLoading = true);

    try {
      // 1. Verify PIN if not bypassed by biometric authentication
      if (!byPassPinCheck) {
        final isValid = await _authService.verifyLocalPin(_pin);
        if (!isValid) throw Exception('Code PIN incorrect');
      }

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
            VireloInAppNotification.show(
              title: 'Paiement Effectué !',
              message: 'Paiement vers ${widget.merchantName} validé avec succès.',
              amount: widget.amount.toInt().toString(),
              type: InAppNotificationType.payment,
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

      // 3. Mode Cryptographique Ed25519 (Génération du jeton sécurisé)
      final offlineStorage = OfflineStorageService(_authService);
      final cryptoService = OfflineCryptoService(offlineStorage);
      await cryptoService.initializeKeys();
      final userId = await _authService.getUserId() ?? "UNKNOWN_CLIENT";
      
      final payload = await cryptoService.generateSignedPayload(
        clientId: userId,
        merchantId: widget.merchantId,
        amount: widget.amount,
      );

      // Déduire du budget et sauvegarder dans l'historique local UNIQUEMENT si le client est réellement hors-ligne
      if (!isOnline) {
        await offlineStorage.deductOfflineBudget(widget.amount);
        
        await offlineStorage.saveOfflineTransaction({
          'type': 'PAYMENT_OFFLINE',
          'amount': widget.amount,
          'status': 'PENDING_MERCHANT_SYNC',
          'uuid': payload.uuid,
          'merchantId': widget.merchantId,
          'sequenceNumber': payload.sequenceNumber,
          'timestamp': payload.timestamp,
          'clientPublicKey': payload.clientPublicKey,
          'clientSignature': payload.clientSignature,
          'validUntil': payload.validUntil,
        });
      }

      // Chiffrer le payload en Base64
      final encryptedToken = await cryptoService.encryptPayload(payload);

      // Déclencher la synchronisation automatique si possible
      AutoSyncManager().triggerSync();

      if (mounted) {
        if (widget.isNfc) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => NfcTapToPayDisplayPage(
                amount: widget.amount,
                token: encryptedToken,
                payload: payload,
              ),
            ),
          );
        } else {
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
      }
    } catch (e) {
      if (mounted) {
        VireloAlertDialog.showError(
          context,
          title: 'Oh non...',
          message: e.toString().replaceAll('Exception: ', ''),
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
              widget.isNfc 
                  ? 'Confirmez le paiement sans contact de ${widget.amount.toInt()} FCFA'
                  : 'Confirmez le paiement de ${widget.amount.toInt()} FCFA',
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
              onBiometricTap: _onBiometricTap,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
