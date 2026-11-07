/// ويدجت اختيار تاريخ الميلاد الموحد
/// 
/// يتيح اختيار التاريخ عبر منتقي التواريخ المدمج مع تطبيق الثيم المونوكرومي
/// وتنسيق التاريخ باللغة العربية
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

/// مكون اختيار تاريخ الميلاد
class BirthDatePicker extends StatelessWidget {
  /// التاريخ المحدد حالياً
  final DateTime? selectedDate;

  /// دالة الاستدعاء عند اختيار تاريخ
  final ValueChanged<DateTime> onDateSelected;

  /// هل الحقل إجباري
  final bool isRequired;

  /// نص التسمية
  final String? labelText;

  /// تلميح الحقل
  final String? hintText;

  /// دالة التحقق
  final String? Function(DateTime?)? validator;

  /// لون الخلفية
  final Color? fillColor;

  /// هل الحقل مفعل
  final bool enabled;

  /// أقدم تاريخ يمكن اختياره
  final DateTime? firstDate;

  /// أحدث تاريخ يمكن اختياره
  final DateTime? lastDate;

  const BirthDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.isRequired = false,
    this.labelText,
    this.hintText,
    this.validator,
    this.fillColor,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
  });

  Future<void> _pickDate(BuildContext context) async {
    if (!enabled) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000),
      firstDate: firstDate ?? DateTime(1940),
      lastDate: lastDate ?? DateTime.now(),
      locale: const Locale('ar'),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final effectiveLabel = (labelText ?? l10n.birthDateColon.replaceAll(':', '')) + (isRequired ? ' *' : '');
    final dateText = selectedDate != null
        ? DateFormat('yyyy/MM/dd', isRtl ? 'ar' : 'en').format(selectedDate!)
        : '';

    return GestureDetector(
      onTap: enabled ? () => _pickDate(context) : null,
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          controller: TextEditingController(text: dateText),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          validator: (val) {
            if (validator != null) {
              return validator!(selectedDate);
            }
            if (isRequired && selectedDate == null) {
              return l10n.selectBirthDateError;
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: effectiveLabel,
            hintText: hintText ?? (isRtl ? 'يوم / شهر / سنة' : 'DD / MM / YYYY'),
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.primary, size: 22),
            suffixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 18),
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
        ),
      ),
    );
  }
}
