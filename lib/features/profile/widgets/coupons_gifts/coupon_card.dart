import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../models/coupon_model.dart';

/// بطاقة عرض تفاصيل كوبون الخصم والمكافأة للمستخدم
class CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final bool isApplied;
  final VoidCallback onApply;

  const CouponCard({
    super.key,
    required this.coupon,
    required this.isApplied,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isApplied ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isApplied ? AppColors.primary : AppColors.border,
          width: isApplied ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isApplied ? AppColors.primaryLight.withValues(alpha: 0.05) : AppColors.surface,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شريط العنوان والرمز
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        coupon.code,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (coupon.hasTargetAudience) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.card_giftcard_rounded, size: 13, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              l10n.specialReward,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 19),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: coupon.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.codeCopiedSuccess,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),

            if (coupon.title != null && coupon.title!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                coupon.title!,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],

            if (coupon.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                coupon.description,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // شارات تفاصيل الخصم والشروط
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag(
                  icon: coupon.isFreeRide ? Icons.star_rounded : Icons.trending_down_rounded,
                  label: coupon.isFreeRide
                      ? l10n.freeRideGift
                      : l10n.discountLabel('${coupon.discountValue.toInt()}%'),
                ),
              ],
            ),

            const Divider(height: 24),

            // تاريخ الانتهاء وزر التطبيق
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.expiryDate}: ${DateFormat('yyyy/MM/dd', isRtl ? 'ar' : 'en').format(coupon.expiryDate)}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApplied ? Colors.grey[700] : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  ),
                  child: Text(
                    isApplied ? l10n.deactivate : l10n.applyNow,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
