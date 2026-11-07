import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/directions_service.dart';
import '../../../core/services/location_service.dart';
import '../../trips/services/trip_request_service.dart';

/// مدير المسارات والتسعير (Route & Fare Manager)
///
/// مسؤول عن:
/// - جلب المسارات والـ Polyline من Google Directions API للوجهة الأساسية والثانية
/// - حساب المسافات والأوقات التقديرية وتطبيق البدائل التقريبية عند انقطاع الاتصال
/// - تطبيق سقف المسافات العادل (Fare Cap Calculation) وحساب السعر التقديري الأساسي
/// - ملاءمة حدود الكاميرا (LatLngBounds) لعرض كامل المسار بين نقطة الانطلاق والوصول
class HomeRouteManager {
  final DirectionsService _directionsService = DirectionsService.instance;
  final LocationService _locationService = LocationService.instance;
  final TripRequestService _tripService = TripRequestService.instance;

  // حالة المسار والمسافات والأوقات
  List<LatLng> polylinePoints = [];
  double? distance;
  double? secondDestinationDistance;
  int? estimatedDuration;
  int? secondDestinationDuration;
  bool isLoadingRoute = false;

  /// الحصول على المسار الحقيقي من Google Directions API للوجهة الأولى (مع Waypoints إن وجدت)
  Future<void> fetchRoutePolyline({
    required LatLng origin,
    required LatLng destination,
    LatLng? secondDestination,
    void Function(String message, {bool isError, bool isWarning, bool isSuccess})? onShowMessage,
    required VoidCallback onUpdate,
  }) async {
    final List<LatLng> waypoints = [];
    if (secondDestination != null) {
      waypoints.add(secondDestination);
    }

    final result = await _directionsService.getDirections(
      origin: origin,
      destination: destination,
      waypoints: waypoints.isNotEmpty ? waypoints : null,
    );

    if (result != null && result.polylinePoints.isNotEmpty) {
      final List<LatLng> points = List.from(result.polylinePoints);
      if (points.first.latitude != origin.latitude || points.first.longitude != origin.longitude) {
        points.insert(0, origin);
      }
      if (points.last.latitude != destination.latitude || points.last.longitude != destination.longitude) {
        points.add(destination);
      }
      polylinePoints = points;
      distance = result.distanceMeters / 1000.0;
      estimatedDuration = (result.durationSeconds / 60).round();
      onUpdate();
    } else {
      onShowMessage?.call(
        'تعذّر تحميل المسار. تحقّق من الاتصال بالإنترنت وحاول مرة أخرى.',
        isWarning: true,
      );

      // Fallback: استخدام المسافة التقريبية مع إضافة 30%
      if (distance == null) {
        final straightDistance = _locationService.calculateDistance(
          origin.latitude,
          origin.longitude,
          destination.latitude,
          destination.longitude,
        );
        distance = straightDistance * 1.3;
        onUpdate();
      }
    }
  }

  /// الحصول على المسار من الوجهة الأولى إلى الوجهة الثانية
  Future<void> fetchSecondDestinationRoute({
    required LatLng destination,
    required LatLng secondDestination,
    required VoidCallback onUpdate,
  }) async {
    final result = await _directionsService.getDirections(
      origin: destination,
      destination: secondDestination,
    );

    if (result != null) {
      secondDestinationDistance = result.distanceMeters / 1000.0;
      secondDestinationDuration = (result.durationSeconds / 60).round();
      onUpdate();
    } else {
      final straightDistance = _tripService.calculateDistanceBetween(
        destination.latitude,
        destination.longitude,
        secondDestination.latitude,
        secondDestination.longitude,
      );
      secondDestinationDistance = straightDistance * 1.3;
      secondDestinationDuration = (secondDestinationDistance! * 2).round();
      onUpdate();
    }
  }

  /// تحريك الكاميرا لعرض المسار بالكامل بين نقطة الانطلاق والوجهة
  void fitBounds({
    required GoogleMapController? mapController,
    required LatLng origin,
    required LatLng? destination,
  }) {
    if (destination == null || mapController == null) return;

    double minLat = origin.latitude;
    double maxLat = origin.latitude;
    double minLng = origin.longitude;
    double maxLng = origin.longitude;

    minLat = math.min(minLat, destination.latitude);
    maxLat = math.max(maxLat, destination.latitude);
    minLng = math.min(minLng, destination.longitude);
    maxLng = math.max(maxLng, destination.longitude);

    for (final point in polylinePoints) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    } catch (e) {
      debugPrint('⚠️ [Map] animateCamera failed: $e');
    }
  }

  /// حساب المسافة الكلية التقديرية
  double getEstimatedTotalDistance() {
    if (distance == null) return 0.0;
    double total = distance!;
    if (secondDestinationDistance != null) {
      total += secondDestinationDistance!;
    }
    return total;
  }

  /// الحصول على المسافة الكلية التقديرية مع تطبيق سقف المسافات العادل (Fare Cap)
  double getCappedEstimatedTotalDistance({
    required LatLng pickup,
    required LatLng? destination,
    LatLng? secondDestination,
  }) {
    final double googleDistance = getEstimatedTotalDistance();
    if (destination == null) return googleDistance;
    return _tripService.getCappedDistance(
      googleDistance: googleDistance,
      pickup: pickup,
      destination: destination,
      secondDestination: secondDestination,
    );
  }

  /// حساب الوقت الكلي المتوقع
  int getEstimatedTotalDuration() {
    if (estimatedDuration == null) return 0;
    int total = estimatedDuration!;
    if (secondDestinationDuration != null) {
      total += secondDestinationDuration!;
    }
    return total;
  }

  /// حساب السعر التقديري الأساسي للرحلة
  double calculateBasePrice({
    required LatLng pickup,
    required LatLng? destination,
    LatLng? secondDestination,
    String? waitTime,
    bool isRoundTrip = false,
  }) {
    final estimatedDist = getCappedEstimatedTotalDistance(
      pickup: pickup,
      destination: destination,
      secondDestination: secondDestination,
    );
    return _tripService.calculatePrice(
      estimatedDist,
      waitTime: waitTime,
      isRoundTrip: isRoundTrip,
      pickupLocation: pickup,
      destinationLocation: destination,
      secondDestinationLocation: secondDestination,
    );
  }

  /// تفريغ بيانات المسار فقط
  void clearRoute({required VoidCallback onUpdate}) {
    polylinePoints = [];
    distance = null;
    secondDestinationDistance = null;
    estimatedDuration = null;
    secondDestinationDuration = null;
    onUpdate();
  }

  /// إعادة تعيين كامل حالة المسار
  void reset() {
    polylinePoints = [];
    distance = null;
    secondDestinationDistance = null;
    estimatedDuration = null;
    secondDestinationDuration = null;
    isLoadingRoute = false;
  }
}
