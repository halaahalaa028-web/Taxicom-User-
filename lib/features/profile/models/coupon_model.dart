import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج كوبون الخصم والمكافآت الموحد
class CouponModel {
  final String id;
  final String code;
  final String? title;
  final String description;
  final String discountType; // 'percentage', 'fixed', or 'free_trip'
  final double discountValue;
  final double? maxDiscountLimit;
  final double? minTripPrice;
  final int? usageLimit;
  final int usedCount;
  final int? usageLimitPerUser;
  final bool isActive;
  final bool isTargeted;
  final List<String>? assignedUserIds;
  final DateTime expiryDate;
  final DateTime? createdAt;

  CouponModel({
    required this.id,
    required this.code,
    this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountLimit,
    this.minTripPrice,
    this.usageLimit,
    required this.usedCount,
    this.usageLimitPerUser,
    required this.isActive,
    required this.isTargeted,
    this.assignedUserIds,
    required this.expiryDate,
    this.createdAt,
  });

  factory CouponModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now().add(const Duration(days: 30));
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return CouponModel(
      id: documentId,
      code: map['code']?.toString() ?? '',
      title: map['title']?.toString(),
      description: map['description']?.toString() ?? '',
      discountType: map['discountType']?.toString() ?? 'percentage',
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0.0,
      maxDiscountLimit: (map['maxDiscountLimit'] as num?)?.toDouble(),
      minTripPrice: (map['minTripPrice'] as num?)?.toDouble(),
      usageLimit: (map['usageLimit'] as num?)?.toInt(),
      usedCount: (map['usedCount'] as num?)?.toInt() ?? 0,
      usageLimitPerUser: (map['usageLimitPerUser'] as num?)?.toInt(),
      isActive: map['isActive'] == true,
      isTargeted: map['isTargeted'] == true,
      assignedUserIds: map['assignedUserIds'] != null
          ? (map['assignedUserIds'] as List).map((e) => e.toString()).toList()
          : null,
      expiryDate: parseDate(map['expiryDate']),
      createdAt: map['createdAt'] != null ? parseDate(map['createdAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      if (title != null) 'title': title,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'maxDiscountLimit': maxDiscountLimit,
      'minTripPrice': minTripPrice,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'usageLimitPerUser': usageLimitPerUser,
      'isActive': isActive,
      'isTargeted': isTargeted,
      'assignedUserIds': assignedUserIds,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isLimitReached => usageLimit != null && usedCount >= usageLimit!;

  bool get isFreeRide => discountType == 'free_trip' || (discountType == 'percentage' && discountValue >= 100);

  bool get hasTargetAudience => isTargeted && assignedUserIds != null && assignedUserIds!.isNotEmpty;

  bool isValidForUser(String userId) {
    if (!isActive) return false;
    if (!isTargeted) return true;
    return assignedUserIds?.contains(userId) ?? false;
  }
}
