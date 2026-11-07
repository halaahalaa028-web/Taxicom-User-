/// شريط العنوان العلوي للشاشة الرئيسية
///
/// يحتوي على زر الرجوع، شارة اسم التطبيق، وزر الانتقال للموقع الحالي
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

class HomeAppBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onMyLocation;

  const HomeAppBar({
    super.key,
    required this.onBack,
    required this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // زر الرجوع
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textPrimary,
                onPressed: onBack,
              ),
            ),

            const Spacer(),

            // اسم وشعار التطبيق
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_taxi_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).appName,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // زر الموقع الحالي
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location_rounded),
                color: AppColors.primary,
                onPressed: onMyLocation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
