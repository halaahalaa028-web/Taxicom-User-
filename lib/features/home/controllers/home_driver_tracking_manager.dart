import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/driver_tracking_service.dart';

/// مدير تتبع السائق (Driver Tracking Manager)
///
/// مسؤول عن:
/// - الاستماع لتحديثات موقع السائق اللحظية عبر Firebase Realtime Database
/// - تطبيق أنيميشن سلس لحركة السائق (Lat/Lng Tweens) وتحديث اتجاه السيارة (Heading)
/// - حساب زاوية اتجاه السائق بالنسبة لكاميرا المستخدم (Angle to Driver)
/// - التحقق من وجود السائق ضمن النطاق المرئي للشاشة (Driver Visibility Bounds)
class HomeDriverTrackingManager {
  final DriverTrackingService _driverTrackingService = DriverTrackingService.instance;

  LatLng? driverLocation;
  double driverHeading = 0.0;
  bool isDriverVisible = true;

  StreamSubscription? _driverLocationSubscription;
  AnimationController? driverAnimationController;
  Animation<double>? _latAnimation;
  Animation<double>? _lngAnimation;

  // السائقون القريبون المتاحون
  Map<String, DriverLocation> nearbyDrivers = {};
  StreamSubscription? _nearbyDriversSubscription;

  /// التحقق مما إذا كان تتبع السائق جارياً حالياً
  bool get isTracking => _driverLocationSubscription != null;

  /// التحقق مما إذا كان الاستماع للسائقين القريبين نشطاً
  bool get isWatchingNearbyDrivers => _nearbyDriversSubscription != null;

  /// بدء الاستماع لجميع السائقين القريبين المتاحين
  void startWatchingNearbyDrivers({
    required LatLng centerLocation,
    required VoidCallback onUpdate,
    double radiusKm = 15.0,
  }) {
    stopWatchingNearbyDrivers();

    _nearbyDriversSubscription = _driverTrackingService
        .watchNearbyDrivers(centerLocation: centerLocation, radiusKm: radiusKm)
        .listen((drivers) {
      nearbyDrivers = drivers;
      onUpdate();
    });
  }

  /// إيقاف الاستماع للسائقين القريبين
  void stopWatchingNearbyDrivers() {
    _nearbyDriversSubscription?.cancel();
    _nearbyDriversSubscription = null;
    nearbyDrivers.clear();
  }

  /// بدء تتبع موقع السائق
  void startTracking({
    required String driverId,
    required TickerProvider vsync,
    required VoidCallback onUpdate,
    required GoogleMapController? Function() getMapController,
  }) {
    stopTracking();

    driverAnimationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1500),
    );

    driverAnimationController!.addListener(() {
      if (_latAnimation != null && _lngAnimation != null) {
        driverLocation = LatLng(
          _latAnimation!.value,
          _lngAnimation!.value,
        );
        onUpdate();
      }
    });

    _driverLocationSubscription = _driverTrackingService
        .watchDriverLocation(driverId)
        .listen((location) {
      if (location != null) {
        animateDriverToNewPosition(
          newLocation: location,
          onUpdate: onUpdate,
          getMapController: getMapController,
        );
      }
    });
  }

  /// تحريك السائق بنعومة إلى الإحداثيات والاتجاه الجديدين
  void animateDriverToNewPosition({
    required DriverLocation newLocation,
    required VoidCallback onUpdate,
    required GoogleMapController? Function() getMapController,
  }) {
    final oldLocation = driverLocation ?? newLocation.latLng;
    driverHeading = newLocation.heading;

    if (driverAnimationController != null) {
      _latAnimation = Tween<double>(
        begin: oldLocation.latitude,
        end: newLocation.lat,
      ).animate(CurvedAnimation(
        parent: driverAnimationController!,
        curve: Curves.easeInOut,
      ));

      _lngAnimation = Tween<double>(
        begin: oldLocation.longitude,
        end: newLocation.lng,
      ).animate(CurvedAnimation(
        parent: driverAnimationController!,
        curve: Curves.easeInOut,
      ));

      driverAnimationController!.forward(from: 0);
    } else {
      driverLocation = newLocation.latLng;
    }

    onUpdate();
    followDriverIfNeeded(
      driverPosition: newLocation.latLng,
      getMapController: getMapController,
      onUpdate: onUpdate,
    );
  }

  /// التحقق من ظهور السائق على الخريطة
  Future<void> followDriverIfNeeded({
    required LatLng driverPosition,
    required GoogleMapController? Function() getMapController,
    required VoidCallback onUpdate,
  }) async {
    final mapController = getMapController();
    if (mapController == null) return;

    try {
      final bounds = await mapController.getVisibleRegion();
      final isInBounds = driverPosition.latitude >= bounds.southwest.latitude &&
          driverPosition.latitude <= bounds.northeast.latitude &&
          driverPosition.longitude >= bounds.southwest.longitude &&
          driverPosition.longitude <= bounds.northeast.longitude;

      if (isDriverVisible != isInBounds) {
        isDriverVisible = isInBounds;
        onUpdate();
      }
    } catch (e) {
      debugPrint('Error checking driver visibility: $e');
    }
  }

  /// حساب زاوية السائق بالنسبة لموقع الراكب وزاوية الكاميرا
  double getAngleToDriver({
    required LatLng userLocation,
    required double cameraBearing,
  }) {
    if (driverLocation == null) return 0;
    final bearing = Geolocator.bearingBetween(
      userLocation.latitude,
      userLocation.longitude,
      driverLocation!.latitude,
      driverLocation!.longitude,
    );
    return bearing - cameraBearing;
  }

  /// إيقاف التتبع والتخلص من المتحكمات الفرعية
  void stopTracking() {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = null;
    driverAnimationController?.dispose();
    driverAnimationController = null;
    _latAnimation = null;
    _lngAnimation = null;
  }

  /// إعادة تعيين بيانات السائق
  void reset() {
    stopTracking();
    stopWatchingNearbyDrivers();
    driverLocation = null;
    driverHeading = 0.0;
    isDriverVisible = true;
  }

  /// التخلص النهائي
  void dispose() {
    stopTracking();
    stopWatchingNearbyDrivers();
  }
}
