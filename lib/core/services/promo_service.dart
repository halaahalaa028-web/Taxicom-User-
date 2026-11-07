import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/profile/models/coupon_model.dart';

class PromoValidationResult {
  final bool isValid;
  final double discountAmount;
  final String? errorMessage;

  PromoValidationResult({
    required this.isValid,
    required this.discountAmount,
    this.errorMessage,
  });
}

/// خدمة إدارة والتحقق من كوبونات الخصم والمكافآت الموحدة
class PromoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PromoService._();
  static final PromoService _instance = PromoService._();
  static PromoService get instance => _instance;

  /// جلب تدفق الكوبونات والمكافآت المتاحة للمستخدم (العامة + المخصصة له) مع استبعاد الكوبونات المستنفدة للمستخدم
  Stream<List<CouponModel>> getUserAvailableCouponsStream({
    required String userPhone,
    String? userId,
  }) {
    final publicStream = _firestore
        .collection('coupons')
        .where('isTargeted', isEqualTo: false)
        .snapshots();
    final targetedStream = userId == null || userId.isEmpty
        ? const Stream<QuerySnapshot<Map<String, dynamic>>>.empty()
        : _firestore.collection('coupons')
            .where('assignedUserIds', arrayContains: userId)
            .snapshots();
    final controller = StreamController<List<CouponModel>>();
    QuerySnapshot<Map<String, dynamic>>? publicSnapshot;
    QuerySnapshot<Map<String, dynamic>>? targetedSnapshot;

    Future<void> emitCoupons() async {
      final docs = [
        ...?publicSnapshot?.docs,
        ...?targetedSnapshot?.docs,
      ];
      final now = DateTime.now();
      final List<CouponModel> list = [];

      Map<String, int> userUsages = {};
      if (userId != null && userId.isNotEmpty) {
        try {
          final usedSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('used_coupons')
              .get();
          for (var doc in usedSnapshot.docs) {
            userUsages[doc.id] = (doc.data()['count'] as num?)?.toInt() ?? 0;
          }
        } catch (_) {}
      }

      for (final doc in docs) {
        final coupon = CouponModel.fromMap(doc.data(), doc.id);
        final bool isExpired = coupon.expiryDate.isBefore(now);
        final bool isTotalLimitReached = coupon.usageLimit != null && coupon.usedCount >= coupon.usageLimit!;
        final bool isValidUser = coupon.isValidForUser(userId ?? '');

        final int userUsedCount = userUsages[coupon.id] ?? 0;
        final int allowedPerUser = coupon.usageLimitPerUser ?? 1;
        final bool isUserLimitReached = userUsedCount >= allowedPerUser;

        if (coupon.isActive && !isExpired && !isTotalLimitReached && isValidUser && !isUserLimitReached) {
          list.add(coupon);
        }
      }

      list.sort((a, b) {
        // نضع الكوبونات المخصصة/الهدايا في المقدمة أولاً
        if (a.hasTargetAudience && !b.hasTargetAudience) return -1;
        if (!a.hasTargetAudience && b.hasTargetAudience) return 1;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      if (!controller.isClosed) controller.add(list);
    }

    final subscriptions = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[
      publicStream.listen((snapshot) { publicSnapshot = snapshot; emitCoupons(); }, onError: controller.addError),
      targetedStream.listen((snapshot) { targetedSnapshot = snapshot; emitCoupons(); }, onError: controller.addError),
    ];
    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
    return controller.stream;
  }

  /// الحصول على عدد مرات استخدام المستخدم لكوبون معين
  Future<int> getUserCouponUsageCount({
    required String userId,
    required String couponId,
  }) async {
    if (userId.isEmpty || couponId.isEmpty) return 0;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('used_coupons')
          .doc(couponId)
          .get();
      if (doc.exists && doc.data() != null) {
        return (doc.data()!['count'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// جلب كوبون معين بالرمز (Code)
  Future<CouponModel?> getCouponByCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: code.toUpperCase().trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return CouponModel.fromMap(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      return null;
    }
  }

  /// التحقق من صلاحية الكوبون وحساب قيمة الخصم بدقة مع مراعاة حد الاستخدام لكل مستخدم
  Future<PromoValidationResult> validateCouponAsync({
    required CouponModel? coupon,
    required double tripPrice,
    required String userPhone,
    String? userId,
  }) async {
    if (coupon == null) {
      return PromoValidationResult(isValid: false, discountAmount: 0.0, errorMessage: 'promoInvalid');
    }

    if (coupon.isExpired) {
      return PromoValidationResult(isValid: false, discountAmount: 0.0, errorMessage: 'promoInvalid');
    }

    if (coupon.isLimitReached) {
      return PromoValidationResult(isValid: false, discountAmount: 0.0, errorMessage: 'promoLimitReached');
    }

    if (!coupon.isValidForUser(userId ?? '')) {
      return PromoValidationResult(isValid: false, discountAmount: 0.0, errorMessage: 'promoInvalid');
    }

    // التحقق من حد الاستخدام للمستخدم الحالي
    if (userId != null && userId.isNotEmpty) {
      final usageCount = await getUserCouponUsageCount(userId: userId, couponId: coupon.id);
      final allowedPerUser = coupon.usageLimitPerUser ?? 1;
      if (usageCount >= allowedPerUser) {
        return PromoValidationResult(
          isValid: false,
          discountAmount: 0.0,
          errorMessage: 'promoLimitReached',
        );
      }
    }

    double discount = 0.0;
    if (coupon.isFreeRide) {
      discount = tripPrice;
    } else {
      discount = tripPrice * (coupon.discountValue / 100.0);
    }

    if (discount > tripPrice) {
      discount = tripPrice;
    }

    return PromoValidationResult(
      isValid: true,
      discountAmount: discount,
    );
  }

  /// دالة التحقق المتزامنة السريعة
  PromoValidationResult validateCoupon({
    required CouponModel? coupon,
    required double tripPrice,
    required String userId,
    int userUsageCount = 0,
  }) {
    if (coupon == null) {
      return PromoValidationResult(isValid: false, discountAmount: 0.0, errorMessage: 'promoInvalid');
    }

    if (coupon.isExpired) {
      return PromoValidationResult(isValid: false, discountAmount: 0.0, errorMessage: 'promoInvalid');
    }

    if (coupon.isLimitReached) {
      return PromoValidationResult(isValid: false, discountAmount: 0.0, errorMessage: 'promoLimitReached');
    }

    if (!coupon.isValidForUser(userId)) {
      return PromoValidationResult(isValid: false, discountAmount: 0.0, errorMessage: 'promoInvalid');
    }

    final allowedPerUser = coupon.usageLimitPerUser ?? 1;
    if (userUsageCount >= allowedPerUser) {
      return PromoValidationResult(
        isValid: false,
        discountAmount: 0.0,
        errorMessage: 'promoLimitReached',
      );
    }

    double discount = 0.0;
    if (coupon.isFreeRide) {
      discount = tripPrice;
    } else {
      discount = tripPrice * (coupon.discountValue / 100.0);
    }

    if (discount > tripPrice) {
      discount = tripPrice;
    }

    return PromoValidationResult(
      isValid: true,
      discountAmount: discount,
    );
  }

}
