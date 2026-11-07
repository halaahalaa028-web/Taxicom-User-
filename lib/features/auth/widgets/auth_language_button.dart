/// زر اختيار اللغة لشاشات تسجيل الدخول والمصادقة
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';

class AuthLanguageButton extends StatelessWidget {
  const AuthLanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLang = LanguageService.instance.currentLanguage;
    final languages = LanguageService.instance.supportedLanguages;

    return PopupMenuButton<AppLanguage>(
      onSelected: (language) async {
        await LanguageService.instance.setLanguage(language);
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              currentLang.name,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => languages.map((language) {
        final isSelected = language == currentLang;
        return PopupMenuItem<AppLanguage>(
          value: language,
          child: Row(
            children: [
              Icon(
                Icons.translate_rounded,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  language.name,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
