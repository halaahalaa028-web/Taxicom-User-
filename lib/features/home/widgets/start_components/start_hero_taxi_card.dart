/// بطاقة طلب التكسي الرئيسية لشاشة البداية
///
/// بطاقة Hero فاخرة بتدرج الأزرق الملكي وزر الحجز التفاعلي بالأصفر التاكسي
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

class StartHeroTaxiCard extends StatelessWidget {
  final VoidCallback onTap;

  const StartHeroTaxiCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primary,
          gradient: const LinearGradient(
            colors: [
              AppColors.primaryLight,
              AppColors.primary,
              AppColors.primaryDark,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // خلفية أيقونة تاكسي كعلامة مائية خفيفة
            const Positioned(
              left: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.local_taxi_rounded,
                  size: 180,
                  color: Colors.white,
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أيقونة التكسي الرئيسية بالأصفر التاكسي المشرق
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_taxi_rounded,
                    color: AppColors.textOnAccent,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 24),

                // العنوان الرئيسي
                Text(
                  l10n.bookTaxi,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  l10n.startHeroDescription,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // زر الحركة التفاعلي بالداخل (أصفر تاكسي فخم)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.bookRideNow,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.textOnAccent,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
