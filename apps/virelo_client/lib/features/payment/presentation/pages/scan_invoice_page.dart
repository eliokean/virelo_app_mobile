import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'generate_payment_qr_pin_page.dart';

class ScanInvoicePage extends StatefulWidget {
  const ScanInvoicePage({super.key});

  @override
  State<ScanInvoicePage> createState() => _ScanInvoicePageState();
}

class _ScanInvoicePageState extends State<ScanInvoicePage> with SingleTickerProviderStateMixin {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  bool _isTorchOn = false;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
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
          // 'ANY' = jeton au porteur (le serveur l'accepte mais journalise) ;
          // ne jamais fabriquer un id numérique arbitraire ('1') qui pourrait
          // matcher/mismatcher un vrai compte marchand.
          String merchantId = 'ANY';
          String merchantName = 'Marchand';
          double amount = 0.0;

          if (code.contains('/pay?') || code.startsWith('http')) {
            final uri = Uri.parse(code);
            merchantId = uri.queryParameters['m'] ?? 'ANY';
            merchantName = Uri.decodeComponent(uri.queryParameters['n'] ?? 'Marchand');
            amount = double.tryParse(uri.queryParameters['a'] ?? '0') ?? 0.0;
          } else {
            final invoiceData = jsonDecode(code);
            merchantId = invoiceData['merchantId']?.toString() ?? 'ANY';
            merchantName = invoiceData['merchantName']?.toString() ?? 'Marchand';
            amount = (invoiceData['amount'] as num).toDouble();
          }

          if (amount <= 0) throw Exception("Montant de facture invalide");

          // Arrêter la caméra et passer à la page du PIN
          cameraController.stop();
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => GeneratePaymentQrPinPage(
                  amount: amount,
                  merchantId: merchantId,
                  merchantName: merchantName,
                  isNfc: false,
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Le QR Code scanné n'est pas une facture valide."),
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
                    'Scanner la facture',
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
                      await cameraController.toggleTorch();
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
              'Placez le QR Code de la facture dans le cadre',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 6. Carte d'information Marchand en bas
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
                      LucideIcons.receipt,
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
                          'Paiement Marchand',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Scannez la facture affichée sur le TPE ou l\'écran',
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
                      'Traitement de la facture...',
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
