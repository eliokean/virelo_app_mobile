import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_primary_button.dart';
import 'package:virelo_design_system/widgets/virelo_text_field.dart';
import 'package:dio/dio.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/biometric_service.dart';

class WithdrawalPage extends StatefulWidget {
  final double currentBalance;

  const WithdrawalPage({
    super.key,
    required this.currentBalance,
  });

  @override
  State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  
  String _selectedProvider = 'wave';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  final List<Map<String, String>> _providers = [
    {'id': 'wave', 'name': 'Wave'},
    {'id': 'orange_money', 'name': 'Orange Money'},
    {'id': 'mtn', 'name': 'MTN Mobile Money'},
    {'id': 'moov', 'name': 'Moov Money'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _initiateWithdrawal() async {
    final amountText = _amountController.text.replaceAll(' ', '');
    final amount = double.tryParse(amountText) ?? 0;

    if (amount < 100) {
      setState(() => _errorMessage = 'Le montant minimum est de 100 FCFA');
      return;
    }
    if (amount > widget.currentBalance) {
      setState(() => _errorMessage = 'Solde insuffisant');
      return;
    }
    if (_accountController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir un compte de destination');
      return;
    }

    final authenticated = await BiometricService().authenticate(
      'Veuillez vous authentifier pour confirmer ce retrait',
    );

    if (!authenticated) {
      setState(() => _errorMessage = 'Authentification annulée ou échouée');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await _apiClient.dio.post('/withdrawals/initiate', data: {
        'amount': amount,
        'provider': _selectedProvider,
        'destination_account': _accountController.text,
      });

      setState(() {
        _successMessage = response.data['message'] ?? 'Retrait effectué avec succès !';
        _amountController.clear();
        _accountController.clear();
      });
      
      // Retour après 2 secondes
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, true); // true = refresh dashboard
        }
      });
    } catch (e) {
      String msg = 'Erreur lors du retrait. Vérifiez votre connexion.';
      if (e is DioException) {
        if (e.response?.data is Map) {
          msg = e.response?.data['message'] ?? e.response?.data['error'] ?? msg;
        } else if (e.response?.statusCode == 403) {
          msg = 'Retrait non autorisé : Votre dossier KYB marchand doit être certifié par la conformité.';
        }
      }
      setState(() {
        _errorMessage = msg;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF161A22)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Retrait vers Gateway',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF161A22)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFF161A22),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Solde disponible',
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${widget.currentBalance.toInt()} FCFA',
                    style: AppTextStyles.displayMedium.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Montant à retirer',
              style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            VireloTextField(
              controller: _amountController,
              hint: '0 FCFA',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Méthode de retrait',
              style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildMethodTile(
              id: 'wave',
              title: 'Wave',
              subtitle: 'Retrait instantané',
              logoPath: 'assets/gateway/wave.svg',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildMethodTile(
              id: 'orange_money',
              title: 'Orange Money',
              subtitle: 'Retrait instantané',
              logoPath: 'assets/gateway/orange.svg',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildMethodTile(
              id: 'mtn',
              title: 'MTN Mobile Money',
              subtitle: 'Retrait instantané',
              logoPath: 'assets/gateway/mtn.svg',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildMethodTile(
              id: 'moov',
              title: 'Moov Money',
              subtitle: 'Retrait instantané',
              logoPath: 'assets/gateway/moov.png',
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Numéro de compte / Téléphone',
              style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Color(0xFF161A22)),
              decoration: InputDecoration(
                hintText: 'Saisissez le compte de destination',
                hintStyle: const TextStyle(color: Color(0xFF8B93A8)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.red),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle2, color: Colors.green),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(_successMessage!, style: const TextStyle(color: Colors.green))),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            SizedBox(
              width: double.infinity,
              child: VireloPrimaryButton(
                onPressed: _isLoading || _successMessage != null ? null : _initiateWithdrawal,
                label: _isLoading ? 'Traitement...' : 'Confirmer le retrait',
                icon: _isLoading ? null : LucideIcons.arrowRight,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMethodTile({required String id, required String title, required String subtitle, String? logoPath, IconData? icon}) {
    final isSelected = _selectedProvider == id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProvider = id;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF161A22) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              child: logoPath != null 
                  ? (logoPath.endsWith('.svg')
                      ? SvgPicture.asset(logoPath, fit: BoxFit.contain)
                      : Image.asset(logoPath, fit: BoxFit.contain))
                  : Icon(icon, color: const Color(0xFF161A22)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: const Color(0xFF1A1C1D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: const Color(0xFF8B93A8),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.checkCircle2, color: Color(0xFF161A22))
            else
              const SizedBox(width: 24, height: 24),
          ],
        ),
      ),
    );
  }
}
