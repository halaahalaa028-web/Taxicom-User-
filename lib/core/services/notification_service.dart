/// خدمة الإشعارات FCM
/// 
/// تتعامل مع Firebase Cloud Messaging لإرسال واستقبال الإشعارات للراكب
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// معالج الإشعارات في الخلفية (يجب أن يكون top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  debugPrint('📬 استلام إشعار في الخلفية: ${message.notification?.title}');
}

/// خدمة الإشعارات للراكب
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  /// مفتاح التنقل العام لاستخدامه في فتح الشاشات من الإشعارات
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    try {
      // 1. طلب الصلاحيات
      await _requestPermissions();

      // 2. تهيئة الإشعارات المحلية
      await _initializeLocalNotifications();

      // 3. معالج الإشعارات في الخلفية
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 4. الاستماع للإشعارات أثناء فتح التطبيق (Foreground)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. الاستماع للنقر على الإشعار وفتح التطبيق من الخلفية
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // 6. التحقق من الإشعار الذي فتح التطبيق (Terminated state)
      _handleInitialMessage();

      // 7. جلب الـ FCM Token وتحديثه في Firestore
      await _getFcmToken();

      // 8. الاستماع لتحديثات الـ Token
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      debugPrint('✅ تم تهيئة خدمة الإشعارات بنجاح');
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات: $e');
      debugPrint('📋 StackTrace: $stackTrace');
    }
  }

  /// طلب صلاحيات الإشعارات
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
      announcement: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ تم منح صلاحية الإشعارات');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('⚠️ تم منح صلاحية إشعارات مؤقتة');
    } else {
      debugPrint('❌ تم رفض صلاحية الإشعارات');
    }
  }

  /// تهيئة الإشعارات المحلية
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // إنشاء قنوات الإشعارات لـ Android
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // قناة تحديثات الرحلات
      const tripUpdatesChannel = AndroidNotificationChannel(
        'trip_updates_channel',
        'تحديثات الرحلة',
        description: 'إشعارات حالة الرحلة (قبول، وصول السائق، انتهاء الرحلة)',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin?.createNotificationChannel(tripUpdatesChannel);

      // قناة إشعارات الإدارة
      const adminChannel = AndroidNotificationChannel(
        'admin_notifications_channel',
        'إشعارات الإدارة',
        description: 'إشعارات من إدارة التطبيق والعروض',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin?.createNotificationChannel(adminChannel);

      // قناة رسائل المحادثة
      const chatChannel = AndroidNotificationChannel(
        'chat_notifications_channel',
        'رسائل المحادثة',
        description: 'إشعارات الرسائل بين الراكب والسائق',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin?.createNotificationChannel(chatChannel);
    }
  }

  /// الحصول على FCM Token
  Future<void> _getFcmToken() async {
    try {
      if (Platform.isIOS) {
        String? apnsToken;
        try {
          apnsToken = await _messaging.getAPNSToken();
        } catch (_) {}

        if (apnsToken == null) {
          _fcmToken = await _messaging.getToken();
          if (_fcmToken != null) {
            await _saveTokenToFirestore(_fcmToken!);
          }
          return;
        }
      }

      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('📱 FCM Token: $_fcmToken');
        await _saveTokenToFirestore(_fcmToken!);
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب FCM Token: $e');
    }
  }

  /// حفظ الـ Token في Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'fcmToken': token,
              'platform': Platform.isAndroid ? 'android' : 'ios',
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        debugPrint('✅ تم حفظ FCM Token في Firestore للمستخدم: ${user.uid}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في حفظ FCM Token: $e');
    }
  }

  /// معالجة تحديث الـ Token
  void _onTokenRefresh(String token) {
    debugPrint('🔄 تم تحديث FCM Token: $token');
    _fcmToken = token;
    _saveTokenToFirestore(token);
  }

  /// تحديث FCM Token عند تسجيل الدخول
  Future<void> updateFcmTokenOnLogin() async {
    await _getFcmToken();
  }

  /// معالجة الإشعارات في المقدمة (Foreground)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 استلام إشعار في المقدمة: ${message.notification?.title}');
    
    final notification = message.notification;
    final type = message.data['type'] ?? '';

    if (notification != null) {
      String channelId = 'trip_updates_channel';
      String channelName = 'تحديثات الرحلة';

      if (type == 'chat' || type == 'chat_message') {
        channelId = 'chat_notifications_channel';
        channelName = 'رسائل المحادثة';
      } else if (type == 'admin' || type == 'promo' || type == 'discount') {
        channelId = 'admin_notifications_channel';
        channelName = 'إشعارات الإدارة';
      }

      _showLocalNotification(
        title: notification.title ?? 'إشعار جديد',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
        channelId: channelId,
        channelName: channelName,
      );
    }
  }

  /// عرض إشعار محلي
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'trip_updates_channel',
    String channelName = 'تحديثات الرحلة',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'إشعارات $channelName',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// التحقق من إشعار أولي (عند فتح التطبيق من إشعار وهو مغلق)
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 التطبيق فُتح من إشعار: ${initialMessage.data}');
      _navigateBasedOnData(initialMessage.data);
    }
  }

  /// معالجة النقر على الإشعار
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 تم النقر على الإشعار: ${message.data}');
    _navigateBasedOnData(message.data);
  }

  /// استجابة النقر على الإشعار المحلي
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('👆 تم النقر على الإشعار المحلي: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _navigateBasedOnData(data);
      } catch (e) {
        debugPrint('❌ خطأ في تحليل payload: $e');
      }
    }
  }

  /// التنقل بناءً على بيانات الإشعار
  void _navigateBasedOnData(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    debugPrint('🧭 نوع الإشعار: $type');
  }

  /// حذف FCM Token عند تسجيل الخروج
  Future<void> clearFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': FieldValue.delete()});
        debugPrint('✅ تم حذف FCM Token من Firestore');
      } catch (e) {
        debugPrint('❌ خطأ في حذف FCM Token: $e');
      }
    }
    _fcmToken = null;
  }
}
