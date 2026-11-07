/// تطبيق تاكسيكوم - المستخدم
/// 
/// ويدجت MaterialApp الرئيسي للتطبيق
/// يتضمن إعدادات الثيم واللغة والتوجيه
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/services/language_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/screens/auth_wrapper.dart';

/// ويدجت التطبيق الرئيسي
class TaxicomApp extends StatefulWidget {
  const TaxicomApp({super.key});

  @override
  State<TaxicomApp> createState() => _TaxicomAppState();
}

class _TaxicomAppState extends State<TaxicomApp> {
  @override
  void initState() {
    super.initState();
    // الاستماع لتغييرات اللغة
    LanguageService.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.instance;
    
    return MaterialApp(
      // مفتاح فريد لكل لغة - يجبر Flutter على إعادة إنشاء الشجرة بالكامل عند تغيير اللغة
      key: ValueKey('app_${languageService.currentLanguage.code}'),
      // مفتاح التنقل للإشعارات
      navigatorKey: NotificationService.navigatorKey,
      
      // اسم التطبيق
      title: AppStrings.appName,
      
      // إخفاء شعار Debug
      debugShowCheckedModeBanner: false,
      
      // الثيم - فقط النمط الفاتح
      theme: AppTheme.lightTheme,
      
      // إجبار استخدام النمط الفاتح فقط بغض النظر عن إعدادات النظام
      themeMode: ThemeMode.light,
      
      // دعم اللغة للـ Material widgets: fallback للعربية للغات غير المتوفرة في GlobalMaterialLocalizations
      locale: languageService.currentLanguage == AppLanguage.kurdish
          ? const Locale('ar')
          : languageService.locale,
      
      // اللغات المدعومة في Material
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('ru'),
        Locale('de'),
        Locale('fr'),
        Locale('it'),
        Locale('es'),
        Locale('tr'),
        Locale('zh'),
        Locale('fa'),
        Locale('hi'),
      ],

      // مفوضو الترجمة
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // بناء التطبيق مع اتجاه النص المناسب للغة
      builder: (context, child) {
        return Directionality(
          textDirection: languageService.textDirection,
          child: child!,
        );
      },
      
      // الشاشة الرئيسية - التوجيه المباشر عبر غلاف المصادقة
      home: const AuthWrapper(),
    );
  }
}
