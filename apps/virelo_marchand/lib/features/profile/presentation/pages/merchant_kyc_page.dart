import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:dio/dio.dart';

class MerchantKycPage extends StatefulWidget {
  const MerchantKycPage({super.key});

  @override
  State<MerchantKycPage> createState() => _MerchantKycPageState();
}

class _MerchantKycPageState extends State<MerchantKycPage> {
  final ImagePicker _picker = ImagePicker();
  
  File? _frontImage;
  File? _backImage;
  File? _selfieImage;
  
  bool _isFetchingStatus = true;
  bool _isLoading = false;
  String _kycStatus = 'unverified'; // 'unverified', 'pending', 'approved', 'rejected'
  String? _adminNotes;
  String _documentType = 'RCCM'; // 'RCCM', 'IFU', 'CNI_GERANT'

  @override
  void initState() {
    super.initState();
    _fetchKycStatus();
  }

  Future<void> _fetchKycStatus() async {
    try {
      final response = await ApiClient().dio.get('/kyb/status');
      if (mounted) {
        setState(() {
          _kycStatus = response.data['status'] ?? 'unverified';
          _adminNotes = response.data['admin_notes'];
          _isFetchingStatus = false;
        });
      }
    } catch (_) {
      try {
        final fallback = await ApiClient().dio.get('/kyc/status');
        if (mounted) {
          setState(() {
            _kycStatus = fallback.data['status'] ?? 'unverified';
            _adminNotes = fallback.data['admin_notes'];
            _isFetchingStatus = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isFetchingStatus = false;
          });
        }
      }
    }
  }

