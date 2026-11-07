/// ويدجت اختيار وتعديل الصورة الشخصية
/// 
/// مكون موحد يتيح عرض واختيار وتعديل الصورة الشخصية
/// مع نافذة سفلية للاختيار من الكاميرا أو المعرض
library;

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../services/storage_service.dart';

/// مكون اختيار ورفع وتعديل الصورة الشخصية
class ProfileAvatarPicker extends StatelessWidget {
  /// ملف الصورة المختار محلياً
  final File? selectedImage;

  /// رابط الصورة السحابية إن وجد
  final String? imageUrl;

  /// دالة استدعاء عند اختيار صورة جديدة
  final ValueChanged<File?>? onImageSelected;

  /// هل الصورة قابلة للتعديل
  final bool isEditable;

  /// هل الحقل إجباري (يظهر نجمة إجبارية)
  final bool isRequired;

  /// تسمية الحقل أسفل الصورة
  final String? label;

  /// نصف قطر الصورة
  final double radius;

  /// هل يتم عرض شارة الكاميرا/التحقق
  final bool showBadge;

  /// خدمة التخزين لاختيار الصور
  final StorageService _storageService;

  ProfileAvatarPicker({
    super.key,
    this.selectedImage,
    this.imageUrl,
    this.onImageSelected,
    this.isEditable = true,
    this.isRequired = false,
    this.label,
    this.radius = 55.0,
    this.showBadge = true,
    StorageService? storageService,
  }) : _storageService = storageService ?? StorageService.instance;

  /// فتح النافذة السفلية لاختيار الصورة من الكاميرا أو المعرض
  Future<void> _showImagePickerModal(BuildContext context) async {
    if (!isEditable || onImageSelected == null) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مؤشر السحب
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 22),
                ),
                title: const Text(
                  AppStrings.chooseFromGallery,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final image = await _storageService.pickImageFromGallery();
                  if (image != null) {
                    onImageSelected!(image);
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22),
                ),
                title: const Text(
                  AppStrings.takePhoto,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final image = await _storageService.pickImageFromCamera();
                  if (image != null) {
                    onImageSelected!(image);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double diameter = radius * 2;
    final bool hasImage = selectedImage != null || (imageUrl != null && imageUrl!.isNotEmpty);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: GestureDetector(
            onTap: isEditable ? () => _showImagePickerModal(context) : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasImage ? AppColors.primary : AppColors.border,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildAvatarContent(diameter),
                  ),
                ),
                if (isEditable && showBadge)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        selectedImage != null ? Icons.check_rounded : Icons.camera_alt_rounded,
                        size: 15,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 12),
          Text(
            '$label${isRequired ? ' *' : ''}',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: hasImage ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildAvatarContent(double diameter) {
    if (selectedImage != null) {
      return Image.file(
        selectedImage!,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.person_rounded,
          size: diameter * 0.52,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Icon(
      Icons.person_rounded,
      size: diameter * 0.52,
      color: AppColors.primary,
    );
  }
}
