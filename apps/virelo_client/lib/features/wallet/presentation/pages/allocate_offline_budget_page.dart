import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:virelo_design_system/virelo_design_system.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import '../../../kyc/presentation/pages/kyc_upload_page.dart';

class AllocateOfflineBudgetPage extends StatefulWidget {
  const AllocateOfflineBudgetPage({super.key});

  @override
  State<AllocateOfflineBudgetPage> createState() => _AllocateOfflineBudgetPageState();
}

class _AllocateOfflineBudgetPageState extends State<AllocateOfflineBudgetPage> {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _amount = "0";
  bool _isAllocating = false;

  String get _formattedAmount {
    if (_amount == "0") return "0";
    final result = StringBuffer();
    for (int i = 0; i < _amount.length; i++) {
      if (i > 0 && (_amount.length - i) % 3 == 0) result.write(' ');
      result.write(_amount[i]);
    }
    return result.toString();
  }

  void _onNumpadTap(String value) {
    setState(() {
      if (_amount == "0") {
        if (value != "0" && value != "00") {
          _amount = value;
        }
      } else if (_amount.length + value.length <= 8) {
        _amount += value;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = "0";
      }
    });
  }

  Future<void> _allocateBudget() async {
    if (_amount == "0" || _amount.isEmpty) return;
    
    setState(() => _isAllocating = true);
    
    try {
      final amountDouble = double.parse(_amount.replaceAll(' ', '').replaceAll(',', '.'));
      final response = await _apiClient.dio.post('/offline/allocate', data: {
        'amount': amountDouble,
      });
      
      final data = response.data;
      await _storage.write(key: 'offline_token', value: data['offline_token'].toString());
      await _storage.write(key: 'escrow_secret', value: data['escrow_secret']);
      
      final offlineStorage = OfflineStorageService(AuthService(_apiClient));
      await offlineStorage.saveOfflineBudget(amountDouble);
      await offlineStorage.clearOfflineTransactions();
      
      if (mounted) {
        setState(() => _isAllocating = false);
        showDialog(
          context: context,
          builder: (context) => VireloAlertDialog(
            alertType: VireloAlertType.success,
            title: 'Allocation Réussie !',
            message: 'Votre budget de $_amount FCFA a été sécurisé en mode hors-ligne avec succès.',
            primaryButtonLabel: 'Super',
            onPrimaryPressed: () => Navigator.pop(context, true),
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _isAllocating = false);
        final responseData = e.response?.data;
        final errorMsg = responseData is Map ? responseData['message']?.toString() ?? 'Erreur lors de l\'allocation' : 'Erreur lors de l\'allocation';
        
        if (errorMsg.contains('KYC') || errorMsg.contains('0%') || errorMsg.contains('vérification')) {
          VireloAlertDialog.showKycRequired(
            context,
            message: errorMsg,
            onCompleteKyc: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KycUploadPage()),
              );
            },
          );
        } else if (errorMsg.contains('50%') || errorMsg.contains('limite') || errorMsg.contains('insuffisant')) {
          VireloAlertDialog.showLimitExceeded(
            context,
            message: errorMsg,
            onUpgradeKyc: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KycUploadPage()),
              );
            },
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => VireloAlertDialog(
              alertType: VireloAlertType.error,
              title: 'Erreur d\'allocation',
              message: errorMsg,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAllocating = false);
        showDialog(
          context: context,
          builder: (context) => const VireloAlertDialog(
            alertType: VireloAlertType.error,
            title: 'Erreur Inattendue',
            message: 'Une erreur est survenue. Veuillez réessayer ultérieurement.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF161A22)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Budget Hors Ligne',
          style: AppTextStyles.headlineMedium.copyWith(color: const Color(0xFF161A22)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: Text(
                'Combien voulez-vous sécuriser pour vos paiements hors ligne ?',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            Text(
              '$_formattedAmount FCFA',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF161A22),
              ),
            ),
            const Spacer(),
            _buildNumpad(),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: (_amount != "0" && !_isAllocating) ? _allocateBudget : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor: AppColors.surfaceBorder,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isAllocating
                      ? const CircularProgressIndicator(color: Color(0xFF161A22))
                      : Text(
                          'Allouer le Budget',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: const Color(0xFF161A22),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (int i = 1; i <= 9; i++) _buildNumpadButton(i.toString()),
        _buildNumpadButton('00'),
        _buildNumpadButton('0'),
        _buildNumpadButton('del', isIcon: true),
      ],
    );
  }

  Widget _buildNumpadButton(String value, {bool isIcon = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isIcon) {
            _onBackspace();
          } else {
            _onNumpadTap(value);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: isIcon
              ? const Icon(LucideIcons.delete, size: 28, color: Color(0xFF1A1C1D))
              : Text(
                  value,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: const Color(0xFF1A1C1D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
