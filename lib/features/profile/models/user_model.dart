/// نموذج المستخدم
/// 
/// يمثل بيانات المستخدم (الراكب) المخزنة في Firestore
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

/// فئة نموذج المستخدم (الراكب)
class UserModel {
  /// معرف المستخدم الفريد (من Firebase Auth)
  final String uid;
  
  /// رقم الهاتف
  final String phone;
  
  /// الاسم الكامل
  final String name;
  
  /// البريد الإلكتروني (اختياري)
  final String? email;
  
  /// العنوان (اختياري)
  final String? address;
  
  /// الجنس (اختياري)
  final String? gender;
  
  /// تاريخ الميلاد (اختياري)
  final DateTime? birthDate;
  
  /// نوع المستخدم (customer)
  final String userType;
  
  /// رابط الصورة الشخصية
  final String? profilePhotoUrl;
  
  /// المحافظة (بغداد أو كركوك)
  final String? province;
  
  /// رمز FCM للإشعارات
  final String? fcmToken;
  
  /// تاريخ الإنشاء
  final DateTime createdAt;
  
  /// تاريخ آخر تحديث
  final DateTime updatedAt;

  /// المنشئ الأساسي
  UserModel({
    required this.uid,
    required this.phone,
    required this.name,
    this.email,
    this.address,
    this.gender,
    this.birthDate,
    this.userType = 'customer',
    this.profilePhotoUrl,
    this.province,
    this.fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// إنشاء نموذج من خريطة (من Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      email: map['email'],
      address: map['address'],
      gender: map['gender'],
      birthDate: map['birthDate'] != null
          ? (map['birthDate'] as Timestamp).toDate()
          : null,
      userType: map['userType'] ?? 'customer',
      profilePhotoUrl: map['profilePhotoUrl'],
      province: map['province'],
      fcmToken: map['fcmToken'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// إنشاء نموذج من DocumentSnapshot
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// تحويل النموذج إلى خريطة (للحفظ في Firestore)
  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'name': name,
      'email': email,
      'address': address,
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'userType': userType,
      'profilePhotoUrl': profilePhotoUrl,
      'province': province,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// إنشاء نسخة معدلة من النموذج
  UserModel copyWith({
    String? uid,
    String? phone,
    String? name,
    String? email,
    String? address,
    String? gender,
    DateTime? birthDate,
    String? userType,
    String? profilePhotoUrl,
    String? province,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      userType: userType ?? this.userType,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      province: province ?? this.province,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, phone: $phone, name: $name, email: $email, address: $address, gender: $gender, birthDate: $birthDate, userType: $userType)';
  }

  /// تحويل النموذج إلى JSON string للتخزين المحلي
  String toJson() {
    return jsonEncode({
      'uid': uid,
      'phone': phone,
      'name': name,
      'email': email,
      'address': address,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'userType': userType,
      'profilePhotoUrl': profilePhotoUrl,
      'province': province,
      'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    });
  }

  /// إنشاء نموذج من JSON string (للتحميل من التخزين المحلي)
  factory UserModel.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      email: map['email'],
      address: map['address'],
      gender: map['gender'],
      birthDate: map['birthDate'] != null
          ? DateTime.parse(map['birthDate'])
          : null,
      userType: map['userType'] ?? 'customer',
      profilePhotoUrl: map['profilePhotoUrl'],
      province: map['province'],
      fcmToken: map['fcmToken'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
