import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../constants/app_constants.dart';
import 'models/stripe_payment_models.dart';
import 'stripe_card_management_service.dart';

export 'models/stripe_payment_models.dart';

/// خدمة الدفع السحابية عبر بوابة Stripe الرسمية (Stripe Payment Gateway Service)
class StripePaymentService {
  static final StripePaymentService instance = StripePaymentService._();
  StripePaymentService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final StripeCardManagementService _cardManagement =
      StripeCardManagementService();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  /// تهيئة Stripe بالمفتاح العام
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Stripe.publishableKey = AppConstants.stripePublishableKey;
      Stripe.merchantIdentifier = 'merchant.com.taxicom.app.user';
      await Stripe.instance.applySettings();
      _isInitialized = true;
      debugPrint('💳 [StripePaymentService] Stripe initialized successfully.');
    } catch (e) {
      debugPrint('❌ [StripePaymentService] Stripe initialization failed: $e');
    }
  }

  /// إنشاء PaymentIntent عبر دوال الفايربيس السحابية الآمنة (Firebase Cloud Functions)
  Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
    required String userId,
    String? paymentMethodId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String userType = 'passenger',
    String purpose = 'wallet_topup',
    String? tripId,
  }) async {
    _lastErrorMessage = null;
    try {
      final callable = _functions.httpsCallable(
        'createStripePaymentIntent',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 35)),
      );

      final result = await callable.call<Map<dynamic, dynamic>>({
        'amount': amount,
        'currency': currency,
        'userId': userId,
        if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'userType': userType,
        'purpose': purpose,
        'tripId': tripId,
      });

      final data = Map<String, dynamic>.from(result.data);
      debugPrint(
        '✅ [StripePaymentService] PaymentIntent created via Cloud Function: ${data['paymentIntentId']}',
      );
      return data;
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        _lastErrorMessage = e.message ?? e.details?.toString();
      } else {
        _lastErrorMessage = e.toString();
      }
      debugPrint('❌ [StripePaymentService] createPaymentIntent error: $e');
      return null;
    }
  }

  /// إنشاء SetupIntent لحفظ بطاقة بنكية مشفرة عبر Cloud Functions (PCI-DSS Tokenization)
  Future<String?> createSetupIntent({
    required String userId,
    String? userEmail,
    String? userName,
  }) async {
    _lastErrorMessage = null;
    try {
      final callable = _functions.httpsCallable(
        'createStripeSetupIntent',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 35)),
      );

      final result = await callable.call<Map<dynamic, dynamic>>({
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
      });

      final data = Map<String, dynamic>.from(result.data);
      final clientSecret = data['clientSecret'] as String?;
      debugPrint(
        '✅ [StripePaymentService] SetupIntent received via Cloud Function: ${data['setupIntentId']}',
      );
      return clientSecret;
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        _lastErrorMessage = e.message ?? e.details?.toString();
      } else {
        _lastErrorMessage = e.toString();
      }
      debugPrint('❌ [StripePaymentService] createSetupIntent error: $e');
      return null;
    }
  }

  /// ربط وسيلة الدفع المشفرة بحساب العميل في Stripe
  Future<bool> attachPaymentMethodToCustomer({
    required String paymentMethodId,
    required String userId,
    String? cardId,
    bool isDefault = false,
    String? userName,
    String? userEmail,
    String? userPhone,
  }) => _cardManagement.attachPaymentMethod(
    paymentMethodId: paymentMethodId,
    userId: userId,
    cardId: cardId,
    isDefault: isDefault,
    userName: userName,
    userEmail: userEmail,
    userPhone: userPhone,
  );

  /// فصل وسيلة الدفع من حساب العميل في Stripe عند حذفها
  Future<bool> detachPaymentMethodFromCustomer({
    required String paymentMethodId,
    required String userId,
  }) => _cardManagement.detachPaymentMethod(
    paymentMethodId: paymentMethodId,
    userId: userId,
  );

  /// تعيين البطاقة الافتراضية عبر الخادم الموثوق فقط.
  Future<bool> setDefaultPaymentMethod({
    required String cardId,
    required String userId,
  }) => _cardManagement.setDefaultPaymentMethod(cardId: cardId, userId: userId);

  /// حفظ بطاقة بنكية مشفرة بأمان عبر نافذة Stripe الأصلية (PCI-DSS 100%)
  Future<PaymentSheetResult> saveCardViaSetupIntent({
    required String userId,
    String? userName,
    String? userEmail,
  }) async {
    try {
      final clientSecret = await createSetupIntent(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
      );

      if (clientSecret == null || clientSecret.isEmpty) {
        return PaymentSheetResult.failed(
          _lastErrorMessage ?? 'تعذر إعداد جلسة حفظ البطاقة الآمنة',
        );
      }

      final initialized = await setupPaymentSheet(
        clientSecret: clientSecret,
        isSetupIntent: true,
      );

      if (!initialized) {
        return PaymentSheetResult.failed('فشل في تهيئة واجهة إضافة البطاقة');
      }

      return await presentPaymentSheet();
    } catch (e) {
      debugPrint('❌ [StripePaymentService] saveCardViaSetupIntent error: $e');
      return PaymentSheetResult.failed(e.toString());
    }
  }

  /// إعداد وتجهيز نافذة الدفع الحقيقية (Payment Sheet)
  Future<bool> setupPaymentSheet({
    required String clientSecret,
    String? customerId,
    String? customerEphemeralKeySecret,
    bool isSetupIntent = false,
  }) async {
    try {
      await initialize();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: isSetupIntent ? null : clientSecret,
          setupIntentClientSecret: isSetupIntent ? clientSecret : null,
          customerId: customerId,
          customerEphemeralKeySecret: customerEphemeralKeySecret,
          merchantDisplayName: 'Taxicom',
          allowsDelayedPaymentMethods: true,
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'GB',
            currencyCode: 'USD',
            testEnv: true,
          ),
          applePay: const PaymentSheetApplePay(merchantCountryCode: 'GB'),
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: Color(0xFF0B4EA2)),
          ),
        ),
      );

      debugPrint('💳 [StripePaymentService] PaymentSheet initialized.');
      return true;
    } catch (e) {
      debugPrint('❌ [StripePaymentService] setupPaymentSheet error: $e');
      return false;
    }
  }

  /// فتح وعرض واجهة الدفع الرسمية (Payment Sheet) للمستخدم
  Future<PaymentSheetResult> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      debugPrint(
        '✅ [StripePaymentService] Payment Sheet completed successfully.',
      );
      return PaymentSheetResult.success();
    } on StripeException catch (e) {
      debugPrint(
        '⚠️ [StripePaymentService] StripeException: ${e.error.localizedMessage}',
      );
      if (e.error.code == FailureCode.Canceled) {
        return PaymentSheetResult.canceled();
      }
      return PaymentSheetResult.failed(
        e.error.localizedMessage ?? 'تم إلغاء أو فشل عملية الدفع',
      );
    } catch (e) {
      debugPrint(
        '❌ [StripePaymentService] presentPaymentSheet unknown error: $e',
      );
      return PaymentSheetResult.failed(e.toString());
    }
  }

  /// معالجة شحن الرصيد عبر Stripe ودوال Firebase Cloud Functions
  Future<PaymentResult> processTopUpPayment({
    required double amount,
    required String currency,
    required String userId,
    String? paymentMethodId,
    String? userName,
    String? userEmail,
    String? userPhone,
  }) async {
    try {
      final data = await createPaymentIntent(
        amount: amount,
        currency: currency,
        userId: userId,
        paymentMethodId: paymentMethodId,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
      );

      if (data == null) {
        return PaymentResult(
          success: false,
          errorMessage:
              _lastErrorMessage ??
              'تعذر الاتصال بدوال المدفوعات السحابية لإنشاء جلسة الدفع الآمنة',
        );
      }

      final status = data['status'] as String?;
      final clientSecret = data['clientSecret'] as String?;
      final paymentIntentId = data['paymentIntentId'] as String?;

      if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
        if (status == 'succeeded') {
          debugPrint(
            '✅ [StripePaymentService] Saved card charged successfully: $paymentIntentId',
          );
          return PaymentResult(
            success: true,
            transactionReference: paymentIntentId,
          );
        } else if (status == 'requires_action' && clientSecret != null) {
          debugPrint(
            '🔐 [StripePaymentService] 3D Secure verification required for saved card',
          );
          try {
            await initialize();
            await Stripe.instance.handleNextAction(clientSecret);
            return PaymentResult(
              success: true,
              transactionReference: paymentIntentId,
            );
          } on StripeException catch (e) {
            if (e.error.code == FailureCode.Canceled) {
              return const PaymentResult(success: false, isCanceled: true);
            }
            return PaymentResult(
              success: false,
              errorMessage: e.error.localizedMessage ?? 'فشلت مصادقة البنك',
            );
          } catch (e) {
            return PaymentResult(success: false, errorMessage: e.toString());
          }
        }
      }

      if (clientSecret == null || clientSecret.isEmpty) {
        return const PaymentResult(
          success: false,
          errorMessage: 'تعذر استلام بيانات جلسة الدفع',
        );
      }

      final customerId = data['customerId'] as String?;
      final ephemeralKeySecret = data['ephemeralKeySecret'] as String?;

      final initialized = await setupPaymentSheet(
        clientSecret: clientSecret,
        customerId: customerId,
        customerEphemeralKeySecret: ephemeralKeySecret,
      );

      if (!initialized) {
        return const PaymentResult(
          success: false,
          errorMessage: 'فشل في تهيئة نافذة الدفع',
        );
      }

      final sheetResult = await presentPaymentSheet();
      if (!sheetResult.isSuccess) {
        return PaymentResult(
          success: false,
          errorMessage: sheetResult.errorMessage,
          isCanceled: sheetResult.isCanceled,
        );
      }

      return const PaymentResult(success: true);
    } catch (e) {
      debugPrint('❌ [StripePaymentService] processTopUpPayment error: $e');
      return PaymentResult(success: false, errorMessage: e.toString());
    }
  }

  /// فك الحجز المالي المسبق للبطاقة عند إلغاء الرحلة (Release Pre-Auth Hold)
  Future<bool> releaseTripHoldPayment({
    required String tripId,
    String? cancellationReason,
    String cancelledBy = 'passenger',
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'releaseTripHoldPayment',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );

      final result = await callable.call<Map<dynamic, dynamic>>({
        'tripId': tripId,
        'cancellationReason': cancellationReason ?? 'cancelled_by_passenger',
        'cancelledBy': cancelledBy,
      });

      final data = Map<String, dynamic>.from(result.data);
      debugPrint(
        '✅ [StripePaymentService] نتيجة فك الحجز المالي للبطاقة: $data',
      );
      return data['success'] == true;
    } catch (e) {
      debugPrint(
        '⚠️ [StripePaymentService] خطأ أثناء استدعاء فك الحجز المالي: $e',
      );
      return false;
    }
  }
}
