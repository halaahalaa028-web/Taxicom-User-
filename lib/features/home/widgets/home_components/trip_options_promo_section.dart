import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../trips/utils/trip_calculation_helper.dart';

/// قسم الكوبونات والهدايا داخل نافذة خيارات الرحلة
class TripOptionsPromoSection extends StatelessWidget {
  final String? appliedCodeName;
  final double discount;
  final TextEditingController promoCodeController;
  final String? promoError;
  final VoidCallback onApplyCode;
  final VoidCallback onClearPromo;
  final VoidCallback onOpenCouponsGifts;

  const TripOptionsPromoSection({
    super.key,
    required this.appliedCodeName,
    required this.discount,
    required this.promoCodeController,
    required this.promoError,
    required this.onApplyCode,
    required this.onClearPromo,
    required this.onOpenCouponsGifts,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).promoCodeLabel,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          if (appliedCodeName != null) ...[
            // كارد الكوبون المطبق
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appliedCodeName!,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          l10n.discountApplied(TripCalculationHelper.formatPrice(discount)),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.red),
                    onPressed: onClearPromo,
                  ),
                ],
              ),
            ),
          ] else ...[
            // إدخال كود يدوي
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: promoCodeController,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'PROMO123',
                      hintStyle: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.grey[400],
                        letterSpacing: 2,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      errorText: promoError,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onApplyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    l10n.applyPromo,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // زر اختيار من الهدايا والكوبونات
          OutlinedButton.icon(
            onPressed: onOpenCouponsGifts,
            icon: const Icon(Icons.card_giftcard_rounded, size: 18),
            label: Text(
              l10n.chooseFromCouponsAndGifts,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
