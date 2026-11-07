import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../trips/utils/trip_calculation_helper.dart';
import 'home_trip_payment_status_badge.dart';

/// ويدجت عرض مقاييس الرحلة الثلاثية (السعر - المسافة - الوقت المتوقع) وشارة توجيه الدفع
class HomeDriverTripMetricsCard extends StatelessWidget {
  final double effectivePrice;
  final double effectiveDistance;
  final int effectiveDuration;
  final String? paymentMethod;

  const HomeDriverTripMetricsCard({
    super.key,
    required this.effectivePrice,
    required this.effectiveDistance,
    required this.effectiveDuration,
    this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان قسم تفاصيل الرحلة
        Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              l10n.tripDetails,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // بطاقات تفاصيل الرحلة الثلاث
        Row(
          children: [
            // سعر الرحلة
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${TripCalculationHelper.formatPrice(effectivePrice)} ${l10n.currency}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.tripPrice,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // مسافة الرحلة
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${effectiveDistance.toStringAsFixed(1)} ${l10n.km}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.tripDistanceLabel,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // وقت الرحلة المتوقع
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$effectiveDuration ${l10n.minutes}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.expectedTimeLabel,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // شارة توجيه وإرشاد حالة وطريقة الدفع للراكب
        if (paymentMethod != null && paymentMethod!.isNotEmpty) ...[
          const SizedBox(height: 12),
          HomeTripPaymentStatusBadge(
            paymentMethod: paymentMethod!,
            effectivePrice: effectivePrice,
          ),
        ],
      ],
    );
  }
}
