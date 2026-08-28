import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/theme/app_colors.dart';
import 'package:virelo_design_system/theme/app_text_styles.dart';
import 'package:virelo_design_system/constants/app_spacing.dart';
import 'package:virelo_core/network/api_client.dart';
import 'package:dio/dio.dart';

class KycUploadPage extends StatefulWidget {
  const KycUploadPage({super.key});

  @override
  State<KycUploadPage> createState() => _KycUploadPageState();
}

class _KycUploadPageState extends State<KycUploadPage> {
  final ImagePicker _picker = ImagePicker();
  
  File? _frontImage;
  File? _backImage;
  File? _selfieImage;
  
  bool _isLoading = false;
  String _documentType = 'CNI'; // 'CNI', 'PASSPORT', 'PERMIS'

  Future<void> _pickImage(String type, {ImageSource source = ImageSource.gallery}) async {
    final XFile? image = await _picker.pickImage(
      source: type == 'selfie' ? ImageSource.camera : source,
      imageQuality: 75,
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
                'Sélectionner une image',
                style: AppTextStyles.headlineMedium.copyWith(color: const Color(0xFF161A22)),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.camera, color: Color(0xFF161A22)),
                ),
                title: Text('Prendre une photo', style: AppTextStyles.labelLarge.copyWith(color: const Color(0xFF161A22))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(type, source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.image, color: Color(0xFF161A22)),
                ),
                title: Text('Choisir depuis la galerie', style: AppTextStyles.labelLarge.copyWith(color: const Color(0xFF161A22))),
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
              Expanded(child: Text('Veuillez fournir le recto du document et votre selfie.')),
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
      final formData = FormData.fromMap({
        'document_type': _documentType,
        'front_image': await MultipartFile.fromFile(_frontImage!.path),
        'selfie_image': await MultipartFile.fromFile(_selfieImage!.path),
      });

      if (_backImage != null) {
        formData.files.add(
          MapEntry('back_image', await MultipartFile.fromFile(_backImage!.path)),
        );
      }

      await ApiClient().dio.post('/auth/kyc/upload', data: formData);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.checkCircle, color: Color(0xFF161A22), size: 48),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Documents Envoyés !',
                  style: AppTextStyles.headlineMedium.copyWith(color: const Color(0xFF161A22), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Vos documents sont en cours de vérification par notre équipe. Vous recevrez une notification dès validation.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Back to settings
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Compris',
                      style: AppTextStyles.labelLarge.copyWith(color: const Color(0xFF161A22), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi : $e'),
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
        backgroundColor: const Color(0xFF1A1C1D), // Dark header bar
        body: Column(
          children: [
            // Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                      ),
                    ),
                    Text(
                      'Vérification KYC',
                      style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 48), // Spacer
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9FA), // Clean bright surface
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.xl, AppSpacing.screenH, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner info KYC
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(LucideIcons.shieldCheck, color: Color(0xFF161A22), size: 28),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Débloquez vos plafonds',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: const Color(0xFF161A22),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Validez votre identité pour sécuriser jusqu\'à 500 000 FCFA en budget hors-ligne.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Section : Type de document
                      Text(
                        'Type de pièce d\'identité',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: const Color(0xFF161A22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildDocumentTypeSelector(),

                      const SizedBox(height: AppSpacing.xxl),

                      // Section : Documents à téléverser
                      Text(
                        'Photos des documents',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: const Color(0xFF161A22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 1. Recto
                      _buildUploadCard(
                        title: 'Photo du Recto',
                        subtitle: 'Face avant lisible et nette de la pièce',
                        icon: LucideIcons.creditCard,
                        type: 'front',
                        file: _frontImage,
                        isRequired: true,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 2. Verso
                      if (_documentType != 'PASSPORT') ...[
                        _buildUploadCard(
                          title: 'Photo du Verso',
                          subtitle: 'Face arrière de la pièce (Optionnel)',
                          icon: LucideIcons.creditCard,
                          type: 'back',
                          file: _backImage,
                          isRequired: false,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // 3. Selfie
                      _buildUploadCard(
                        title: 'Selfie en direct',
                        subtitle: 'Photo claire de votre visage bien éclairé',
                        icon: LucideIcons.camera,
                        type: 'selfie',
                        file: _selfieImage,
                        isRequired: true,
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitKyc,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF161A22)),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Soumettre mes documents',
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTypeSelector() {
    final types = [
      {'id': 'CNI', 'label': 'CNI', 'icon': LucideIcons.creditCard},
      {'id': 'PASSPORT', 'label': 'Passeport', 'icon': LucideIcons.bookOpen},
      {'id': 'PERMIS', 'label': 'Permis', 'icon': LucideIcons.car},
    ];

    return Row(
      children: types.map((t) {
        final isSelected = _documentType == t['id'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _documentType = t['id'] as String),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF161A22) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF161A22) : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      color: isSelected ? AppColors.accent : Colors.grey[600],
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t['label'] as String,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? Colors.white : const Color(0xFF161A22),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String type,
    required File? file,
    required bool isRequired,
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
            color: hasFile ? AppColors.accent : Colors.grey[200]!,
            width: hasFile ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Preview or Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: hasFile ? Colors.transparent : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[300]!, width: 0.5),
              ),
              child: hasFile
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(file, fit: BoxFit.cover),
                    )
                  : Icon(icon, color: Colors.grey[700], size: 26),
            ),
            const SizedBox(width: AppSpacing.md),

            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: const Color(0xFF161A22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isRequired)
                        Text(
                          ' *',
                          style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Action / Status Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasFile ? AppColors.accent.withOpacity(0.2) : const Color(0xFFF1F3F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile ? LucideIcons.check : LucideIcons.plus,
                color: hasFile ? const Color(0xFF161A22) : Colors.grey[700],
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
