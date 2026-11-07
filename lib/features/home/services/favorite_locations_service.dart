/// خدمة المواقع المفضلة
/// 
/// تدير تخزين واسترجاع المواقع المفضلة للمستخدم
library;

import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نموذج الموقع المفضل
class FavoriteLocation {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final DateTime createdAt;

  FavoriteLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.createdAt,
  });

  /// تحويل إلى Map
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'lat': location.latitude,
    'lng': location.longitude,
    'createdAt': createdAt.toIso8601String(),
  };

  /// إنشاء من Map
  factory FavoriteLocation.fromJson(Map<String, dynamic> json) => FavoriteLocation(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    location: LatLng(json['lat'], json['lng']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// خدمة المواقع المفضلة
class FavoriteLocationsService {
  FavoriteLocationsService._();
  
  /// Instance وحيد من الخدمة
  static final FavoriteLocationsService instance = FavoriteLocationsService._();
  
  /// مفتاح التخزين
  static const String _storageKey = 'favorite_locations';
  
  /// قائمة المواقع المفضلة (cached)
  List<FavoriteLocation> _favorites = [];
  
  /// هل تم تحميل البيانات
  bool _isLoaded = false;

  /// تحميل المواقع المفضلة
  Future<List<FavoriteLocation>> loadFavorites() async {
    if (_isLoaded) return _favorites;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      
      if (data != null) {
        final List<dynamic> jsonList = json.decode(data);
        _favorites = jsonList
            .map((item) => FavoriteLocation.fromJson(item))
            .toList();
      }
      
      _isLoaded = true;
    } catch (e) {
      // في حالة خطأ، نبدأ بقائمة فارغة
      _favorites = [];
      _isLoaded = true;
    }
    
    return _favorites;
  }

  /// الحصول على المواقع المفضلة
  Future<List<FavoriteLocation>> getFavorites() async {
    if (!_isLoaded) {
      await loadFavorites();
    }
    return List.from(_favorites);
  }

  /// إضافة موقع مفضل
  Future<void> addFavorite({
    required String name,
    required String address,
    required LatLng location,
  }) async {
    final favorite = FavoriteLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      address: address,
      location: location,
      createdAt: DateTime.now(),
    );
    
    _favorites.insert(0, favorite); // إضافة في البداية
    await _saveFavorites();
  }

  /// حذف موقع مفضل
  Future<void> removeFavorite(String id) async {
    _favorites.removeWhere((f) => f.id == id);
    await _saveFavorites();
  }

  /// حفظ المواقع المفضلة
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String data = json.encode(
        _favorites.map((f) => f.toJson()).toList(),
      );
      await prefs.setString(_storageKey, data);
    } catch (e) {
      // تجاهل خطأ الحفظ
    }
  }

  /// التحقق مما إذا كان الموقع موجود في المفضلة
  bool isFavorite(LatLng location) {
    return _favorites.any((f) => 
      f.location.latitude == location.latitude && 
      f.location.longitude == location.longitude
    );
  }
}
