/// بانر متابعة الرحلة النشطة لشاشة البداية
///
/// يعرض حالة الرحلة الحالية مع زر للمتابعة والانتقال للخريطة
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../trips/models/trip_request_model.dart';

class StartActiveTripBanner extends StatelessWidget {
  final Stream<TripRequestModel?> activeTripStream;
  final VoidCallback onTap;

  const StartActiveTripBanner({
    super.key,
    required this.activeTripStream,
    required this.onTap,
  });

  String _getTripStatusText(BuildContext context, TripStatus status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case TripStatus.pending:
        return l10n.searchingNearbyDriverStatus;
      case TripStatus.accepted:
        return l10n.driverAcceptedStatus;
      case TripStatus.arrivedAtPickup:
        return l10n.driverArrivedPickupStatus;
      case TripStatus.pickedUp:
        return l10n.inTransitStatus;
      default:
        return l10n.activeTripNow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<TripRequestModel?>(
      stream: activeTripStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final trip = snapshot.data!;
        final statusText = _getTripStatusText(context, trip.status);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryLight, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                          const SizedBox(width: 6),
                          Text(
                            l10n.activeTripNow,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.track,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.primary,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
