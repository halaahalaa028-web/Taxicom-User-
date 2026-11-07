/// لوحة السائق في الطريق وتفاصيل الرحلة
///
/// تعرض معلومات السائق، وأزرار الاتصال والمحادثة، وقسم تفاصيل الرحلة (السعر، المسافة، الوقت المتوقع)، وزر الإلغاء
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../trips/models/trip_request_model.dart';
import 'home_driver_trip_metrics_card.dart';
import 'home_driver_car_info_badge.dart';

class HomeDriverOnWayPanel extends StatelessWidget {
  final TripRequestModel trip;
  final double totalDistance;
  final double price;
  final int unreadMessagesCount;
  final VoidCallback onCancelTrip;
  final VoidCallback onCallDriver;
  final VoidCallback onChatWithDriver;

  const HomeDriverOnWayPanel({
    super.key,
    required this.trip,
    required this.totalDistance,
    required this.price,
    this.unreadMessagesCount = 0,
    required this.onCancelTrip,
    required this.onCallDriver,
    required this.onChatWithDriver,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveDistance = trip.distance > 0 ? trip.distance : totalDistance;
    final effectivePrice = trip.price > 0 ? trip.price : price;
    final effectiveDuration = trip.estimatedDuration ?? (effectiveDistance * 2.5).round().clamp(5, 120);

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
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // المقبض
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 12),

                // شارة حالة السائق
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.navigation_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        trip.status == TripStatus.pickedUp
                            ? l10n.inTransitStatus
                            : trip.status == TripStatus.arrivedAtPickup
                                ? l10n.driverArrivedAtYourLocation
                                : l10n.driverAcceptedStatus,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                if (trip.startOtp != null && trip.status != TripStatus.pickedUp) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pin_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        const Text(
                          'رمز بدء الرحلة للكابتن: ',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          trip.startOtp!,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // معلومات السائق (الصورة والاسم ورقم الهاتف)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.surfaceVariant,
                      backgroundImage: trip.driverPhotoUrl != null && trip.driverPhotoUrl!.isNotEmpty
                          ? NetworkImage(trip.driverPhotoUrl!)
                          : null,
                      child: trip.driverPhotoUrl == null || trip.driverPhotoUrl!.isEmpty
                          ? const Icon(Icons.person_rounded, size: 30, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.driverName ?? 'السائق',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            trip.driverPhone ?? '',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // بطاقة بيانات ومعلومات سيارة السائق ورقم اللوحة
                HomeDriverCarInfoBadge(
                  carNumber: trip.carNumber,
                  carModel: trip.carModel,
                  carColor: trip.carColor,
                  carType: trip.carType,
                ),

                const SizedBox(height: 16),

                // أزرار التواصل (اتصال + محادثة مع شارة الرسائل)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onCallDriver,
                        icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                        label: Text(
                          AppLocalizations.of(context).callDriver,
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: onChatWithDriver,
                              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                              label: Text(
                                AppLocalizations.of(context).chatWithDriver,
                                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          if (unreadMessagesCount > 0)
                            Positioned(
                              top: -6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE53935).withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                                child: Center(
                                  child: Text(
                                    '$unreadMessagesCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // خط أفقي فاصل
                const Divider(height: 1, thickness: 1, color: AppColors.border),

                const SizedBox(height: 14),

                // تفاصيل ومقاييس الرحلة (السعر - المسافة - الوقت المتوقع) وشارة توجيه الدفع
                HomeDriverTripMetricsCard(
                  effectivePrice: effectivePrice,
                  effectiveDistance: effectiveDistance,
                  effectiveDuration: effectiveDuration,
                  paymentMethod: trip.paymentMethod,
                ),

                const SizedBox(height: 14),

                // زر الإلغاء
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onCancelTrip,
                    child: Text(
                      AppLocalizations.of(context).cancelTrip,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
