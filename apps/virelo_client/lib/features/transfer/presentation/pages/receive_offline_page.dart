import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/crypto/offline_crypto_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'package:virelo_core/offline_sync/offline_authorization_payload.dart';
import 'transfer_amount_page.dart';

class ReceiveOfflinePage extends StatefulWidget {
  const ReceiveOfflinePage({super.key});

  @override
  State<ReceiveOfflinePage> createState() => _ReceiveOfflinePageState();
}

class _ReceiveOfflinePageState extends State<ReceiveOfflinePage> with SingleTickerProviderStateMixin {
  final MobileScannerController _cameraController = MobileScannerController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiClient _apiClient = ApiClient();
  late final OfflineCryptoService _offlineCryptoService;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final authService = AuthService(_apiClient);
    _offlineCryptoService = OfflineCryptoService(OfflineStorageService(authService));

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String rawData) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Check if it's a simple QR (e.g. virelo://pay?phone=... or just a phone number)
      final uri = Uri.tryParse(rawData);
      String? phone;
      if (uri != null && uri.queryParameters.containsKey('phone')) {
        phone = uri.queryParameters['phone'];
      } else if (RegExp(r'^\+?[0-9]{8,15}$').hasMatch(rawData)) {
        phone = rawData;
      }

      if (phone != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TransferAmountPage(
                beneficiaryName: 'Contact Scanné',
                beneficiaryPhone: phone!,
              ),
            ),
          );
        }
        return;
      }

      final payloadJson = jsonDecode(rawData);
      
      try {
        final payload = OfflineAuthorizationPayload.fromJson(payloadJson);
        
        // Vérification cryptographique réelle
        final isValid = await _offlineCryptoService.verifyPayload(payload);
        
        if (!isValid) {
          throw Exception('Signature cryptographique invalide (Tentative de fraude)');
        }

        // Tentative de synchronisation immédiate si réseau disponible
        bool syncSuccess = false;
        try {
          await _apiClient.dio.post('/offline/sync', data: payloadJson);
          syncSuccess = true;
        } catch (e) {
          // Erreur réseau ou API, on continue hors ligne
        }

        // Sauvegarde locale du reçu
        final existingReceiptsStr = await _storage.read(key: 'offline_receipts') ?? '[]';
        final List<dynamic> receipts = jsonDecode(existingReceiptsStr);
        receipts.add(payloadJson);
        await _storage.write(key: 'offline_receipts', value: jsonEncode(receipts));

        if (mounted) {
          _showSuccess(payload.amount.toString(), syncSuccess);
        }
      } catch (e) {
        throw Exception('Payload invalide: $e');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code Invalide ou corrompu')),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccess(String amount, bool synced) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161A22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB5E48C).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.checkCircle, color: Color(0xFFB5E48C), size: 48),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Paiement Sécurisé',
              style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              synced
                  ? 'Vous avez reçu $amount FCFA.\nLa transaction a été synchronisée avec succès !'
                  : 'Vous avez reçu $amount FCFA.\nLa transaction a été validée hors ligne et sera synchronisée dès votre retour réseau.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF161A22),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Terminer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const cutOutSize = 260.0;
    final topCutOut = (screenSize.height - cutOutSize) / 2 - 40;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Scanner Camera
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // 2. Cadrage QR Moderne
          Positioned.fill(
            child: CustomPaint(
              painter: _QrScannerOverlayPainter(
                cutOutSize: cutOutSize,
                cutOutTop: topCutOut,
              ),
            ),
          ),

          // 3. Faisceau Laser de Scan Animé
          Positioned(
            top: topCutOut,
            left: (screenSize.width - cutOutSize) / 2,
            width: cutOutSize,
            height: cutOutSize,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      top: _animation.value * (cutOutSize - 4),
                      left: 12,
                      right: 12,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFFB5E48C),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB5E48C).withOpacity(0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 4. Barre Supérieure avec Retour et Flash
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Encaissement Hors Ligne',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                      color: _isTorchOn ? AppColors.accent : Colors.white,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                    ),
                    onPressed: () async {
                      await _cameraController.toggleTorch();
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // 5. Instruction sous le cadrage
          Positioned(
            top: topCutOut + cutOutSize + 24,
            left: 20,
            right: 20,
            child: Text(
              'Scannez le QR Code de Preuve présenté par l\'expéditeur',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 6. Carte d'information en bas
          Positioned(
            bottom: 24,
            left: AppSpacing.screenH,
            right: AppSpacing.screenH,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFF161A22).withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.shieldCheck,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Preuve Cryptographique',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vérification hors-ligne sans connexion internet',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 7. Indicateur de chargement / traitement
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.accent),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Vérification cryptographique en cours...',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Peintre personnalisé pour le cadrage QR avec découpe et coins néon vert
class _QrScannerOverlayPainter extends CustomPainter {
  final double cutOutSize;
  final double cutOutTop;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final Color borderColor;
  final Color overlayColor;

  _QrScannerOverlayPainter({
    required this.cutOutSize,
    required this.cutOutTop,
    this.borderRadius = 24.0,
    this.borderLength = 32.0,
    this.borderWidth = 4.0,
    this.borderColor = const Color(0xFFB5E48C),
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.65),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final left = (size.width - cutOutSize) / 2;
    final top = cutOutTop;
    final right = left + cutOutSize;
    final bottom = top + cutOutSize;
    final cutOutRect = Rect.fromLTRB(left, top, right, bottom);

    // 1. Fond sombre avec découpe transparente
    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // 2. Bordure légère du cadre
    final frameBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      frameBorderPaint,
    );

    // 3. Les 4 coins néon renforcés
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final r = borderRadius;
    final l = borderLength;

    // Coin Haut-Gauche
    final topLeft = Path()
      ..moveTo(left, top + l)
      ..lineTo(left, top + r)
      ..arcToPoint(Offset(left + r, top), radius: Radius.circular(r))
      ..lineTo(left + l, top);
    canvas.drawPath(topLeft, cornerPaint);

    // Coin Haut-Droit
    final topRight = Path()
      ..moveTo(right - l, top)
      ..lineTo(right - r)
      ..arcToPoint(Offset(right, top + r), radius: Radius.circular(r))
      ..lineTo(right, top + l);
    canvas.drawPath(topRight, cornerPaint);

    // Coin Bas-Droit
    final bottomRight = Path()
      ..moveTo(right, bottom - l)
      ..lineTo(right, bottom - r)
      ..arcToPoint(Offset(right - r, bottom), radius: Radius.circular(r))
      ..lineTo(right - l, bottom);
    canvas.drawPath(bottomRight, cornerPaint);

    // Coin Bas-Gauche
    final bottomLeft = Path()
      ..moveTo(left + l, bottom)
      ..lineTo(left + r, bottom)
      ..arcToPoint(Offset(left, bottom - r), radius: Radius.circular(r))
      ..lineTo(left, bottom - l);
    canvas.drawPath(bottomLeft, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
