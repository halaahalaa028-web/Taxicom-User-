/// لوحة تأكيد تفاصيل وحساب سعر الرحلة
///
/// تعرض المسافة، السعر، الكوبونات والهدايا، والخيارات الإضافية مع زر التأكيد
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../trips/utils/trip_calculation_helper.dart';
import '../../../trips/models/trip_request_model.dart';
import '../../../profile/models/coupon_model.dart';
import 'home_payment_method_selector.dart';

class HomeTripConfirmationSheet extends StatelessWidget {
  final TripType selectedTripType;
  final ValueChanged<TripType> onTripTypeChanged;
  final bool isRoundTrip;
  final String? waitTime;
  final String formattedDistance;
  final double originalPrice;
  final double finalPrice;
  final double discountAmount;
  final CouponModel? appliedCoupon;
  final String selectedPaymentMethod;
  final ValueChanged<String>? onPaymentMethodChanged;
  final VoidCallback onOpenTripOptions;
  final VoidCallback onOpenPromos;
  final bool isCreatingTrip;
  final VoidCallback onConfirmTrip;

  const HomeTripConfirmationSheet({
    super.key,
    required this.selectedTripType,
    required this.onTripTypeChanged,
    required this.isRoundTrip,
    required this.waitTime,
    required this.formattedDistance,
    required this.originalPrice,
    required this.finalPrice,
    required this.discountAmount,
    required this.appliedCoupon,
    this.selectedPaymentMethod = 'cash',
    this.onPaymentMethodChanged,
    required this.onOpenTripOptions,
    required this.onOpenPromos,
    required this.isCreatingTrip,
    required this.onConfirmTrip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // شريط التبديل بين تكسي وتوصيل
              Container(
                padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTripTypeChanged(TripType.ride),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedTripType == TripType.ride
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: selectedTripType == TripType.ride
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_taxi_rounded,
                            size: 20,
                            color: selectedTripType == TripType.ride
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).rideTab,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: selectedTripType == TripType.ride
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTripTypeChanged(TripType.delivery),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedTripType == TripType.delivery
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: selectedTripType == TripType.delivery
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delivery_dining_rounded,
                            size: 20,
                            color: selectedTripType == TripType.delivery
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).deliveryTab,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: selectedTripType == TripType.delivery
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // خيارات إضافية (ذهاب وإياب / وقت انتظار)
          if (isRoundTrip || waitTime != null) ...[
            Row(
              children: [
                if (isRoundTrip)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.loop_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.roundTripBadge,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (isRoundTrip && waitTime != null) const SizedBox(width: 8),

                if (waitTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_rounded, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          l10n.waitingWithTime(l10n.formatWaitTime(waitTime!)),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // المسافة والسعر
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.straighten_rounded, color: AppColors.textSecondary),
                      const SizedBox(height: 4),
                      Text(
                        formattedDistance,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context).distance,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.payments_rounded, color: AppColors.primary),
                      const SizedBox(height: 4),
                      if (discountAmount > 0) ...[
                        Text(
                          '${TripCalculationHelper.formatPrice(originalPrice)} ${AppLocalizations.of(context).currency}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${TripCalculationHelper.formatPrice(finalPrice)} ${AppLocalizations.of(context).currency}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '${TripCalculationHelper.formatPrice(originalPrice)} ${AppLocalizations.of(context).currency}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      Text(
                        AppLocalizations.of(context).price,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // اختيار وسيلة الدفع
          if (onPaymentMethodChanged != null)
            HomePaymentMethodSelector(
              selectedPaymentMethod: selectedPaymentMethod,
              onPaymentMethodChanged: onPaymentMethodChanged!,
              tripPrice: finalPrice,
            ),

          const SizedBox(height: 14),

          // زر تأكيد الطلب
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isCreatingTrip ? null : onConfirmTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isCreatingTrip
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context).confirmRequest,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}
