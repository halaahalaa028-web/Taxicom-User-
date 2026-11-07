import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/trip_request_model.dart';
import '../utils/trip_calculation_helper.dart';

/// رأس بطاقة تفاصيل الرحلة (الحالة، التاريخ، والسعر)
class TripCardHeader extends StatelessWidget {
  final TripRequestModel trip;

  const TripCardHeader({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(trip.status);
    final isCompleted = trip.status == TripStatus.completed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.surfaceVariant
            : statusColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // أيقونة وشارة الحالة
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(trip.status),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(context, trip.status),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  _formatDate(context, trip.createdAt),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // شارة السعر والخصم
          _buildPriceSection(context),
        ],
      ),
    );
  }

  /// قسم عرض السعر وتفاصيل الخصم (السعر المدفوع، السعر الأصلي، وشارة التوفير)
  Widget _buildPriceSection(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currency = (trip.currency != null && trip.currency!.isNotEmpty)
        ? trip.currency!
        : loc.currency;
    final formattedPaidPrice =
        '${TripCalculationHelper.formatPrice(trip.price)} $currency';

    if (!trip.hasDiscount) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          formattedPaidPrice,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final formattedOriginalPrice =
        '${TripCalculationHelper.formatPrice(trip.effectiveOriginalPrice)} $currency';
    final formattedDiscount =
        '${TripCalculationHelper.formatPrice(trip.discountAmount!)} $currency';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // السعر النهائي المدفوع
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            formattedPaidPrice,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // السعر الأصلي المشطوب + شارة الخصم
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formattedOriginalPrice,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10.5,
                color: AppColors.textSecondary,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_offer_outlined,
                    size: 9,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    loc.discountLabel(formattedDiscount),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
      case TripStatus.accepted:
      case TripStatus.arrivedAtPickup:
      case TripStatus.pickedUp:
        return AppColors.textPrimary;
      case TripStatus.completed:
        return AppColors.primary;
      case TripStatus.cancelled:
      case TripStatus.cancelledByDriver:
        return const Color(0xFF555555);
    }
  }

  IconData _getStatusIcon(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return Icons.hourglass_empty_rounded;
      case TripStatus.accepted:
      case TripStatus.arrivedAtPickup:
      case TripStatus.pickedUp:
        return Icons.drive_eta_rounded;
      case TripStatus.completed:
        return Icons.check_rounded;
      case TripStatus.cancelled:
      case TripStatus.cancelledByDriver:
        return Icons.close_rounded;
    }
  }

  String _getStatusText(BuildContext context, TripStatus status) {
    final loc = AppLocalizations.of(context);
    switch (status) {
      case TripStatus.pending:
        return loc.statusPending;
      case TripStatus.accepted:
        return loc.statusAccepted;
      case TripStatus.arrivedAtPickup:
        return loc.driverArrived;
      case TripStatus.pickedUp:
        return loc.onTheWay;
      case TripStatus.completed:
        return loc.statusCompleted;
      case TripStatus.cancelled:
        return loc.statusCancelled;
      case TripStatus.cancelledByDriver:
        return loc.statusCancelledByDriver;
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripDate = DateTime(date.year, date.month, date.day);

    final loc = AppLocalizations.of(context);
    final isRtl = loc.isRtl;
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? (isRtl ? 'صباحاً' : 'AM') : (isRtl ? 'مساءً' : 'PM');
    final timeStr = '$hour:$minute $period';

    if (tripDate == today) {
      return '${loc.today} $timeStr';
    } else if (tripDate == today.subtract(const Duration(days: 1))) {
      return '${loc.yesterday} $timeStr';
    } else {
      final dateStr = DateFormat('dd/MM/yyyy', isRtl ? 'ar' : 'en').format(date);
      return '$dateStr - $timeStr';
    }
  }
}
