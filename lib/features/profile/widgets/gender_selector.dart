/// ويدجت اختيار الجنس الموحد
/// 
/// يتيح اختيار الجنس (ذكر / أنثى) بنمط قائمة منسدلة أو شرائح اختيار
/// متوافق مع معايير التصميم المونوكروم والخط العربي Cairo
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

/// نوع عرض محدد الجنس
enum GenderSelectorType {
  /// قائمة منسدلة داخل حقل إدخال
  dropdown,

  /// أزرار اختيار سريعة (Chips)
  chips,
}

/// مكون اختيار الجنس
class GenderSelector extends StatelessWidget {
  /// الجنس المحدد حالياً ('male' أو 'female' أو null)
  final String? selectedGender;

  /// دالة الاستدعاء عند التغيير
  final ValueChanged<String?> onChanged;

  /// هل الحقل إجباري
  final bool isRequired;

  /// نص التسمية
  final String? labelText;

  /// دالة التحقق
  final String? Function(String?)? validator;

  /// نوع العرض (dropdown أو chips)
  final GenderSelectorType type;

  /// لون الخلفية
  final Color? fillColor;

  /// هل الحقل مفعل
  final bool enabled;

  const GenderSelector({
    super.key,
    required this.selectedGender,
    required this.onChanged,
    this.isRequired = false,
    this.labelText,
    this.validator,
    this.type = GenderSelectorType.dropdown,
    this.fillColor,
    this.enabled = true,
  });

  /// منشئ مخصص لنمط القائمة المنسدلة
  const GenderSelector.dropdown({
    super.key,
    required this.selectedGender,
    required this.onChanged,
    this.isRequired = false,
    this.labelText,
    this.validator,
    this.fillColor,
    this.enabled = true,
  }) : type = GenderSelectorType.dropdown;

  /// منشئ مخصص لنمط شرائح الاختيار (Chips)
  const GenderSelector.chips({
    super.key,
    required this.selectedGender,
    required this.onChanged,
    this.isRequired = false,
    this.labelText,
    this.validator,
    this.fillColor,
    this.enabled = true,
  }) : type = GenderSelectorType.chips;

  @override
  Widget build(BuildContext context) {
    if (type == GenderSelectorType.chips) {
      return _buildChipsSelector(context);
    }
    return _buildDropdownSelector(context);
  }

  Widget _buildDropdownSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveLabel = (labelText ?? l10n.genderColon.replaceAll(':', '')) + (isRequired ? ' *' : '');

    return DropdownButtonFormField<String>(
      initialValue: selectedGender,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: effectiveLabel,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        prefixIcon: const Icon(Icons.wc_rounded, color: AppColors.primary),
        filled: true,
        fillColor: fillColor ?? AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        DropdownMenuItem(
          value: 'male',
          child: Text(l10n.genderMale, style: const TextStyle(fontFamily: 'Cairo')),
        ),
        DropdownMenuItem(
          value: 'female',
          child: Text(l10n.genderFemale, style: const TextStyle(fontFamily: 'Cairo')),
        ),
      ],
      onChanged: enabled ? onChanged : null,
      validator: validator ??
          (isRequired
              ? (val) {
                  if (val == null || val.isEmpty) {
                    return l10n.selectGenderError;
                  }
                  return null;
                }
              : null),
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      dropdownColor: AppColors.surface,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
    );
  }

  Widget _buildChipsSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        const Icon(Icons.wc_rounded, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          labelText ?? l10n.genderColon,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        ChoiceChip(
          label: Text(l10n.genderMale, style: const TextStyle(fontFamily: 'Cairo')),
          selected: selectedGender == 'male',
          selectedColor: AppColors.primaryLight.withValues(alpha: 0.15),
          backgroundColor: AppColors.surfaceVariant,
          onSelected: enabled
              ? (selected) {
                  onChanged(selected ? 'male' : null);
                }
              : null,
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text(l10n.genderFemale, style: const TextStyle(fontFamily: 'Cairo')),
          selected: selectedGender == 'female',
          selectedColor: AppColors.primaryLight.withValues(alpha: 0.15),
          backgroundColor: AppColors.surfaceVariant,
          onSelected: enabled
              ? (selected) {
                  onChanged(selected ? 'female' : null);
                }
              : null,
        ),
      ],
    );
  }
}
