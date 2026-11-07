/// خانة الموافقة على الشروط والأحكام
/// 
/// مكون موحد يتيح للمستخدم الموافقة على الشروط والأحكام
/// مع رابط قابل للنقر لفتح صفحة الشروط الخارجية
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

/// مكون مربع الاختيار للشروط والأحكام
class TermsConditionsCheckbox extends StatelessWidget {
  /// قيمة الموافقة الحالية
  final bool value;

  /// دالة الاستدعاء عند تغيير القيمة
  final ValueChanged<bool> onChanged;

  /// رابط مخصص للشروط والأحكام
  final String? customTermsUrl;

  /// نص مخصص للموافقة
  final String? termsText;

  const TermsConditionsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.customTermsUrl,
    this.termsText,
  });

  Future<void> _openTermsUrl() async {
    final url = Uri.parse(customTermsUrl ?? 'https://sites.google.com/view/taxicoma/%D8%A7%D9%84%D8%B5%D9%81%D8%AD%D8%A9-%D8%A7%D9%84%D8%B1%D8%A6%D9%8A%D8%B3%D9%8A%D8%A9');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? AppColors.primaryLight.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppColors.primary : AppColors.border,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: value,
            onChanged: (val) => onChanged(val ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(text: termsText ?? l10n.agreeToTermsPrefix),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: _openTermsUrl,
                        child: Text(
                          l10n.termsAndConditions,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
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
    );
  }
}
