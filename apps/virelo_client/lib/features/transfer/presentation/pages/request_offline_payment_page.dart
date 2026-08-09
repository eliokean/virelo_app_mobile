import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/network/api_client.dart';
import 'receive_offline_page.dart';

class RequestOfflinePaymentPage extends StatefulWidget {
  const RequestOfflinePaymentPage({super.key});

  @override
  State<RequestOfflinePaymentPage> createState() => _RequestOfflinePaymentPageState();
}

class _RequestOfflinePaymentPageState extends State<RequestOfflinePaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  String? _qrData;
  bool _isLoading = false;

  void _generateQr() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService(ApiClient());
      final merchantId = await authService.getUserId();
      
      if (merchantId == null) {
        throw Exception("Impossible de récupérer votre identifiant marchand.");
      }

      setState(() {
        _qrData = 'virelo://offline_pay?merchantId=$merchantId&amount=$amount';
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161A22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Initier Paiement Hors Ligne', style: AppTextStyles.headlineMedium.copyWith(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_qrData == null) ...[
                Text(
                  'Entrez le montant à encaisser',
                  style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: 'FCFA',
                    suffixStyle: const TextStyle(color: Colors.white54, fontSize: 20),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFB5E48C))),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _generateQr,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: const Color(0xFF161A22),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Color(0xFF161A22))
                        : const Text('Générer le Défi (QR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ] else ...[
                Text(
                  'Présentez ce code au client',
                  style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: 250.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ReceiveOfflinePage()),
                      );
                    },
                    icon: const Icon(LucideIcons.scan),
                    label: const Text('Scanner la Preuve du Client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: const Color(0xFF161A22),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => setState(() => _qrData = null),
                  child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
