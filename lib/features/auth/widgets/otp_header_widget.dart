/// ويدجت ترويسة التحقق من رمز OTP
///
/// يعرض أيقونة الرسائل والعنوان الرئيسي وتنسيق رقم الهاتف
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/phone_formatter.dart';

/// ويدجت ترويسة شاشة OTP
class OtpHeaderWidget extends StatelessWidget {
  final String phoneNumber;
  final String? channel;

  const OtpHeaderWidget({
    super.key,
    required this.phoneNumber,
    this.channel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWhatsApp = (channel ?? 'whatsapp').toLowerCase() == 'whatsapp';

    return Column(
      children: [
        // أيقونة القناة
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isWhatsApp ? Icons.chat_bubble_rounded : Icons.sms_rounded,
            size: 42,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),

        // العنوان
        Text(
          l10n.enterOtp,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),

        // الوصف مع توضيح القناة
        Text(
          isWhatsApp
              ? 'تم إرسال رمز التحقق إلى حسابك على واتساب'
              : l10n.otpSentTo,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // رقم الهاتف
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            PhoneFormatter.format(phoneNumber),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
