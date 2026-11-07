import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// عمليات البطاقات المحفوظة التي يجب أن تمر عبر Cloud Functions الموثوقة.
class StripeCardManagementService {
  StripeCardManagementService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<bool> attachPaymentMethod({
    required String paymentMethodId,
    required String userId,
    String? cardId,
    bool isDefault = false,
    String? userName,
    String? userEmail,
    String? userPhone,
  }) {
    return _call('attachStripePaymentMethod', {
      'paymentMethodId': paymentMethodId,
      'userId': userId,
      'cardId': cardId,
      'isDefault': isDefault,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
    });
  }

  Future<bool> detachPaymentMethod({
    required String paymentMethodId,
    required String userId,
  }) {
    return _call('detachStripePaymentMethod', {
      'paymentMethodId': paymentMethodId,
      'userId': userId,
    });
  }

  Future<bool> setDefaultPaymentMethod({
    required String cardId,
    required String userId,
  }) {
    return _call('setDefaultStripePaymentMethod', {
      'cardId': cardId,
      'userId': userId,
    });
  }

  Future<bool> _call(String functionName, Map<String, dynamic> payload) async {
    try {
      final result = await _functions
          .httpsCallable(functionName)
          .call<Map<dynamic, dynamic>>(payload);
      return Map<String, dynamic>.from(result.data)['success'] == true;
    } catch (error) {
      debugPrint(
        '⚠️ [StripeCardManagementService] $functionName failed: $error',
      );
      return false;
    }
  }
}
