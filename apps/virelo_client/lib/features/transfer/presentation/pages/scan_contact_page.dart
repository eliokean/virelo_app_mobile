import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/crypto/offline_crypto_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'show_offline_proof_page.dart';

class ScanContactPage extends StatefulWidget {
  const ScanContactPage({super.key});

  @override
  State<ScanContactPage> createState() => _ScanContactPageState();
}

class _ScanContactPageState extends State<ScanContactPage> with SingleTickerProviderStateMixin {
  bool _isProcessingOfflinePayment = false;
  bool _isTorchOn = false;
  final MobileScannerController _cameraController = MobileScannerController();
  late final OfflineCryptoService _offlineCryptoService;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final authService = AuthService(ApiClient());
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const cutOutSize = 260.0;
    final topCutOut = (screenSize.height - cutOutSize) / 2 - 40;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Vue Caméra Plein Écran
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              if (_isProcessingOfflinePayment) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  final uri = Uri.tryParse(rawValue);
                  // Détection d'un paiement hors ligne
                  if (uri != null && uri.scheme == 'virelo' && uri.host == 'offline_pay') {
                    final merchantId = uri.queryParameters['merchantId'] ?? 'ANY';
                    final amountStr = uri.queryParameters['amount'] ?? '0';
                    final amount = double.tryParse(amountStr) ?? 0.0;
                    
                    _handleOfflinePayment(merchantId, amount);
                    return;
                  }
                  
                  // QR code contenant un numéro de téléphone (virelo://pay?phone=XXXX)
                  if (uri != null && uri.queryParameters.containsKey('phone')) {
                    Navigator.pop(context, uri.queryParameters['phone']);
                    return;
                  }
                  // Ou juste la valeur brute scannée (ex: numéro)
                  Navigator.pop(context, rawValue);
                  return;
                }
              }
            },
          ),

          // 2. Cadrage QR Moderne avec Découpe Sombre et Coins Verts
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
                    'Scanner QR Code',
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
            child: Column(
              children: [
                Text(
                  'Placez le QR Code de votre contact dans le cadre',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
                      LucideIcons.qrCode,
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
                          'Scanner le Destinataire',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Visez le code QR Virelo du destinataire pour remplir automatiquement le numéro',
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
          
          // Indicateur de chargement si paiement hors ligne en cours
          if (_isProcessingOfflinePayment)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.accent),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Génération du paiement sécurisé...',
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

  Future<void> _handleOfflinePayment(String merchantId, double amount) async {
    if (!mounted) return;
    setState(() {
      _isProcessingOfflinePayment = true;
    });

    try {
      await _offlineCryptoService.initializeKeys();
      
      final authService = AuthService(ApiClient());
      final clientId = await authService.getUserId();
      
      if (clientId == null || clientId.isEmpty) {
        throw Exception("Vous devez être connecté pour effectuer un paiement hors ligne.");
      }

      final offlineStorage = OfflineStorageService(authService);
      final currentBudget = await offlineStorage.getOfflineBudget();
      
      if (currentBudget < amount) {
        throw Exception("Solde hors ligne insuffisant (Reste : $currentBudget FCFA)");
      }

      final payload = await _offlineCryptoService.generateSignedPayload(
        clientId: clientId,
        merchantId: merchantId,
        amount: amount,
      );

      // Déduire le solde et enregistrer la transaction
      await offlineStorage.deductOfflineBudget(amount);
      await offlineStorage.saveOfflineTransaction({
        'merchantId': merchantId,
        'amount': amount,
        'type': 'payment_sent',
        'uuid': payload.uuid,
        'sequenceNumber': payload.sequenceNumber,
        'timestamp': payload.timestamp,
        'clientPublicKey': payload.clientPublicKey,
        'clientSignature': payload.clientSignature,
      });

      if (mounted) {
        setState(() {
          _isProcessingOfflinePayment = false;
        });
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ShowOfflineProofPage(
              beneficiaryName: "Marchand $merchantId",
              amount: amount.toString(),
              signedPayload: jsonEncode(payload.toJson()),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur hors ligne: $e')),
        );
        setState(() {
          _isProcessingOfflinePayment = false;
        });
      }
    }
  }
}

/// Peintre personnalisé pour le cadrage QR avec découpe et coins néon
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
      ..lineTo(left, bottom - l);
    canvas.drawPath(bottomLeft, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
