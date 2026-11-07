import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/country_service.dart';
import '../../../../core/services/stripe_payment_service.dart';
import '../../../../core/services/wallet_service.dart';
import '../../data/models/saved_card_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/models/wallet_transaction_model.dart';

/// وحدة التحكم بحالة المحفظة والمدفوعات (Wallet Controller)
class WalletController extends ChangeNotifier {
  final WalletService _walletService = WalletService.instance;
  final StripePaymentService _stripeService = StripePaymentService.instance;

  bool _isLoading = false;
  bool _isProcessingTopUp = false;
  String? _errorMessage;
  double _selectedAmount = 10000.0;
  SavedCardModel? _selectedCard;
  String _selectedPaymentMethod = 'stripe';

  bool get isLoading => _isLoading;
  bool get isProcessingTopUp => _isProcessingTopUp;
  String? get errorMessage => _errorMessage;
  double get selectedAmount => _selectedAmount;
  SavedCardModel? get selectedCard => _selectedCard;
  String get selectedPaymentMethod => _selectedPaymentMethod;

  WalletModel? get wallet => _walletService.cachedWallet;
  double get balance => _walletService.currentBalance;
  List<WalletTransactionModel> get transactions => _walletService.transactionsNotifier.value;
  List<SavedCardModel> get savedCards => _walletService.savedCardsNotifier.value;
  String get currency => CountryService.instance.selectedCountry.currencyAr;
  bool get hasMoreTransactions => _walletService.hasMoreTransactions;
  bool get isLoadingMoreTransactions => _walletService.isLoadingMoreTransactions;

  WalletController() {
    _init();
  }

  void _init() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _walletService.startListening(user.uid);
      _walletService.savedCardsNotifier.addListener(_onCardsChanged);
      _walletService.transactionsNotifier.addListener(_onTransactionsChanged);
      _walletService.isLoadingMoreTransactionsNotifier.addListener(_onPaginationStateChanged);
      _walletService.hasMoreTransactionsNotifier.addListener(_onPaginationStateChanged);
    }
  }

  void _onCardsChanged() {
    final cards = _walletService.savedCardsNotifier.value;
    if (_selectedCard == null && cards.isNotEmpty) {
      _selectedCard = cards.firstWhere((c) => c.isDefault, orElse: () => cards.first);
      notifyListeners();
    }
  }

  void _onTransactionsChanged() {
    notifyListeners();
  }

  void _onPaginationStateChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _walletService.savedCardsNotifier.removeListener(_onCardsChanged);
    _walletService.transactionsNotifier.removeListener(_onTransactionsChanged);
    _walletService.isLoadingMoreTransactionsNotifier.removeListener(_onPaginationStateChanged);
    _walletService.hasMoreTransactionsNotifier.removeListener(_onPaginationStateChanged);
    super.dispose();
  }

  /// تحميل المزيد من المعاملات الأقدم عند التمرير للأسفل
  Future<void> loadMoreTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _walletService.loadMoreTransactions(user.uid);
  }

  /// إعادة تحديث المعاملات من البداية
  Future<void> refreshTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _walletService.refreshTransactions(user.uid);
  }

  void setSelectedAmount(double amount) {
    _selectedAmount = amount;
    notifyListeners();
  }

  void setSelectedCard(SavedCardModel? card) {
    _selectedCard = card;
    notifyListeners();
  }

  void setSelectedPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  /// تنفيذ عملية شحن رصيد المحفظة عبر Stripe
  Future<bool> topUpWallet({
    required double amount,
    String? paymentMethodId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || amount <= 0) return false;

    _isProcessingTopUp = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // معالجة الدفع عبر Stripe (مباشرة بالبطاقة المحفوظة إن وجدت أو عبر PaymentSheet)
      final effectivePaymentMethodId = paymentMethodId ?? _selectedCard?.paymentMethodId;
      final paymentResult = await _stripeService.processTopUpPayment(
        amount: amount,
        currency: currency,
        userId: user.uid,
        paymentMethodId: effectivePaymentMethodId,
        userName: user.displayName,
        userEmail: user.email,
        userPhone: user.phoneNumber,
      );

      if (!paymentResult.success) {
        if (!paymentResult.isCanceled) {
          _errorMessage = paymentResult.errorMessage ?? 'فشلت عملية الدفع';
        }
        _isProcessingTopUp = false;
        notifyListeners();
        return false;
      }

      // تم تحديث الرصيد ذرياً وسحابياً عبر Firebase Cloud Functions / Webhook
      // وسيقوم الـ Firestore Stream بتحديث واجهة المستخدم فورياً وتلقائياً
      _isProcessingTopUp = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessingTopUp = false;
      notifyListeners();
      return false;
    }
  }

  /// حفظ بطاقة جديدة
  Future<bool> addSavedCard(SavedCardModel card) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();

    final result = await _walletService.addSavedCard(
      userId: user.uid,
      card: card,
    );

    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// حذف بطاقة
  Future<bool> deleteSavedCard(String cardId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    return await _walletService.deleteSavedCard(
      userId: user.uid,
      cardId: cardId,
    );
  }

  /// تعيين كبطاقة افتراضية
  Future<void> setDefaultCard(String cardId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _walletService.setDefaultCard(
      userId: user.uid,
      cardId: cardId,
    );
  }
}
