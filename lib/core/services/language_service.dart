/// خدمة إدارة اللغة
/// 
/// تدير اللغة المحددة في التطبيق
/// وتحفظها في SharedPreferences
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// رموز اللغات المدعومة (12 لغة عالمية)
enum AppLanguage {
  arabic('ar', 'العربية', true),
  english('en', 'English', false),
  kurdish('ku', 'کوردی', true),
  russian('ru', 'Русский', false),
  german('de', 'Deutsch', false),
  french('fr', 'Français', false),
  italian('it', 'Italiano', false),
  spanish('es', 'Español', false),
  turkish('tr', 'Türkçe', false),
  chinese('zh', '中文 (简体)', false),
  persian('fa', 'فارسی', true),
  hindi('hi', 'हिन्दी', false);

  final String code;
  final String name;
  final bool isRtl;

  const AppLanguage(this.code, this.name, this.isRtl);

  /// الحصول على Locale
  Locale get locale => Locale(code);

  /// الحصول على اتجاه النص
  TextDirection get textDirection => 
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// الحصول على اللغة من الكود
  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.arabic,
    );
  }
}

/// خدمة إدارة اللغة
class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  
  static LanguageService? _instance;
  static LanguageService get instance => _instance ??= LanguageService._();
  
  LanguageService._();

  AppLanguage _currentLanguage = AppLanguage.arabic;
  bool _isInitialized = false;

  /// اللغة الحالية
  AppLanguage get currentLanguage => _currentLanguage;

  /// هل تم التهيئة
  bool get isInitialized => _isInitialized;

  /// Locale الحالي
  Locale get locale => _currentLanguage.locale;

  /// اتجاه النص الحالي
  TextDirection get textDirection => _currentLanguage.textDirection;

  /// هل اللغة الحالية RTL
  bool get isRtl => _currentLanguage.isRtl;

  /// تهيئة الخدمة وتحميل اللغة المحفوظة
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languageKey);
    
    if (savedCode != null) {
      _currentLanguage = AppLanguage.fromCode(savedCode);
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  /// تغيير اللغة
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    
    _currentLanguage = language;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
    
    notifyListeners();
  }

  /// الحصول على قائمة اللغات المدعومة (المفعلة حالياً)
  List<AppLanguage> get supportedLanguages => AppLanguage.values.toList();
}
