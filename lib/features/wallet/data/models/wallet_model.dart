import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج بيانات محفظة المستخدم
class WalletModel {
  final String userId;
  final double balance;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletModel({
    required this.userId,
    this.balance = 0.0,
    this.currency = 'د.ع',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// إنشاء محفظة افتراضية جديدة لمستخدم
  factory WalletModel.initial(String userId, {String currency = 'د.ع'}) {
    final now = DateTime.now();
    return WalletModel(
      userId: userId,
      balance: 0.0,
      currency: currency,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory WalletModel.fromMap(Map<String, dynamic> map, String documentId) {
    return WalletModel(
      userId: documentId,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'د.ع',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'balance': balance,
      'currency': currency,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  WalletModel copyWith({
    String? userId,
    double? balance,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
