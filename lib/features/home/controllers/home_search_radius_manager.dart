/// مدير نطاق البحث الديناميكي وموجات الرادار والمهلة الزمنية
///
/// يدير استراتيجية إرسال الموجات الحلقية المتوسعة (Ripple Dispatch)
/// وتحديث نصف قطر البحث تدريجياً وإلغاء الطلب تلقائياً عند انتهاء المهلة
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../trips/services/trip_request_service.dart';

class HomeSearchRadiusManager {
  final TripRequestService _tripService = TripRequestService.instance;

  double _currentSearchRadiusKm = AppConstants.initialSearchRadiusKm;
  bool _isSearching = false;
  int _searchElapsedSeconds = 0;

  Timer? _tickerTimer;
  VoidCallback? _onUpdate;
  VoidCallback? _onTimeout;
  String? _activeTripId;

  double get currentSearchRadiusKm => _currentSearchRadiusKm;
  double get currentSearchRadiusMeters => _currentSearchRadiusKm * 1000.0;
  bool get isSearching => _isSearching;
  int get searchElapsedSeconds => _searchElapsedSeconds;

  /// الوصف النصي المرحلي لنطاق البحث الحالي
  String get searchStageDescription {
    if (_currentSearchRadiusKm <= AppConstants.initialSearchRadiusKm) {
      return 'جاري البحث عن أقرب سائق في محيط (2 كم)...';
    } else if (_currentSearchRadiusKm <= AppConstants.mediumSearchRadiusKm) {
      return 'توسيع نطاق البحث إلى (5 كم)...';
    } else if (_currentSearchRadiusKm <= AppConstants.wideSearchRadiusKm) {
      return 'توسيع نطاق البحث إلى (8 كم)...';
    } else {
      return 'توسيع نطاق البحث إلى الحد الأقصى (10 كم)...';
    }
  }

  /// نسبة تقدم مهلة البحث (من 0.0 إلى 1.0)
  double get searchProgress {
    const totalSeconds = AppConstants.tripSearchTimeoutMinutes * 60;
    return (_searchElapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  /// بدء تتبع مراحل البحث الزمني للرحلة بناءً على تاريخ إنشائها في السيرفر
  void startSearch({
    required String tripId,
    DateTime? createdAt,
    double? initialRadius,
    required VoidCallback onUpdate,
    required VoidCallback onTimeout,
  }) {
    stopSearch();

    _activeTripId = tripId;
    _onUpdate = onUpdate;
    _onTimeout = onTimeout;
    _isSearching = true;

    // حساب الثواني المنقضية بدقة من تاريخ إنشاء الرحلة (createdAt)
    final now = DateTime.now();
    int initialElapsedSeconds = 0;
    if (createdAt != null) {
      initialElapsedSeconds = now.difference(createdAt).inSeconds;
      if (initialElapsedSeconds < 0) initialElapsedSeconds = 0;
    }

    _searchElapsedSeconds = initialElapsedSeconds;

    const totalTimeoutSeconds = AppConstants.tripSearchTimeoutMinutes * 60;

    // فحص ما إذا كانت المهلة قد انقضت بالفعل أثناء إغلاق التطبيق
    if (_searchElapsedSeconds >= totalTimeoutSeconds) {
      _handleTimeout();
      return;
    }

    // حساب نصف القطر المناسب لحظياً بناءً على الوقت المنقضي
    if (_searchElapsedSeconds >= 120) {
      _currentSearchRadiusKm = AppConstants.maxSearchRadiusKm;
    } else if (_searchElapsedSeconds >= 60) {
      _currentSearchRadiusKm = AppConstants.wideSearchRadiusKm;
    } else if (_searchElapsedSeconds >= 30) {
      _currentSearchRadiusKm = AppConstants.mediumSearchRadiusKm;
    } else {
      _currentSearchRadiusKm = initialRadius ?? AppConstants.initialSearchRadiusKm;
    }

    _onUpdate?.call();

    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isSearching) {
        timer.cancel();
        return;
      }

      _searchElapsedSeconds++;

      // المرحلة 2: بعد 30 ثانية -> التوسع إلى 5 كم
      if (_searchElapsedSeconds >= 30 && _currentSearchRadiusKm < AppConstants.mediumSearchRadiusKm) {
        _currentSearchRadiusKm = AppConstants.mediumSearchRadiusKm;
        _updateTripRadiusInFirestore(_currentSearchRadiusKm);
      }
      // المرحلة 3: بعد 60 ثانية -> التوسع إلى 8 كم
      else if (_searchElapsedSeconds >= 60 && _currentSearchRadiusKm < AppConstants.wideSearchRadiusKm) {
        _currentSearchRadiusKm = AppConstants.wideSearchRadiusKm;
        _updateTripRadiusInFirestore(_currentSearchRadiusKm);
      }
      // المرحلة 4: بعد 120 ثانية (دقيقتين) -> التوسع إلى 10 كم (الحد الأقصى)
      else if (_searchElapsedSeconds >= 120 && _currentSearchRadiusKm < AppConstants.maxSearchRadiusKm) {
        _currentSearchRadiusKm = AppConstants.maxSearchRadiusKm;
        _updateTripRadiusInFirestore(_currentSearchRadiusKm);
      }

      _onUpdate?.call();

      // انتهاء المهلة القصوى (Timeout)
      if (_searchElapsedSeconds >= totalTimeoutSeconds) {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _updateTripRadiusInFirestore(double radiusKm) {
    if (_activeTripId != null) {
      _tripService.updateTripSearchRadius(_activeTripId!, radiusKm);
    }
  }

  Future<void> _handleTimeout() async {
    final tripId = _activeTripId;
    stopSearch();
    if (tripId != null) {
      await _tripService.cancelTripDueToTimeout(tripId);
    }
    _onTimeout?.call();
  }

  /// إيقاف البحث (عند قبول الطلب أو إلغائه يدوياً)
  void stopSearch() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
    _isSearching = false;
    _activeTripId = null;
  }

  /// إعادة ضبط الحالة
  void reset() {
    stopSearch();
    _currentSearchRadiusKm = AppConstants.initialSearchRadiusKm;
    _searchElapsedSeconds = 0;
  }

  void dispose() {
    stopSearch();
  }
}
