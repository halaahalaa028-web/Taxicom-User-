import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../trips/utils/trip_calculation_helper.dart';

/// قسم ملخص وتفاصيل السعر النهائي في نافذة خيارات الرحلة
class TripOptionsPriceSummary extends StatelessWidget {
  final double estimatedPrice;
  final double finalDiscount;
  final double finalPrice;

  const TripOptionsPriceSummary({
    super.key,
    required this.estimatedPrice,
    required this.finalDiscount,
    required this.finalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = l10n.currency;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.estimatedPriceColon,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: AppColors.textSecondary),
              ),
              Text(
                '${TripCalculationHelper.formatPrice(estimatedPrice)} $currency',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (finalDiscount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.discountColon,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: AppColors.primary),
                ),
                Text(
                  '-${TripCalculationHelper.formatPrice(finalDiscount)} $currency',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.finalPriceColon,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${TripCalculationHelper.formatPrice(finalPrice)} $currency',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
