/// لوحة تتبع الرحلة النشطة والسائق
///
/// تعرض حالة البحث عن سائق، أو تفاصيل السائق في الطريق وتفاصيل الرحلة
library;

import 'package:flutter/material.dart';
import '../../../trips/models/trip_request_model.dart';
import 'home_waiting_trip_panel.dart';
import 'home_driver_on_way_panel.dart';

class HomeActiveTripPanel extends StatelessWidget {
  final TripRequestModel? activeTrip;
  final double totalDistance;
  final double price;
  final String? paymentMethod;
  final double? searchRadiusKm;
  final String? searchStageDescription;
  final double searchProgress;
  final int searchElapsedSeconds;
  final int unreadMessagesCount;
  final VoidCallback onCancelTrip;
  final VoidCallback onCallDriver;
  final VoidCallback onChatWithDriver;

  const HomeActiveTripPanel({
    super.key,
    required this.activeTrip,
    required this.totalDistance,
    required this.price,
    this.paymentMethod,
    this.searchRadiusKm,
    this.searchStageDescription,
    this.searchProgress = 0.0,
    this.searchElapsedSeconds = 0,
    this.unreadMessagesCount = 0,
    required this.onCancelTrip,
    required this.onCallDriver,
    required this.onChatWithDriver,
  });

  @override
  Widget build(BuildContext context) {
    if (activeTrip == null || activeTrip!.status == TripStatus.pending) {
      return HomeWaitingTripPanel(
        totalDistance: totalDistance,
        price: price,
        paymentMethod: activeTrip?.paymentMethod ?? paymentMethod,
        searchRadiusKm: searchRadiusKm,
        searchStageDescription: searchStageDescription,
        searchProgress: searchProgress,
        searchElapsedSeconds: searchElapsedSeconds,
        onCancelTrip: onCancelTrip,
      );
    }

    return HomeDriverOnWayPanel(
      trip: activeTrip!,
      totalDistance: totalDistance,
      price: price,
      unreadMessagesCount: unreadMessagesCount,
      onCancelTrip: onCancelTrip,
      onCallDriver: onCallDriver,
      onChatWithDriver: onChatWithDriver,
    );
  }
}
