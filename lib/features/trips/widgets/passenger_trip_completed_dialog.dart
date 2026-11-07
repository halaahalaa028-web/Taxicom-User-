import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/payment_helper.dart';
import '../../../core/widgets/custom_button.dart';
import '../utils/trip_calculation_helper.dart';
import '../models/trip_request_model.dart';

/// نافذة إشعار إتمام الرحلة وفاتورة الدفع للراكب
class PassengerTripCompletedDialog extends StatelessWidget {
  final TripRequestModel trip;
  final VoidCallback onContinue;

  const PassengerTripCompletedDialog({
    super.key,
    required this.trip,
    required this.onContinue,
  });

  static Future<void> show(
    BuildContext context, {
    required TripRequestModel trip,
    required VoidCallback onContinue,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PassengerTripCompletedDialog(
        trip: trip,
        onContinue: onContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWallet = PaymentHelper.isWalletPayment(trip.paymentMethod);
    final bool isCard = PaymentHelper.isCardPayment(trip.paymentMethod);
    final bool isElectronic = PaymentHelper.isElectronicPayment(trip.paymentMethod);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة النجاح
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 14),

            // عنوان اكتمال الرحلة
            const Text(
              'وصلت بالسلامة!',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trip.driverName != null && trip.driverName!.isNotEmpty
                  ? 'تم إنهاء الرحلة مع الكابتن ${trip.driverName}'
                  : 'تم إنهاء الرحلة بنجاح',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // كارت تفاصيل الفاتورة
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // المبلغ الإجمالي
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'إجمالي الأجرة:',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        TripCalculationHelper.formatPrice(
                          trip.price,
                          currency: trip.currency,
                          countryCode: trip.countryCode,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  if (trip.hasDiscount) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'خصم الكوبون:',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.orange),
                        ),
                        Text(
                          '-${TripCalculationHelper.formatPrice(
                            trip.discountAmount!,
                            currency: trip.currency,
                            countryCode: trip.countryCode,
                          )}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // حالة وطريقة الدفع
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          isWallet
                              ? Icons.account_balance_wallet_rounded
                              : isCard
                                  ? Icons.credit_card_rounded
                                  : Icons.payments_rounded,
                          size: 22,
                          color: isElectronic ? AppColors.success : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isWallet
                                  ? 'تم الخصم من المحفظة'
                                  : isCard
                                      ? 'تم الدفع بالبطاقة البنكية'
                                      : 'الدفع نقداً للكابتن',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isElectronic ? AppColors.success : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isElectronic
                                  ? 'لا تدفع أي مبالغ نقدية للكابتن'
                                  : 'يرجى تسليم المبلغ نقداً للكابتن',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isElectronic
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : Colors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isElectronic ? 'مدفوع إلكترونياً' : 'مطلوب نقداً',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isElectronic ? AppColors.success : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // زر المتابعة والتقييم
            CustomButton(
              text: 'متابعة وتقييم الكابتن',
              icon: Icons.star_rate_rounded,
              height: 50,
              fontSize: 15,
              borderRadius: 12,
              elevation: 0,
              onPressed: () {
                Navigator.pop(context);
                onContinue();
              },
            ),
          ],
        ),
      ),
    );
  }
}
