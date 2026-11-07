/// خدمة طلبات الرحلات
/// 
/// توفر وظائف التعامل مع طلبات الرحلات في Firestore للراكب
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/trip_request_model.dart';
import '../utils/trip_calculation_helper.dart';
import '../../../core/services/country_service.dart';

/// خدمة طلبات الرحلات للراكب
class TripRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  TripRequestService._();
  static final TripRequestService _instance = TripRequestService._();
  static TripRequestService get instance => _instance;

  CollectionReference get _tripsCollection =>
      _firestore.collection(AppConstants.tripsCollection);

  /// حساب السعر التقديري
  double calculatePrice(
    double distanceKm, {
    String? waitTime,
    bool isRoundTrip = false,
    LatLng? pickupLocation,
    LatLng? destinationLocation,
    LatLng? secondDestinationLocation,
  }) => TripCalculationHelper.calculatePrice(
    distanceKm,
    waitTime: waitTime,
    isRoundTrip: isRoundTrip,
    pickupLocation: pickupLocation,
    destinationLocation: destinationLocation,
    secondDestinationLocation: secondDestinationLocation,
  );

  /// الحصول على المسافة المحددة (Capped Distance)
  double getCappedDistance({
    required double googleDistance,
    required LatLng pickup,
    required LatLng destination,
    LatLng? secondDestination,
  }) => TripCalculationHelper.getCappedDistance(
    googleDistance: googleDistance,
    pickup: pickup,
    destination: destination,
    secondDestination: secondDestination,
  );

  /// الحصول على طلب الانتظار الحالي للمستخدم لنوع معين من الرحلات
  Future<TripRequestModel?> getPendingTripForUser({TripType tripType = TripType.ride}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    final snapshot = await _tripsCollection
        .where('passengerId', isEqualTo: user.uid)
        .where('status', isEqualTo: TripStatus.pending.name)
        .where('tripType', isEqualTo: tripType.name)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return TripRequestModel.fromMap(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
  }

  Future<bool> hasPendingTrip({TripType tripType = TripType.ride}) async {
    final trip = await getPendingTripForUser(tripType: tripType);
    return trip != null;
  }

  /// الحصول على الرحلة النشطة للراكب
  Future<TripRequestModel?> getActiveTripForPassenger() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    final snapshot = await _tripsCollection
        .where('passengerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final statusStr = data['status'] as String?;
      if (statusStr != TripStatus.completed.name &&
          statusStr != TripStatus.cancelled.name &&
          statusStr != TripStatus.cancelledByDriver.name) {
        return TripRequestModel.fromMap(data, doc.id);
      }
    }
    return null;
  }

  /// الاستماع للرحلة النشطة للراكب في الوقت الفعلي
  Stream<TripRequestModel?> watchPassengerActiveTrip() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _tripsCollection
        .where('passengerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final statusStr = data['status'] as String?;
        if (statusStr != TripStatus.completed.name &&
            statusStr != TripStatus.cancelled.name &&
            statusStr != TripStatus.cancelledByDriver.name) {
          return TripRequestModel.fromMap(data, doc.id);
        }
      }
      return null;
    });
  }

  /// الحصول على جميع رحلات المستخدم
  Future<List<TripRequestModel>> getUserTrips() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    
    final snapshot = await _tripsCollection
        .where('passengerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    
    return snapshot.docs.map((doc) => TripRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  /// الحصول على إحصائيات أعداد رحلات الراكب
  Future<Map<String, int>> getPassengerTripsCounts(String passengerId) async {
    try {
      final allQuery = _tripsCollection.where('passengerId', isEqualTo: passengerId);
      final completedQuery = allQuery.where('status', isEqualTo: TripStatus.completed.name);
      final cancelledQuery = allQuery.where('status', whereIn: [TripStatus.cancelled.name, TripStatus.cancelledByDriver.name]);

      final results = await Future.wait([
        allQuery.count().get(),
        completedQuery.count().get(),
        cancelledQuery.count().get(),
      ]);

      return {
        'all': results[0].count ?? 0,
        'completed': results[1].count ?? 0,
        'cancelled': results[2].count ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting passenger trips counts: $e');
      return {'all': 0, 'completed': 0, 'cancelled': 0};
    }
  }

  /// الحصول على سجل رحلات الراكب مع التصفح (Pagination)
  Future<List<DocumentSnapshot>> getPassengerTripsHistory({
    required String passengerId,
    String? statusFilter,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _tripsCollection.where('passengerId', isEqualTo: passengerId);

    if (statusFilter == 'completed') {
      query = query.where('status', isEqualTo: TripStatus.completed.name);
    } else if (statusFilter == 'cancelled') {
      query = query.where('status', whereIn: [TripStatus.cancelled.name, TripStatus.cancelledByDriver.name]);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final QuerySnapshot snapshot = await query.get();
    return snapshot.docs;
  }

  /// إنشاء طلب رحلة جديد
  Future<String> createTripRequest({
    required String passengerName,
    required String passengerPhone,
    required LatLng pickupLocation,
    required String pickupAddress,
    required LatLng destinationLocation,
    required String destinationAddress,
    required double distance,
    int? estimatedDuration,
    TripType tripType = TripType.ride,
    String? receiverName,
    String? receiverPhone,
    String? packageDescription,
    bool paidByReceiver = false,
    LatLng? secondDestinationLocation,
    String? secondDestinationAddress,
    String? waitTime,
    bool isRoundTrip = false,
    double? customPrice,
    DateTime? scheduledDate,
    String? scheduledTime,
    int? numberOfPassengers,
    String? bookingNote,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? couponCode,
    String? couponId,
    double? discountAmount,
    double? originalPrice,
    String paymentMethod = 'cash',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

    final existingTrip = await getPendingTripForUser(tripType: tripType);
    if (existingTrip != null) {
      throw Exception('لديك طلب معلق بالفعل. يرجى إلغاؤه أولاً.');
    }

    final finalDistance = getCappedDistance(
      googleDistance: distance,
      pickup: pickupLocation,
      destination: destinationLocation,
      secondDestination: secondDestinationLocation,
    );

    final price = customPrice ?? calculatePrice(
      finalDistance, 
      waitTime: waitTime,
      isRoundTrip: isRoundTrip,
      pickupLocation: pickupLocation,
      destinationLocation: destinationLocation,
      secondDestinationLocation: secondDestinationLocation,
    );
    
    final startOtp = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();

    final docRef = await _tripsCollection.add({
      'passengerId': user.uid,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'pickupLat': pickupLocation.latitude,
      'pickupLng': pickupLocation.longitude,
      'pickupAddress': pickupAddress,
      'destinationLat': destinationLocation.latitude,
      'destinationLng': destinationLocation.longitude,
      'destinationAddress': destinationAddress,
      if (secondDestinationLocation != null) ...{
        'secondDestinationLat': secondDestinationLocation.latitude,
        'secondDestinationLng': secondDestinationLocation.longitude,
      },
      if (secondDestinationAddress != null) 'secondDestinationAddress': secondDestinationAddress,
      if (waitTime != null) 'waitTime': waitTime,
      'isRoundTrip': isRoundTrip,
      'distance': finalDistance,
      if (estimatedDuration != null) 'estimatedDuration': estimatedDuration,
      'price': price,
      if (couponCode != null) 'couponCode': couponCode,
      if (couponId != null) 'couponId': couponId,
      if (discountAmount != null) 'discountAmount': discountAmount,
      if (originalPrice != null) 'originalPrice': originalPrice,
      'tripType': tripType.name,
      'status': TripStatus.pending.name,
      'startOtp': startOtp,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      if (scheduledDate != null) 'scheduledDate': Timestamp.fromDate(scheduledDate),
      if (scheduledTime != null) 'scheduledTime': scheduledTime,
      if (numberOfPassengers != null) 'numberOfPassengers': numberOfPassengers,
      if (bookingNote != null) 'bookingNote': bookingNote,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (receiverName != null) 'receiverName': receiverName,
      if (receiverPhone != null) 'receiverPhone': receiverPhone,
      if (packageDescription != null) 'packageDescription': packageDescription,
      'paidByReceiver': paidByReceiver,
      'paymentMethod': paymentMethod,
      'currentRadius': AppConstants.initialSearchRadiusKm,
      'countryCode': CountryService.instance.selectedCountry.code,
      'currency': CountryService.instance.selectedCountry.currencyAr,
      'currencyCode': CountryService.instance.selectedCountry.currencyCode,
    });

    return docRef.id;
  }

  /// تحديث نصف قطر البحث الديناميكي للرحلة
  Future<void> updateTripSearchRadius(String tripId, double radiusKm) async {
    try {
      await _tripsCollection.doc(tripId).update({
        'currentRadius': radiusKm,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating trip search radius: $e');
    }
  }

  /// إلغاء الطلب تلقائياً لانتهاء المهلة
  Future<void> cancelTripDueToTimeout(String tripId) async {
    await cancelTrip(tripId, cancellationReason: 'timeout_no_drivers_found');
  }

  /// الاستماع لحالة طلب معين
  Stream<TripRequestModel?> watchTripRequest(String tripId) {
    return _tripsCollection.doc(tripId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return TripRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  /// إلغاء طلب من الراكب
  Future<void> cancelTrip(String tripId, {String? cancellationReason}) async {
    await _tripsCollection.doc(tripId).update({
      'status': TripStatus.cancelled.name,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      if (cancellationReason != null) 'cancelledByPassengerAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// إكمال رحلة؛ تسوية الكوبون المالية تتم حصراً في Cloud Functions.
  Future<void> completeTrip(String tripId) async {
    await _tripsCollection.doc(tripId).update({
      'status': TripStatus.completed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// حفظ تقييم الراكب للرحلة
  Future<void> submitPassengerRating({
    required String tripId,
    required int rating,
    String? note,
  }) async {
    await _tripsCollection.doc(tripId).update({
      'passengerRating': rating,
      'passengerNote': note,
      'passengerRatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// دوال مساعدة موجهة لـ TripCalculationHelper
  double calculateDistanceBetween(double lat1, double lng1, double lat2, double lng2) =>
      TripCalculationHelper.calculateDistanceBetween(lat1, lng1, lat2, lng2);

  String formatPrice(double price) => TripCalculationHelper.formatPrice(price);

  String formatDistance(double distanceKm) => TripCalculationHelper.formatDistance(distanceKm);
}