  Future<void> _pickImage(String type, {ImageSource source = ImageSource.gallery}) async {
    final XFile? image = await _picker.pickImage(
      source: type == 'selfie' ? ImageSource.camera : source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        if (type == 'front') _frontImage = File(image.path);
        if (type == 'back') _backImage = File(image.path);
        if (type == 'selfie') _selfieImage = File(image.path);
      });
    }
  }

  void _showImageSourceDialog(String type) {
    if (type == 'selfie') {
      _pickImage(type, source: ImageSource.camera);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Sélectionner une pièce',
                style: AppTextStyles.headlineMedium.copyWith(color: const Color(0xFF161A22)),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.camera, color: Color(0xFF161A22)),
                ),
                title: Text('Prendre une photo du document', style: AppTextStyles.labelLarge.copyWith(color: const Color(0xFF161A22))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(type, source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.image, color: Color(0xFF161A22)),
                ),
                title: Text('Choisir depuis la galerie / Fichiers', style: AppTextStyles.labelLarge.copyWith(color: const Color(0xFF161A22))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(type, source: ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitKyc() async {
    if (_frontImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(LucideIcons.alertCircle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Veuillez fournir le document de l\'entreprise et votre photo gérant.')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final frontFile = await MultipartFile.fromFile(_frontImage!.path, filename: 'merchant_front.jpg');
      final selfieFile = await MultipartFile.fromFile(_selfieImage!.path, filename: 'merchant_selfie.jpg');
      MultipartFile? backFile;
      if (_backImage != null) {
        backFile = await MultipartFile.fromFile(_backImage!.path, filename: 'merchant_back.jpg');
      }

      final formData = FormData.fromMap({
        'document_type': _documentType,
        'front_image': frontFile,
        'storefront_photo': frontFile,
        'selfie_image': selfieFile,
        'manager_id_card': selfieFile,
        if (backFile != null) 'back_image': backFile,
        if (backFile != null) 'rccm_document': backFile,
      });

      final response = await ApiClient().dio.post(
        '/kyb/upload',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            _kycStatus = 'pending';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(LucideIcons.checkCircle2, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(child: Text('Dossier KYB Marchand soumis avec succès !')),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      String errorMsg = "Erreur lors de l'envoi du dossier KYB.";
      if (e is DioException) {
        debugPrint('❌ [KYB Upload Error] status=${e.response?.statusCode}, data=${e.response?.data}');
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data['message'] != null) {
            errorMsg = data['message'].toString();
          } else if (data['errors'] != null && data['errors'] is Map) {
            final errors = data['errors'] as Map;
            final firstError = errors.values.first;
            errorMsg = firstError is List ? firstError.first.toString() : firstError.toString();
          }
        } else if (e.response?.statusCode == 413) {
          errorMsg = "Les images sélectionnées sont trop volumineuses.";
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1C1D),
        body: Column(
          children: [
            // Header Sombre
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                      ),
                    ),
                    Text(
                      'KYC & Fiche Entreprise',
                      style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // Conteneur Principal Incurvé
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                  child: _isFetchingStatus
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.screenH),
                          child: _buildBodyContent(),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_kycStatus == 'approved') {
      return _buildApprovedView();
    } else if (_kycStatus == 'pending') {
      return _buildPendingView();
    } else if (_kycStatus == 'rejected') {
      return _buildRejectedView();
    } else {
      return _buildUploadForm();
    }
  }

  Widget _buildApprovedView() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2E7D32), width: 2),
          ),
          child: const Icon(LucideIcons.shieldCheck, size: 48, color: Color(0xFF2E7D32)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Établissement Certifié',
          style: AppTextStyles.headlineMedium.copyWith(
            color: const Color(0xFF161A22),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Votre compte marchand et vos pièces d\'immatriculation ont été validés avec succès par l\'équipe conformité.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF6B7280)),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E4E8)),
          ),
          child: Column(
            children: [
              _buildFeatureRow(LucideIcons.zap, 'Encaissements illimités', 'Plafonds de facturation débloqués'),
              const Divider(height: 24),
              _buildFeatureRow(LucideIcons.banknote, 'Virements & Retraits prioritaires', 'Transferts instantanés vers Mobile Money'),
              const Divider(height: 24),
              _buildFeatureRow(LucideIcons.badgeCheck, 'Badge Marchand Officiel', 'Visibilité et confiance client maximales'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingView() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF59E0B), width: 2),
          ),
          child: const Icon(LucideIcons.clock, size: 48, color: Color(0xFFF59E0B)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Dossier en cours d\'examen',
          style: AppTextStyles.headlineMedium.copyWith(
            color: const Color(0xFF161A22),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Vos documents d\'entreprise sont en cours de vérification par nos agents de conformité bancaire (délai : 24h à 48h ouvrées).',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF6B7280)),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E4E8)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.info, color: Color(0xFFF59E0B), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Traitement sécurisé',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: const Color(0xFF161A22),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vous recevrez une notification dès que la revue sera terminée.',
                      style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedView() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.error, width: 2),
          ),
          child: const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.error),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Dossier Non Validé',
          style: AppTextStyles.headlineMedium.copyWith(
            color: const Color(0xFF161A22),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Votre soumission n\'a pas pu être validée pour le motif suivant :',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF6B7280)),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Text(
            _adminNotes ?? 'Document illisible ou non conforme aux critères d\'immatriculation.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _kycStatus = 'unverified';
                _frontImage = null;
                _backImage = null;
                _selfieImage = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: const Color(0xFF161A22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Soumettre de nouveaux documents', style: AppTextStyles.headlineMedium.copyWith(color: const Color(0xFF161A22), fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                const Icon(LucideIcons.arrowRight, color: Color(0xFF161A22)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Immatriculation de l\'établissement',
          style: AppTextStyles.headlineMedium.copyWith(
            color: const Color(0xFF161A22),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fournissez les pièces officielles pour certifier votre compte marchand et débloquer les plafonds.',
          style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF6B7280)),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Sélecteur de type de document
        Text(
          'Type de justificatif',
          style: AppTextStyles.labelMedium.copyWith(
            color: const Color(0xFF161A22),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTypePill('RCCM (Registre Commerce)', 'RCCM'),
              _buildTypePill('Attestation IFU / DGI', 'IFU'),
              _buildTypePill('Pièce d\'identité du Gérant', 'CNI_GERANT'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Zone 1: Document Principal
        _buildUploadCard(
          title: 'Document Officiel (Recto / Page 1)',
          subtitle: 'Photo lisible de l\'immatriculation ou de la pièce',
          file: _frontImage,
          type: 'front',
          icon: LucideIcons.fileText,
        ),
        const SizedBox(height: AppSpacing.md),

        // Zone 2: Document Verso (Optionnel)
        _buildUploadCard(
          title: 'Document (Verso / Page 2 - Optionnel)',
          subtitle: 'Si le document comporte une seconde page',
          file: _backImage,
          type: 'back',
          icon: LucideIcons.files,
        ),
        const SizedBox(height: AppSpacing.md),

        // Zone 3: Selfie / Habilitation Gérant
        _buildUploadCard(
          title: 'Photo d\'habilitation du Gérant',
          subtitle: 'Selfie clair du représentant légal pour vérification faciale',
          file: _selfieImage,
          type: 'selfie',
          icon: LucideIcons.userCheck,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Bouton Soumettre
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitKyc,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              disabledBackgroundColor: AppColors.surfaceBorder,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Color(0xFF161A22), strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Soumettre le dossier KYC',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: const Color(0xFF161A22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(LucideIcons.arrowRight, color: Color(0xFF161A22)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildTypePill(String label, String value) {
    final isSelected = _documentType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF161A22) : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.accent,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.accent : const Color(0xFFE2E4E8),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (selected) {
          if (selected) {
            setState(() => _documentType = value);
          }
        },
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required File? file,
    required String type,
    required IconData icon,
  }) {
    final hasFile = file != null;

    return InkWell(
      onTap: () => _showImageSourceDialog(type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasFile ? const Color(0xFF00E5A0) : const Color(0xFFE2E4E8),
            width: hasFile ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: hasFile 
                    ? const Color(0xFF00E5A0).withValues(alpha: 0.15)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: hasFile
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(file, fit: BoxFit.cover),
                    )
                  : Icon(icon, color: const Color(0xFF6B7280), size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: const Color(0xFF161A22),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? 'Document importé avec succès' : subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: hasFile ? const Color(0xFF00E5A0) : const Color(0xFF6B7280),
                      fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasFile ? const Color(0xFF00E5A0) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile ? LucideIcons.check : LucideIcons.upload,
                color: hasFile ? const Color(0xFF161A22) : const Color(0xFF6B7280),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: const Color(0xFF161A22),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
