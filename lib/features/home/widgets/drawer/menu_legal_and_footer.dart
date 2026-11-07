import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

/// القسم السفلي للقائمة الكاملة (الروابط القانونية، زر تسجيل الخروج، ورقم الإصدار)
class MenuLegalAndFooter extends StatelessWidget {
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;
  final VoidCallback onLogoutTap;

  const MenuLegalAndFooter({
    super.key,
    required this.onTermsTap,
    required this.onPrivacyTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomPadding > 0 ? bottomPadding + 16 : 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. زر تسجيل الخروج الأنيق ذو الخلفية الحمراء الخفيفة
          Material(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onLogoutTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.18),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.logout,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            l10n.logoutSubtitle,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: Colors.red.withValues(alpha: 0.75),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 13,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. الروابط القانونية المدمجة (الشروط والأحكام • سياسة الخصوصية)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TextLink(
                title: l10n.termsAndConditions,
                onTap: onTermsTap,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              _TextLink(
                title: l10n.privacyPolicy,
                onTap: onPrivacyTap,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. معلومات الإصدار والشعار السفلي
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_taxi_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${l10n.appName} v1.0.0 • صُنع بحب في العراق',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _TextLink({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.border,
          ),
        ),
      ),
    );
  }
}
