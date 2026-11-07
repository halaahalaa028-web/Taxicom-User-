import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../trips/utils/trip_calculation_helper.dart';
import '../../data/models/saved_card_model.dart';
import '../utils/wallet_currency_helper.dart';

/// نافذة تأكيد شحن رصيد المحفظة قبل إجراء الخصم الفعلي
class TopUpConfirmationDialog extends StatelessWidget {
  final double amount;
  final String currency;
  final double currentBalance;
  final double exchangeRate;
  final SavedCardModel? selectedCard;
  final VoidCallback onConfirm;

  const TopUpConfirmationDialog({
    super.key,
    required this.amount,
    required this.currency,
    required this.currentBalance,
    this.exchangeRate = 1310.0,
    this.selectedCard,
    required this.onConfirm,
  });

  /// عرض نافذة التأكيد المنبثقة
  static Future<bool?> show(
    BuildContext context, {
    required double amount,
    required String currency,
    required double currentBalance,
    double exchangeRate = 1310.0,
    SavedCardModel? selectedCard,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TopUpConfirmationDialog(
        amount: amount,
        currency: currency,
        currentBalance: currentBalance,
        exchangeRate: exchangeRate,
        selectedCard: selectedCard,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = TripCalculationHelper.formatPrice(amount);
    final formattedCurrentBalance = TripCalculationHelper.formatPrice(currentBalance);
    final formattedNewBalance = TripCalculationHelper.formatPrice(currentBalance + amount);

    final bool isConverted = WalletCurrencyHelper.requiresUsdConversion(currency);
    final double usdEquivalent = isConverted ? (amount / (exchangeRate > 0 ? exchangeRate : 1310.0)) : 0.0;
    final String formattedUsd = usdEquivalent.toStringAsFixed(2);
    final String formattedRate = TripCalculationHelper.formatPrice(exchangeRate > 0 ? exchangeRate : 1310.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // أيقونة المحفظة والتأكيد
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

            // العنوان الرئيسي
            const Text(
              'تأكيد شحن المحفظة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'يرجى مراجعة تفاصيل العملية قبل الخصم',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 18),

            // بطاقة تفاصيل المبلغ والرصيد
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // المبلغ المشحون
                  _buildDetailRow(
                    label: 'المبلغ المراد شحنه:',
                    value: '$formattedAmount $currency',
                    isHighlight: true,
                    valueColor: AppColors.primary,
                  ),

                  // تفاصيل التحويل بالدولار أو الخصم المباشر
                  if (isConverted) ...[
                    const SizedBox(height: 6),
                    _buildDetailRow(
                      label: 'المبلغ المخصوم بالبطاقة:',
                      value: '≈ \$$formattedUsd USD',
                      isBold: true,
                      valueColor: AppColors.textPrimary,
                    ),
                    const SizedBox(height: 4),
                    _buildDetailRow(
                      label: 'سعر الصرف المعتمد:',
                      value: '1 USD ≈ $formattedRate $currency',
                      valueColor: AppColors.textSecondary,
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    _buildDetailRow(
                      label: 'المبلغ المخصوم بالبطاقة:',
                      value: '$formattedAmount $currency',
                      isBold: true,
                      valueColor: AppColors.textPrimary,
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.border),
                  ),

                  // وسيلة الدفع
                  _buildDetailRow(
                    label: 'وسيلة الدفع:',
                    value: selectedCard != null
                        ? '${selectedCard!.brand.toUpperCase()} •••• ${selectedCard!.last4}'
                        : 'بطاقة بنكية جديدة',
                  ),

                  const SizedBox(height: 8),

                  // الرصيد الحالي
                  _buildDetailRow(
                    label: 'الرصيد الحالي:',
                    value: '$formattedCurrentBalance $currency',
                    valueColor: AppColors.textSecondary,
                  ),

                  const SizedBox(height: 8),

                  // الرصيد بعد الشحن
                  _buildDetailRow(
                    label: 'الرصيد بعد الشحن:',
                    value: '$formattedNewBalance $currency',
                    valueColor: AppColors.success,
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isConverted
                    ? 'يتم الخصم بالدولار (\$) عبر بوابة Stripe ويُضاف كامل المبلغ ($currency) إلى محفظتك.'
                    : 'يتم الخصم مباشرة بالعملة المحلية ($currency) عبر بوابة Stripe ويُضاف كامل الرصيد لمحفظتك.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // تنبيه أمني
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  'معاملة مشفرة ومؤمنة بنكياً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // أزرار التأكيد والإلغاء
            Row(
              children: [
                // زر التراجع / الإلغاء
                Expanded(
                  child: Material(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // زر التأكيد والدفع
                Expanded(
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 2,
                    child: InkWell(
                      onTap: onConfirm,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'تأكيد وشحن',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildDetailRow({
    required String label,
    required String value,
    bool isHighlight = false,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: isHighlight ? 13 : 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: isHighlight ? 15 : 13,
            fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
