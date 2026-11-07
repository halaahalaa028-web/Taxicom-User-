/// خدمة الموقع
/// 
/// توفر خدمات الحصول على الموقع الحالي وإدارة أذونات الـ GPS
/// وتفويض تحويل الإحداثيات إلى خدمة ReverseGeocodingService المركزية
library;

import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'reverse_geocoding_service.dart';

/// فئة خدمة الموقع
class LocationService {
  LocationService._(); // منع إنشاء instance متعددة
  
  static final LocationService _instance = LocationService._();
  
  /// الحصول على instance وحيد
  static LocationService get instance => _instance;
  
  /// هل وضع المطور مفعل (للسماح بالبصرة)
  static bool isDeveloperModeEnabled = false;
  
  /// تحميل حالة وضع المطور
  static Future<void> loadDeveloperMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isDeveloperModeEnabled = prefs.getBool('developer_mode_enabled') ?? false;
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  /// مفتاح حفظ حالة عرض الإفصاح
  static const String _disclosureShownKey = 'location_disclosure_shown';

  /// التحقق من إذن الموقع وطلبه إذا لزم الأمر
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // التحقق من تفعيل خدمة الموقع
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // التحقق من الإذن
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }
  
  /// التحقق مما إذا كان الإفصاح قد عُرض من قبل
  Future<bool> wasDisclosureShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_disclosureShownKey) ?? false;
  }
  
  /// تعيين أن الإفصاح قد عُرض
  Future<void> setDisclosureShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disclosureShownKey, true);
  }
  
  /// التحقق من حالة إذن الموقع الحالية
  Future<LocationPermission> checkPermissionStatus() async {
    return await Geolocator.checkPermission();
  }
  
  /// طلب إذن الموقع
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }
  
  /// فتح إعدادات الموقع في الجهاز
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
  
  /// فتح إعدادات التطبيق
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// الحصول على الموقع الحالي
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// الحصول على الموقع الافتراضي
  Future<Position> getDefaultPosition() async {
    return Position(
      latitude: AppConstants.samawahLat,
      longitude: AppConstants.samawahLng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  /// التحقق مما إذا كان الموقع داخل نطاق الخدمة
  static bool isWithinServiceArea(double latitude, double longitude) {
    return latitude >= 29.0 && latitude <= 37.5 && 
           longitude >= 38.7 && longitude <= 48.6;
  }

  /// تحويل الإحداثيات إلى اسم عنوان (مفوَّض لخدمة العنونة المركزية المؤمنة)
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    return ReverseGeocodingService.instance.getAddressFromCoordinates(latitude, longitude);
  }

  /// حساب المسافة بين نقطتين بالكيلومتر
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    double distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
    return distanceInMeters / 1000;
  }

  /// بث مستمر لتحديثات الموقع (Foreground فقط لتطبيق الراكب)
  Stream<Position> getPositionStream() {
    if (Platform.isIOS) {
      return Geolocator.getPositionStream(
        locationSettings: AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50,
          pauseLocationUpdatesAutomatically: true,
          activityType: ActivityType.automotiveNavigation,
        ),
      );
    }
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    );
  }

  /// بث مستمر لتحديثات الموقع بأعلى دقة (Foreground فقط)
  Stream<Position> getHighAccuracyPositionStream() {
    if (Platform.isIOS) {
      return Geolocator.getPositionStream(
        locationSettings: AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
          pauseLocationUpdatesAutomatically: true,
          activityType: ActivityType.automotiveNavigation,
        ),
      );
    }
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    );
  }
}
