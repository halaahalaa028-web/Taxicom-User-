/// نماذج نتائج عمليات الدفع وبوابة Stripe
library;

/// نتيجة نافذة ورقة الدفع (Stripe Payment Sheet Result)
class PaymentSheetResult {
  final bool isSuccess;
  final bool isCanceled;
  final String? errorMessage;

  const PaymentSheetResult._({
    this.isSuccess = false,
    this.isCanceled = false,
    this.errorMessage,
  });

  factory PaymentSheetResult.success() =>
      const PaymentSheetResult._(isSuccess: true);

  factory PaymentSheetResult.canceled() =>
      const PaymentSheetResult._(isCanceled: true);

  factory PaymentSheetResult.failed(String message) =>
      PaymentSheetResult._(errorMessage: message);
}

/// نتيجة عملية الدفع العامة (General Payment Result)
class PaymentResult {
  final bool success;
  final bool isCanceled;
  final String? transactionReference;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    this.isCanceled = false,
    this.transactionReference,
    this.errorMessage,
  });

  factory PaymentResult.successful([String? txRef]) => PaymentResult(
        success: true,
        transactionReference: txRef,
      );

  factory PaymentResult.canceled() => const PaymentResult(
        success: false,
        isCanceled: true,
      );

  factory PaymentResult.failed(String error) => PaymentResult(
        success: false,
        errorMessage: error,
      );
}
