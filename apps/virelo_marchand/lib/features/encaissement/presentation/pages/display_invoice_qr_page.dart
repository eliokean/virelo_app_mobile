import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_primary_button.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/merchant_service.dart';
import 'receive_payment_page.dart';

class DisplayInvoiceQrPage extends StatefulWidget {
  final int merchantId;
  final String merchantName;
  final double amount;

  const DisplayInvoiceQrPage({
    super.key,
    required this.merchantId,
    required this.merchantName,
    required this.amount,
  });

  @override
  State<DisplayInvoiceQrPage> createState() => _DisplayInvoiceQrPageState();
}

class _DisplayInvoiceQrPageState extends State<DisplayInvoiceQrPage> {
  late final MerchantService _merchantService;
  Timer? _pollingTimer;
  bool _isOnline = true;
  bool _isPaid = false;
  int _initialTxCount = -1;
  dynamic _latestTxId;

  @override
  void initState() {
    super.initState();
    _merchantService = MerchantService(ApiClient());
    _checkConnectivity();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = !result.contains(ConnectivityResult.none);
      });
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final result = await Connectivity().checkConnectivity();
      final online = !result.contains(ConnectivityResult.none);

      if (mounted && online != _isOnline) {
        setState(() => _isOnline = online);
      }

      if (!online || _isPaid) return;

      try {
        final txList = await _merchantService.getTransactions(perPage: 5);
        if (_initialTxCount == -1) {
          _initialTxCount = txList.length;
          if (txList.isNotEmpty) {
            _latestTxId = txList.first['id'] ?? txList.first['reference'];
          }
          return;
        }

        // Vérification d'une NOUVELLE transaction reçue depuis l'ouverture de l'écran
        if (txList.isNotEmpty) {
          final currentLatestId = txList.first['id'] ?? txList.first['reference'];
          final isNewTx = (currentLatestId != null && currentLatestId != _latestTxId) || (txList.length > _initialTxCount);
          
          if (isNewTx) {
            final latestTx = txList.first;
            final latestAmount = double.tryParse(latestTx['amount']?.toString() ?? '0') ?? 0;
            
            if (latestAmount == widget.amount || widget.amount == 0) {
              _pollingTimer?.cancel();
              if (mounted) {
                setState(() {
                  _isPaid = true;
                });
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                });
              }
            }
          }
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final invoiceData = 'https://backend-virelo.onrender.com/pay?m=${widget.merchantId}&n=${Uri.encodeComponent(widget.merchantName)}&a=${widget.amount.toInt()}';

    return Scaffold(
      backgroundColor: const Color(0xFF161A22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _isPaid ? _buildPaidSuccessView() : _buildQrDisplayView(invoiceData),
          ),
        ),
      ),
    );
  }

  Widget _buildQrDisplayView(String invoiceData) {
    final formattedAmount = widget.amount.toInt().toString();

    return LayoutBuilder(
      key: const ValueKey('qr_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Facture à payer',
                    style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Demandez au client de scanner ce code pour régler $formattedAmount FCFA',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Badge Statut Réseau
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isOnline ? AppColors.accent.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _isOnline ? AppColors.accent : Colors.orange),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isOnline) ...[
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'EN LIGNE — En attente du règlement...',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else ...[
                          const Icon(LucideIcons.wifiOff, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'MODE HORS-LIGNE',
                            style: AppTextStyles.labelSmall.copyWith(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // QR Code Box (Dynamic size)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: QrImageView(
                      data: invoiceData,
                      version: QrVersions.auto,
                      size: 210.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpacing.lg),

                  // Bouton d'urgence Hors-Ligne uniquement si PAS en ligne ou en option secondaire
                  if (!_isOnline) ...[
                    SizedBox(
                      width: double.infinity,
                      child: VireloPrimaryButton(
                        label: 'Scanner la preuve client',
                        icon: LucideIcons.qrCode,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReceivePaymentPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReceivePaymentPage(),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.scan, color: Colors.white38, size: 16),
                        label: Flexible(
                          child: Text(
                            'Scanner la preuve (Secours Hors-Ligne)',
                            style: AppTextStyles.labelSmall.copyWith(color: Colors.white38),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaidSuccessView() {
    return Center(
      key: const ValueKey('success_view'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle2,
              color: AppColors.accent,
              size: 80,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Paiement Reçu !',
            style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontSize: 32),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vous avez reçu ${widget.amount.toInt()} FCFA de votre client.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
