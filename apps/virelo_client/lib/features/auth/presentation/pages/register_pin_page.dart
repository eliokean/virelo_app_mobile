import 'package:flutter/material.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_design_system/widgets/virelo_pin_pad.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:virelo_core/services/auth_service.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';

class RegisterPinPage extends StatefulWidget {
  final String name;
  final String phone;
  final String email;

  const RegisterPinPage({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
  });

  @override
  State<RegisterPinPage> createState() => _RegisterPinPageState();
}

class _RegisterPinPageState extends State<RegisterPinPage> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isLoading = false;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(ApiClient());
  }

  void _onDigitTap(String digit) {
    if (_isLoading) return;

    setState(() {
      if (!_isConfirming) {
        if (_pin.length < 4) _pin += digit;
        if (_pin.length == 4) {
          _isConfirming = true;
        }
      } else {
        if (_confirmPin.length < 4) _confirmPin += digit;
        if (_confirmPin.length == 4) {
          _validateAndRegister();
        }
      }
    });
  }

  void _onDeleteTap() {
    if (_isLoading) return;

    setState(() {
      if (!_isConfirming && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      } else if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirming = false;
          _pin = '';
        }
      }
    });
  }

  Future<void> _validateAndRegister() async {
    if (_pin != _confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les codes PIN ne correspondent pas. Réessayez.'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() {
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Inscription sur le serveur avec le PIN comme "mot de passe"
      await _authService.register(widget.name, widget.phone, widget.email, _pin);
      
      // 2. Sauvegarde du PIN en local pour les prochaines ouvertures
      await _authService.saveLocalPin(_pin);
      
      // 3. Proposer la biométrie
      if (await _authService.isBiometricsAvailable()) {
        final success = await _authService.authenticateWithBiometrics();
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biométrie activée avec succès !')),
          );
        }
      }

      if (mounted) {
        // Redirection vers le Wallet, en supprimant tout l'historique
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WalletPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
        setState(() {
          _pin = '';
          _confirmPin = '';
          _isConfirming = false;
        });
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
            const Spacer(flex: 1),
            Text(
              _isConfirming ? 'Confirmez votre PIN' : 'Créez un code PIN',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Il remplacera votre mot de passe',
              style: AppTextStyles.bodyMedium,
            ),
            const Spacer(flex: 2),
            
            if (_isLoading)
              const CircularProgressIndicator(color: AppColors.accent)
            else
              VireloPinDots(
                pinLength: _isConfirming ? _confirmPin.length : _pin.length,
              ),
            
            const Spacer(flex: 3),
            VireloPinPad(
              onDigitTap: _onDigitTap,
              onDeleteTap: _onDeleteTap,
              showBiometric: false,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
