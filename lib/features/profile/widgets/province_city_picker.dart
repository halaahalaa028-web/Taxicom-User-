/// ويدجت اختيار المحافظة والمدينة الموحد
/// 
/// يتيح اختيار المحافظة بناءً على دولة المستخدم (مصر، العراق، سوريا، إيران)
/// مع تصميم مونوكروم متناسق ودعم التحقق من الحقول
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_provinces.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/country_service.dart';

/// مكون اختيار المحافظة
class ProvinceCityPicker extends StatelessWidget {
  /// المحافظة المحددة حالياً
  final String? value;

  /// كود الدولة (EG, IQ, SY, IR)
  final String? countryCode;

  /// دالة الاستدعاء عند تغيير المحافظة
  final ValueChanged<String?> onChanged;

  /// دالة التحقق
  final String? Function(String?)? validator;

  /// نص التسمية (Label)
  final String? labelText;

  /// هل الحقل إجباري
  final bool isRequired;

  /// لون الخلفية
  final Color? fillColor;

  /// هل الحقل مفعل
  final bool enabled;

  const ProvinceCityPicker({
    super.key,
    required this.value,
    this.countryCode,
    required this.onChanged,
    this.validator,
    this.labelText,
    this.isRequired = false,
    this.fillColor,
    this.enabled = true,
  });

  /// استرجاع اسم المحافظة بالعربية بناءً على المفتاح والدولة
  static String getProvinceName(String? key, [String? countryCode]) {
    return AppProvinces.getProvinceName(key, countryCode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveCountry = countryCode ?? CountryService.instance.selectedCountry.code;
    final provinces = AppProvinces.getProvincesForCountry(effectiveCountry);

    final effectiveLabel = (labelText ?? l10n.provinceField) + (isRequired ? ' *' : '');
    
    // التأكد من أن القيمة المحددة موجودة ضمن قائمة المحافظات للدولة الحالية
    final isValidValue = value != null && provinces.any((p) => p.id == value!.toLowerCase());
    final effectiveValue = isValidValue ? value!.toLowerCase() : null;

    return DropdownButtonFormField<String>(
      initialValue: effectiveValue,
      isExpanded: true,
      menuMaxHeight: 350,
      decoration: InputDecoration(
        labelText: effectiveLabel,
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
        prefixIcon: const Icon(
          Icons.location_city_rounded,
          color: AppColors.primary,
          size: 22,
        ),
        filled: true,
        fillColor: fillColor ??
            (enabled
                ? AppColors.surfaceVariant.withValues(alpha: 0.35)
                : AppColors.surfaceVariant.withValues(alpha: 0.6)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
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
      items: provinces.map((item) {
        return DropdownMenuItem<String>(
          value: item.id,
          child: Text(
            item.nameAr,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator ??
          (isRequired
              ? (val) {
                  if (val == null || val.isEmpty) {
                    return l10n.selectProvinceError;
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
}
