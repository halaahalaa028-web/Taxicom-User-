/// خدمة تتبع موقع السائق
/// 
/// تستخدم Firebase Realtime Database للاستماع لموقع السائق لحظياً
library;

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';

/// نموذج موقع السائق
class DriverLocation {
  /// معرف السائق
  final String? driverId;

  /// خط العرض
  final double lat;
  
  /// خط الطول
  final double lng;
  
  /// اتجاه السيارة (بالدرجات)
  final double heading;
  
  /// سرعة السائق (متر/ثانية)
  final double speed;
  
  /// دقة الموقع (بالمتر)
  final double accuracy;
  
  /// الموقع كـ LatLng
  LatLng get latLng => LatLng(lat, lng);

  DriverLocation({
    this.driverId,
    required this.lat,
    required this.lng,
    this.heading = 0.0,
    this.speed = 0.0,
    this.accuracy = 0.0,
  });

  /// إنشاء من Map
  factory DriverLocation.fromMap(Map<dynamic, dynamic> map, {String? driverId}) {
    double lat = 0.0;
    double lng = 0.0;

    if (map['lat'] != null && map['lng'] != null) {
      lat = (map['lat'] as num?)?.toDouble() ?? 0.0;
      lng = (map['lng'] as num?)?.toDouble() ?? 0.0;
    } else if (map['l'] != null) {
      final lField = map['l'];
      if (lField is List && lField.length >= 2) {
        lat = (lField[0] as num?)?.toDouble() ?? 0.0;
        lng = (lField[1] as num?)?.toDouble() ?? 0.0;
      }
    }

    final headingVal = map['h'] ?? map['heading'] ?? 0.0;
    final speedVal = map['s'] ?? map['speed'] ?? 0.0;
    final accuracyVal = map['a'] ?? map['accuracy'] ?? 0.0;

    return DriverLocation(
      driverId: driverId,
      lat: lat,
      lng: lng,
      heading: (headingVal as num?)?.toDouble() ?? 0.0,
      speed: (speedVal as num?)?.toDouble() ?? 0.0,
      accuracy: (accuracyVal as num?)?.toDouble() ?? 0.0,
    );
  }
  
  @override
  String toString() => 'DriverLocation(driverId: $driverId, lat: $lat, lng: $lng, heading: $heading, speed: $speed, accuracy: $accuracy)';
}

/// خدمة تتبع السائق
class DriverTrackingService {
  /// Singleton instance
  static final DriverTrackingService instance = DriverTrackingService._();
  
  DriverTrackingService._();
  
  /// رابط قاعدة البيانات (europe-west1)
  static const String _databaseUrl = AppConstants.realtimeDatabaseUrl;
  
  /// مرجع قاعدة البيانات
  late final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: _databaseUrl,
  ).ref();
  
  /// الاستماع لموقع السائق
  /// 
  /// [driverId] معرف السائق
  /// يعيد Stream من مواقع السائق المحدثة
  Stream<DriverLocation?> watchDriverLocation(String driverId) {
    return _database
        .child('drivers_locations')
        .child(driverId)
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data == null) return null;
          
          if (data is Map) {
            return DriverLocation.fromMap(data, driverId: driverId);
          }
          return null;
        });
  }

  /// الاستماع لجميع السائقين القريبين من موقع محدد
  ///
  /// [centerLocation] الموقع المركزي (عادة نقطة الانطلاق)
  /// [radiusKm] نصف قطر البحث بالكيلومتر (افتراضياً 15 كم)
  Stream<Map<String, DriverLocation>> watchNearbyDrivers({
    required LatLng centerLocation,
    double radiusKm = 15.0,
  }) {
    return _database.child('drivers_locations').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return <String, DriverLocation>{};

      final Map<String, DriverLocation> nearbyDrivers = {};

      data.forEach((key, value) {
        if (value is Map) {
          final driverId = key.toString();
          final location = DriverLocation.fromMap(value, driverId: driverId);

          if (location.lat != 0.0 && location.lng != 0.0) {
            final distanceMeters = Geolocator.distanceBetween(
              centerLocation.latitude,
              centerLocation.longitude,
              location.lat,
              location.lng,
            );

            if (distanceMeters <= radiusKm * 1000) {
              nearbyDrivers[driverId] = location;
            }
          }
        }
      });

      return nearbyDrivers;
    }).handleError((error) {
      return <String, DriverLocation>{};
    });
  }
  
  /// الحصول على موقع السائق مرة واحدة
  Future<DriverLocation?> getDriverLocation(String driverId) async {
    final snapshot = await _database
        .child('drivers_locations')
        .child(driverId)
        .get();
    
    if (!snapshot.exists || snapshot.value == null) return null;
    
    final data = snapshot.value;
    if (data is Map) {
      return DriverLocation.fromMap(data, driverId: driverId);
    }
    return null;
  }
}
