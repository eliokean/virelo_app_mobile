import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../../core/services/auto_sync_manager.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/virelo_core.dart';
import 'package:virelo_core/crypto/offline_crypto_service.dart';

class ReceivePaymentPage extends StatefulWidget {
  const ReceivePaymentPage({super.key});

  @override
  State<ReceivePaymentPage> createState() => _ReceivePaymentPageState();
}

class _ReceivePaymentPageState extends State<ReceivePaymentPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() => _isProcessing = true);

        try {
          // Decode amount from token for local UI and offline storage
          double amount = 0;
          Map<String, dynamic> payload = {};
          try {
            // Le QR Code est chiffré en AES-GCM par le client, on doit le déchiffrer
            final cryptoService = OfflineCryptoService(OfflineStorageService(AuthService(ApiClient())));
            final decryptedPayload = await cryptoService.decryptPayload(code);

            // 1. Vérification de la signature cryptographique Ed25519 (Sécurité Hors-Ligne)
            final isValid = await cryptoService.verifyPayload(decryptedPayload);
            if (!isValid) {
              throw Exception("Signature cryptographique invalide ou falsifiée !");
            }

            // 2. Vérification de la validité temporelle (Anti-Rejeu / Expiration)
            if (decryptedPayload.validUntil.isNotEmpty) {
              final validUntilDate = DateTime.tryParse(decryptedPayload.validUntil);
              if (validUntilDate != null && DateTime.now().isAfter(validUntilDate.add(const Duration(seconds: 30)))) {
                throw Exception("Paiement rejeté : le jeton a expiré !");
              }
            }

            payload = decryptedPayload.toJson();
            amount = decryptedPayload.amount;
          } catch (e) {
            throw Exception("Format ou signature de jeton invalide: $e");
          }

          try {
            // First check connectivity explicitly
            final connectivityResult = await (Connectivity().checkConnectivity());
            final isOffline = connectivityResult.contains(ConnectivityResult.none);

            if (isOffline) {
              // Direct to offline
              final offlineService = OfflineSyncService(ApiClient());
              await offlineService.saveTransaction(jsonEncode(payload), amount);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Paiement hors-ligne de ${amount.toInt()} FCFA validé et stocké.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                Navigator.pop(context);
              }
              
              AutoSyncManager().triggerSync();
              return;
            }

            // If online, proceed with normal API request
            await ApiClient().dio.post(
              '/offline/sync',
              data: payload,
            );

            // Update GPS Position on payment
            TelemetryService().sendTerminalPing();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Paiement réussi ! ${amount.toInt()} FCFA encaissés.'),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context);
            }
          } on DioException catch (e) {
            // If it's a network error, we save offline (Telecollecte)
            if (e.type == DioExceptionType.connectionTimeout || 
                e.type == DioExceptionType.receiveTimeout || 
                e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.unknown ||
                (e.type == DioExceptionType.badResponse && 
                 [404, 500, 502, 503, 504].contains(e.response?.statusCode))) {
              
              final offlineService = OfflineSyncService(ApiClient());
              await offlineService.saveTransaction(jsonEncode(payload), amount);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hors-ligne : paiement mis en attente de synchronisation.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                Navigator.pop(context);
              }
              AutoSyncManager().triggerSync();
            } else {
              rethrow;
            }
          }
        } catch (e) {
          String errorMessage = 'Erreur lors de l\'encaissement';
          if (e is DioException) {
            if (e.response?.data is Map) {
              errorMessage = e.response?.data['message'] ?? e.message;
            } else {
              errorMessage = e.message ?? e.toString();
            }
          } else {
            errorMessage = e.toString();
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: AppColors.error,
              ),
            );
          }
          await Future.delayed(const Duration(seconds: 3));
          if (mounted) setState(() => _isProcessing = false);
        }
      }
    }
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
          // 1. Vue Caméra MobileScanner
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),

          // 2. Cadrage QR Moderne avec Découpe Sombre et Coins Verts Néon
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
                              Color(0xFF00E5A0),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5A0).withOpacity(0.8),
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

          // 4. Barre Supérieure avec Bouton Retour et Flash
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
                    'Encaisser par QR',
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
                    onPressed: () {
                      setState(() => _isTorchOn = !_isTorchOn);
                      cameraController.toggleTorch();
                    },
                  ),
                ],
              ),
            ),
          ),

          // 5. Carte d'indication en bas
          Positioned(
            bottom: 40,
            left: AppSpacing.screenH,
            right: AppSpacing.screenH,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222B).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5A0).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.scanLine,
                      color: Color(0xFF00E5A0),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isProcessing ? 'Validation en cours...' : 'Preuve de paiement',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isProcessing 
                              ? 'Vérification cryptographique...'
                              : 'Scannez le QR Code généré par le client.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isProcessing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00E5A0),
                      ),
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

/// CustomPainter pour le Cadrage QR Moderne avec découpe sombre et 4 coins néon
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
    this.borderColor = const Color(0xFF00E5A0),
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
      ..lineTo(right - r, top)
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
      ..lineTo(left + l, bottom);
    canvas.drawPath(bottomLeft, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
