/// بطاقة اختيار لغة التطبيق
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';

/// بطاقة خيار اللغة في شاشة الإعدادات
class LanguageCard extends StatelessWidget {
  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageCard({
    super.key,
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  /// الحصول على الاسم الثانوي / الفرعي للغة
  String _getLanguageSubtitle(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.arabic:
        return 'Arabic';
      case AppLanguage.english:
        return 'English';
      case AppLanguage.kurdish:
        return 'Kurdish';
      case AppLanguage.russian:
        return 'Russian';
      case AppLanguage.german:
        return 'German';
      case AppLanguage.french:
        return 'French';
      case AppLanguage.italian:
        return 'Italian';
      case AppLanguage.spanish:
        return 'Spanish';
      case AppLanguage.turkish:
        return 'Turkish';
      case AppLanguage.chinese:
        return 'Chinese';
      case AppLanguage.persian:
        return 'Persian (Farsi)';
      case AppLanguage.hindi:
        return 'Hindi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.6),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // أيقونة اللغة
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.translate_rounded,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // اسم اللغة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.name,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _getLanguageSubtitle(language),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // علامة الاختيار
                if (isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
