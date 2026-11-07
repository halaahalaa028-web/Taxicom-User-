import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

/// خدمة صندوق الإشعارات الداخلية (In-App Notification Feed)
///
/// تجلب الإشعارات من Firebase Firestore مع تصفية حسب الجمهور المستهدف،
/// وتتبع حالة القراءة في قاعدة البيانات عبر حقل [readBy].
class NotificationInboxService {
  // Singleton pattern
  static final NotificationInboxService _instance =
      NotificationInboxService._internal();
  static NotificationInboxService get instance => _instance;
  NotificationInboxService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// عدد الإشعارات لكل صفحة
  static const int _pageSize = 10;

  // ──────────────────────────────────────────────────────────────
  // جلب الإشعارات مع Pagination
  // ──────────────────────────────────────────────────────────────

  /// جلب وثائق إشعارات العملاء كـ QuerySnapshot (للحصول على docs و lastDoc)
  Future<QuerySnapshot<Map<String, dynamic>>>
  fetchCustomerNotificationsSnapshot(
    String customerId, {
    DocumentSnapshot? lastDoc,
  }) async {
    var query = _firestore
        .collection('notifications')
        .where('audience', whereIn: ['customer', 'all'])
        .orderBy('timestamp', descending: true)
        .limit(_pageSize);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return await query.get();
  }

  /// جلب وثائق الإشعارات الشخصية الخاصة بالعميل كـ QuerySnapshot
  Future<QuerySnapshot<Map<String, dynamic>>>
  fetchPersonalNotificationsSnapshot(
    String customerId, {
    DocumentSnapshot? lastDoc,
  }) async {
    var query = _firestore
        .collection('notifications')
        .where('audience', isEqualTo: 'private')
        .where('userId', isEqualTo: customerId)
        .orderBy('timestamp', descending: true)
        .limit(_pageSize);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return await query.get();
  }

  /// جلب صفحة من إشعارات المستخدم (أو الجميع)
  Future<List<NotificationModel>> fetchCustomerNotificationsPage(
    String customerId, {
    DocumentSnapshot? lastDoc,
  }) async {
    final snapshot = await fetchCustomerNotificationsSnapshot(
      customerId,
      lastDoc: lastDoc,
    );
    return snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ──────────────────────────────────────────────────────────────
  // Streams للعدّ وتتبع حالة القراءة
  // ──────────────────────────────────────────────────────────────

  /// الاستماع لجميع إشعارات الزبون (أو الجميع)
  Stream<List<NotificationModel>> getCustomerNotifications(String customerId) {
    return _firestore
        .collection('notifications')
        .where('audience', whereIn: ['customer', 'all'])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// الاستماع لعدد الإشعارات غير المقروءة للزبون
  Stream<int> getUnreadCount(String customerId) {
    return _firestore
        .collection('notifications')
        .where('audience', whereIn: ['customer', 'all'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final data = doc.data();
            final readBy = List<String>.from(data['readBy'] ?? []);
            return !readBy.contains(customerId);
          }).length;
        });
  }

  /// الاستماع لعدد الإشعارات غير المقروءة للزبون (تسمية متوافقة)
  Stream<int> getCustomerUnreadCountStream(String customerId) =>
      getUnreadCount(customerId);

  // ──────────────────────────────────────────────────────────────
  // تحديث حالة القراءة
  // ──────────────────────────────────────────────────────────────

  /// تعليم إشعار كمقروء للمستخدم الحالي
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// تعليم جميع الإشعارات كمقروءة للزبون الحالي
  Future<void> markAllAsRead(
    String customerId, [
    List<String>? notificationIds,
  ]) async {
    try {
      if (notificationIds != null && notificationIds.isNotEmpty) {
        final batch = _firestore.batch();
        for (final id in notificationIds) {
          batch.update(_firestore.collection('notifications').doc(id), {
            'readBy': FieldValue.arrayUnion([customerId]),
          });
        }
        await batch.commit();
        return;
      }

      final snapshot = await _firestore
          .collection('notifications')
          .where('audience', whereIn: ['customer', 'all'])
          .get();

      final batch = _firestore.batch();
      bool hasUpdates = false;

      for (var doc in snapshot.docs) {
        final readBy = List<String>.from(doc.data()['readBy'] ?? []);
        if (!readBy.contains(customerId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([customerId]),
          });
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // إرسال الإشعارات
  // ──────────────────────────────────────────────────────────────

  /// إرسال إشعار جديد
  Future<void> sendNotification({
    required String title,
    required String body,
    required String audience,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'audience': audience,
        'type': type ?? 'general',
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [],
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }

  /// إرسال إشعار لجميع المستخدمين
  Future<void> sendToAllCustomers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await sendNotification(
      title: title,
      body: body,
      audience: 'customer',
      type: 'broadcast',
      data: data,
    );
  }

  /// إرسال إشعار للجميع (سائقين ومستخدمين)
  Future<void> sendToAll({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await sendNotification(
      title: title,
      body: body,
      audience: 'all',
      type: 'broadcast',
      data: data,
    );
  }
}

/// لضمان التوافق مع الكود السابق
typedef NotificationService = NotificationInboxService;
