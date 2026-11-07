/// أداة مساعدة لحسابات وتنسيقات الرحلات
library;

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/country_service.dart';
import '../../../core/services/pricing_service.dart';

class TripCalculationHelper {
  TripCalculationHelper._();

  /// حساب المسافة بين نقطتين بالكيلومتر بصيغة Haversine
  static double calculateDistanceBetween(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // كم
    double dLat = (lat2 - lat1) * (math.pi / 180);
    double dLng = (lng2 - lng1) * (math.pi / 180);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// الحصول على المسافة المحددة (Capped Distance) بناءً على صيغة Haversine
  static double getCappedDistance({
    required double googleDistance,
    required LatLng pickup,
    required LatLng destination,
    LatLng? secondDestination,
  }) {
    double straightDist = calculateDistanceBetween(
      pickup.latitude,
      pickup.longitude,
      destination.latitude,
      destination.longitude,
    );
    if (secondDestination != null) {
      straightDist += calculateDistanceBetween(
        destination.latitude,
        destination.longitude,
        secondDestination.latitude,
        secondDestination.longitude,
      );
    }
    final double capLimit = math.max(straightDist * 1.5, straightDist + 2.0);
    if (googleDistance > capLimit) {
      debugPrint('⚠️ [Fare Cap Warning] Google Distance ($googleDistance km) exceeded cap ($capLimit km). Straight: $straightDist km.');
      return capLimit;
    }
    return googleDistance;
  }

  /// حساب تكلفة وقت الانتظار
  static double getWaitTimeCost(String waitTime) {
    return PricingService.instance.getWaitTimeCost(waitTime);
  }

  /// حساب سعر الرحلة المتوافق مع دولة المستخدم الحالية وقواعد التسعير الديناميكية
  static double calculatePrice(
    double distanceKm, {
    String? waitTime,
    bool isRoundTrip = false,
    LatLng? pickupLocation,
    LatLng? destinationLocation,
    LatLng? secondDestinationLocation,
  }) {
    double finalDistance = distanceKm;
    if (pickupLocation != null && destinationLocation != null) {
      finalDistance = getCappedDistance(
        googleDistance: distanceKm,
        pickup: pickupLocation,
        destination: destinationLocation,
        secondDestination: secondDestinationLocation,
      );
    }

    return PricingService.instance.calculatePrice(
      finalDistance,
      waitTime: waitTime,
      isRoundTrip: isRoundTrip,
    );
  }

  /// تنسيق السعر للعرض مع فواصل الآلاف والعملة المناسبة
  static String formatPrice(
    double price, {
    String? currency,
    String? countryCode,
    bool includeCurrency = false,
  }) {
    String effectiveCurrency = '';
    if (includeCurrency) {
      if (currency != null && currency.isNotEmpty) {
        effectiveCurrency = currency;
      } else if (countryCode != null && countryCode.isNotEmpty) {
        effectiveCurrency = CountryService.instance.getCountryByCode(countryCode).currencyAr;
      } else {
        effectiveCurrency = CountryService.instance.selectedCountry.currencyAr;
      }
    }

    final step = CountryService.instance.selectedCountry.roundingStep;
    String formattedNum;
    if (step < 0.1) {
      formattedNum = price.toStringAsFixed(2);
    } else if (step < 1) {
      final str = price.toStringAsFixed(1);
      formattedNum = str.endsWith('.0') ? str.substring(0, str.length - 2) : str;
    } else {
      final intVal = price.round();
      final formatted = intVal.toString();
      final buffer = StringBuffer();
      int count = 0;
      for (int i = formatted.length - 1; i >= 0; i--) {
        if (count > 0 && count % 3 == 0) {
          buffer.write(',');
        }
        buffer.write(formatted[i]);
        count++;
      }
      formattedNum = buffer.toString().split('').reversed.join('');
    }

    if (!includeCurrency || effectiveCurrency.isEmpty) {
      return formattedNum;
    }

    return '$formattedNum $effectiveCurrency';
  }

  /// تنسيق المسافة للعرض
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} م';
    } else {
      return '${distanceKm.toStringAsFixed(1)} كم';
    }
  }
}
