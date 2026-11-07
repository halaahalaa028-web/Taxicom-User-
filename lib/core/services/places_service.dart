/// خدمة البحث عن الأماكن عبر دوال Firebase السحابية الوسيطة
/// 
/// تستخدم دالتي searchPlaces و getPlaceDetails في Cloud Functions لعزل المفاتيح وتفعيل الكاش
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';
import 'country_service.dart';

/// نموذج اقتراح المكان
class PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;

  PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
  });

  factory PlaceSuggestion.fromJson(Map<dynamic, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] as Map<dynamic, dynamic>? ?? {};
    return PlaceSuggestion(
      placeId: (json['place_id'] as String?) ?? '',
      mainText: (structuredFormatting['main_text'] as String?) ?? (json['description'] as String?) ?? '',
      secondaryText: (structuredFormatting['secondary_text'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
    );
  }
}

/// نموذج تفاصيل المكان
class PlaceDetails {
  final String placeId;
  final String name;
  final String address;
  final LatLng location;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.address,
    required this.location,
  });

  factory PlaceDetails.fromJson(Map<dynamic, dynamic> json) {
    final result = json['result'] as Map<dynamic, dynamic>? ?? {};
    final geometry = result['geometry'] as Map<dynamic, dynamic>? ?? {};
    final location = geometry['location'] as Map<dynamic, dynamic>? ?? {};
    
    return PlaceDetails(
      placeId: (result['place_id'] as String?) ?? '',
      name: (result['name'] as String?) ?? '',
      address: (result['formatted_address'] as String?) ?? '',
      location: LatLng(
        ((location['lat'] as num?) ?? 0).toDouble(),
        ((location['lng'] as num?) ?? 0).toDouble(),
      ),
    );
  }
}

/// خدمة البحث عن الأماكن باستخدام Google Places عبر الدالة السحابية الوسيطة
class PlacesService {
  PlacesService._();
  
  static final PlacesService _instance = PlacesService._();
  
  /// الحصول على instance وحيد
  static PlacesService get instance => _instance;
  
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// البحث عن أماكن
  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    LatLng? location,
    int radius = 200000,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final callable = _functions.httpsCallable(
        'searchPlaces',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
      );

      final double lat = location?.latitude ?? ((AppConstants.samawahLat + AppConstants.baghdadLat) / 2);
      final double lng = location?.longitude ?? ((AppConstants.samawahLng + AppConstants.baghdadLng) / 2);

      final response = await callable.call<Map<dynamic, dynamic>>({
        'query': query.trim(),
        'latitude': lat,
        'longitude': lng,
        'radius': radius,
        'language': 'ar',
        'region': CountryService.instance.selectedCountry.code.toLowerCase(),
      });

      final data = response.data;
      final status = (data['status'] as String?) ?? 'UNKNOWN';

      if (status == 'OK') {
        final predictions = (data['predictions'] as List?) ?? [];
        return predictions
            .map((p) => PlaceSuggestion.fromJson(p as Map<dynamic, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ PlacesService: Exception = $e');
      return [];
    }
  }

  /// الحصول على تفاصيل المكان
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (placeId.trim().isEmpty) {
      return null;
    }

    try {
      final callable = _functions.httpsCallable(
        'getPlaceDetails',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
      );

      final response = await callable.call<Map<dynamic, dynamic>>({
        'placeId': placeId.trim(),
        'language': 'ar',
      });

      final data = response.data;
      final status = (data['status'] as String?) ?? 'UNKNOWN';

      if (status == 'OK') {
        return PlaceDetails.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('❌ PlacesService: getPlaceDetails Exception = $e');
      return null;
    }
  }
}
