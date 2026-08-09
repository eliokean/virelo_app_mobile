import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:virelo_design_system/virelo_design_system.dart';
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
  String _documentType = 'CNI';

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: type == 'selfie' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70, // Compresser pour Ã©viter les gros fichiers
    );

    if (image != null) {
      setState(() {
        if (type == 'front') _frontImage = File(image.path);
        if (type == 'back') _backImage = File(image.path);
        if (type == 'selfie') _selfieImage = File(image.path);
      });
    }
  }

  Future<void> _submitKyc() async {
    if (_frontImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez fournir le recto et un selfie.'),
          backgroundColor: AppColors.error,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents envoyÃ©s. En attente de validation.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Retour
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildImageSelector(String title, String type, File? file) {
    return GestureDetector(
      onTap: () => _pickImage(type),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder, width: 1),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(file, fit: BoxFit.cover, width: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == 'selfie' ? LucideIcons.camera : LucideIcons.image,
                    color: AppColors.accent,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: AppTextStyles.bodyMedium),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vérification KYC', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Afin d\'augmenter votre plafond hors-ligne, nous devons vérifier votre identité.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),

            DropdownButtonFormField<String>(
              value: _documentType,
              decoration: const InputDecoration(
                labelText: 'Type de document',
                border: OutlineInputBorder(),
              ),
              items: ['CNI', 'PASSPORT', 'PERMIS']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (val) => setState(() => _documentType = val!),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            Text('1. Photo du Recto', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            _buildImageSelector('Ajouter le recto', 'front', _frontImage),

            const SizedBox(height: AppSpacing.xl),
            Text('2. Photo du Verso (Optionnel)', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            _buildImageSelector('Ajouter le verso', 'back', _backImage),

            const SizedBox(height: AppSpacing.xl),
            Text('3. Prendre un selfie', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            _buildImageSelector('Prendre photo', 'selfie', _selfieImage),

            const SizedBox(height: AppSpacing.xxl),
            VireloPrimaryButton(
              label: 'Soumettre',
              isLoading: _isLoading,
              onPressed: _submitKyc,
            ),
          ],
        ),
      ),
    );
  }
}
