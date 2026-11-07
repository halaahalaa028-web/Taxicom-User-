/// حوار إشعار عدم العثور على سائق متاح عند انتهاء المهلة
///
/// يوفر خياري إعادة المحاولة أو الإلغاء بتصميم مونوكروم راقٍ
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/custom_button.dart';

class NoDriversFoundDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const NoDriversFoundDialog({
    super.key,
    required this.onRetry,
    required this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onRetry,
    required VoidCallback onCancel,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => NoDriversFoundDialog(
        onRetry: () {
          Navigator.of(ctx).pop();
          onRetry();
        },
        onCancel: () {
          Navigator.of(ctx).pop();
          onCancel();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة الرادار المميزة
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.radar_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            // العنوان الرئيسي
            Text(
              l10n.noDriversTitle,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // الوصف التوضيحي
            Text(
              l10n.noDriversDesc,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // زر إعادة المحاولة
            CustomButton(
              text: l10n.retryNow,
              onPressed: onRetry,
              height: 50,
              fontSize: 15,
              borderRadius: 14,
              elevation: 0,
            ),

            const SizedBox(height: 10),

            // زر الإلغاء / العودة
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.cancelAndReturnHome,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
