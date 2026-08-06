import 'package:flutter/material.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_pin_pad.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';
import 'device_verification_page.dart';

class LoginNetworkPinPage extends StatefulWidget {
  final String phone;

  const LoginNetworkPinPage({super.key, required this.phone});

  @override
  State<LoginNetworkPinPage> createState() => _LoginNetworkPinPageState();
}

class _LoginNetworkPinPageState extends State<LoginNetworkPinPage> {
  String _pin = '';
  bool _isLoading = false;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(ApiClient());
  }

  void _onDigitTap(String digit) {
    if (_isLoading) return;
    
    if (_pin.length < 4) {
      setState(() => _pin += digit);
      if (_pin.length == 4) {
        _verifyNetworkPin();
      }
    }
  }

  void _onDeleteTap() {
    if (_isLoading) return;
    
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _verifyNetworkPin() async {
    setState(() => _isLoading = true);

    try {
      // Le PIN fait office de mot de passe pour le backend
      final response = await _authService.login(widget.phone, _pin);
      
      // Sauvegarde du PIN en local
      await _authService.saveLocalPin(_pin);
      
      if (mounted) {
        if (response['requires_device_verification'] == true) {
          // Si le backend a détecté un nouvel appareil et a généré un OTP
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DeviceVerificationPage(phone: widget.phone),
            ),
          );
        } else {
          // Sinon, on va au Wallet normal
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WalletPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('==== LOGIN ERROR: $e ====');
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
              'Saisissez votre PIN pour vous connecter',
              style: AppTextStyles.bodyMedium,
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
              showBiometric: false, // Pas de biométrie pour la première connexion réseau
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
