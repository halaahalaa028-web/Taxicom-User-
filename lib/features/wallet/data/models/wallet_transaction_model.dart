import 'package:cloud_firestore/cloud_firestore.dart';

/// نوع المعاملة المالية
enum WalletTransactionType {
  topUp, // شحن رصيد
  tripPayment, // دفع أجرة رحلة
  refund, // استرداد مبلغ
  bonus, // مكافأة أو هدية ترويجية
  withdrawal, // سحب رصيد
}

/// حالة المعاملة المالية
enum WalletTransactionStatus {
  completed, // مكتملة بنجاح
  pending, // معلقة / قيد المعالجة
  failed, // فشلت
  cancelled, // ملغاة
}

/// نموذج المعاملة المالية في المحفظة
class WalletTransactionModel {
  final String id;
  final String userId;
  final double amount;
  final WalletTransactionType type;
  final WalletTransactionStatus status;
  final String title;
  final String? description;
  final String? referenceId; // Trip ID or Stripe Intent ID
  final String? paymentMethod; // stripe, card, cash, apple_pay
  final String currency;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.status = WalletTransactionStatus.completed,
    required this.title,
    this.description,
    this.referenceId,
    this.paymentMethod,
    this.currency = 'د.ع',
    required this.createdAt,
  });

  /// هل المعاملة إضافة رصيد (موجبة) أم خصم (سالبة)
  bool get isCredit =>
      type == WalletTransactionType.topUp ||
      type == WalletTransactionType.refund ||
      type == WalletTransactionType.bonus;

  factory WalletTransactionModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return WalletTransactionModel(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: WalletTransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WalletTransactionType.topUp,
      ),
      status: WalletTransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WalletTransactionStatus.completed,
      ),
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      referenceId: map['referenceId'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      currency: map['currency'] as String? ?? 'د.ع',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'title': title,
      if (description != null) 'description': description,
      if (referenceId != null) 'referenceId': referenceId,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  WalletTransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    WalletTransactionType? type,
    WalletTransactionStatus? status,
    String? title,
    String? description,
    String? referenceId,
    String? paymentMethod,
    String? currency,
    DateTime? createdAt,
  }) {
    return WalletTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
