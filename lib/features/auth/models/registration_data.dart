/// نموذج بيانات التسجيل المؤقتة
/// 
/// يُستخدم لتمرير بيانات التسجيل إلى شاشة التحقق من OTP
/// قبل إنشاء الحساب في Firebase
library;

/// بيانات التسجيل المؤقتة
class RegistrationData {
  /// رقم الهاتف الكامل مع رمز الدولة
  final String phone;
  
  /// كلمة المرور (غير مستخدمة بعد تحويل المصادقة إلى Phone Auth)
  final String password;
  
  /// الاسم
  final String name;
  
  /// البريد الإلكتروني (اختياري)
  final String? email;
  
  /// العنوان (اختياري)
  final String? address;
  
  /// الجنس (اختياري)
  final String? gender;
  
  /// تاريخ الميلاد (اختياري)
  final DateTime? birthDate;

  /// المحافظة (بغداد أو كركوك)
  final String province;

  const RegistrationData({
    required this.phone,
    required this.name,
    this.password = '',
    this.province = 'baghdad',
    this.email,
    this.address,
    this.gender,
    this.birthDate,
  });
}
