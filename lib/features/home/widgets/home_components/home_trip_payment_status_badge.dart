import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../trips/utils/trip_calculation_helper.dart';

/// شارة إرشادية وتوضيحية لطريقة وحالة الدفع أثناء توجه السائق ومسار الرحلة
class HomeTripPaymentStatusBadge extends StatelessWidget {
  final String paymentMethod;
  final double effectivePrice;

  const HomeTripPaymentStatusBadge({
    super.key,
    required this.paymentMethod,
    required this.effectivePrice,
  });

  bool get isCash => paymentMethod.isEmpty || paymentMethod == 'cash';

  String _getReadablePaymentMethodName(AppLocalizations l10n) {
    switch (paymentMethod) {
      case 'wallet':
        return l10n.walletPayment;
      case 'card':
        return l10n.creditCard;
      case 'applePay':
      case 'apple_pay':
        return l10n.applePay;
      default:
        return l10n.walletPayment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formattedPrice = '${TripCalculationHelper.formatPrice(effectivePrice)} ${l10n.currency}';

    final isCashPayment = isCash;
    final backgroundColor = isCashPayment
        ? AppColors.surfaceVariant.withValues(alpha: 0.7)
        : AppColors.success.withValues(alpha: 0.08);

    final borderColor = isCashPayment
        ? AppColors.border.withValues(alpha: 0.8)
        : AppColors.success.withValues(alpha: 0.35);

    final iconColor = isCashPayment ? AppColors.warning : AppColors.success;
    final iconData = isCashPayment ? Icons.payments_rounded : Icons.verified_rounded;

    final badgeMessage = isCashPayment
        ? l10n.paymentMethodCashBadge(formattedPrice)
        : l10n.paymentMethodElectronicBadge(_getReadablePaymentMethodName(l10n));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              badgeMessage,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCashPayment ? AppColors.textPrimary : const Color(0xFF065F46),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
