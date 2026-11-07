import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import 'gender_selector.dart';

/// بطاقة المعلومات الإضافية (الجنس وتاريخ الميلاد)
class ProfileAdditionalInfoCard extends StatelessWidget {
  final String? selectedGender;
  final DateTime? selectedBirthDate;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onSelectBirthDate;

  const ProfileAdditionalInfoCard({
    super.key,
    required this.selectedGender,
    required this.selectedBirthDate,
    required this.onGenderChanged,
    required this.onSelectBirthDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.additionalInfoOptional,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // الجنس
          GenderSelector.chips(
            selectedGender: selectedGender,
            onChanged: onGenderChanged,
          ),

          const Divider(height: 20),

          // تاريخ الميلاد
          InkWell(
            onTap: onSelectBirthDate,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.cake_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.birthDateColon,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    selectedBirthDate != null
                        ? DateFormat('yyyy/MM/dd', isRtl ? 'ar' : 'en').format(selectedBirthDate!)
                        : l10n.chooseDate,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: selectedBirthDate != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: selectedBirthDate != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
