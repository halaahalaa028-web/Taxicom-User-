import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../../features/wallet/data/models/saved_card_model.dart';
import '../../features/wallet/data/models/wallet_model.dart';
import '../../features/wallet/data/models/wallet_transaction_model.dart';
import 'stripe_payment_service.dart';

/// خدمة إدارة المحفظة والمعاملات المالية للراكب (Wallet Service) — Singleton
class WalletService {
  static final WalletService instance = WalletService._();
  WalletService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot>? _walletSubscription;
  StreamSubscription<QuerySnapshot>? _transactionsSubscription;
  StreamSubscription<QuerySnapshot>? _cardsSubscription;
  StreamSubscription<DocumentSnapshot>? _financialSettingsSubscription;

  static const int defaultPageSize = 10;
  static const double defaultIqdExchangeRate = 1310.0;

  double _iqdExchangeRate = defaultIqdExchangeRate;
  double get iqdExchangeRate => _iqdExchangeRate;

  final Map<String, double> _exchangeRates = {
    'IQ': 1310.0,
    'SY': 13000.0,
    'LB': 89500.0,
    'IR': 60000.0,
  };

  double getExchangeRate(String countryOrCurrency) {
    final key = countryOrCurrency.toUpperCase().trim();
    if (key == 'د.ع' || key == 'IQD' || key == 'IQ') {
      return _exchangeRates['IQ'] ?? 1310.0;
    }
    if (key == 'ل.س' || key == 'SYP' || key == 'SY') {
      return _exchangeRates['SY'] ?? 13000.0;
    }
    if (key == 'ل.ل' || key == 'LBP' || key == 'LB') {
      return _exchangeRates['LB'] ?? 89500.0;
    }
    if (key == 'تومان' || key == 'IRT' || key == 'IR') {
      return _exchangeRates['IR'] ?? 60000.0;
    }
    return _exchangeRates[key] ?? 1310.0;
  }

  DocumentSnapshot? _lastTransactionDoc;
  final List<WalletTransactionModel> _pageOneTransactions = [];
  final List<WalletTransactionModel> _olderTransactions = [];

  final ValueNotifier<WalletModel?> walletNotifier =
      ValueNotifier<WalletModel?>(null);
  final ValueNotifier<List<WalletTransactionModel>> transactionsNotifier =
      ValueNotifier([]);
  final ValueNotifier<List<SavedCardModel>> savedCardsNotifier = ValueNotifier(
    [],
  );
  final ValueNotifier<bool> hasMoreTransactionsNotifier = ValueNotifier(true);
  final ValueNotifier<bool> isLoadingMoreTransactionsNotifier = ValueNotifier(
    false,
  );

  WalletModel? get cachedWallet => walletNotifier.value;
  double get currentBalance => walletNotifier.value?.balance ?? 0.0;
  List<SavedCardModel> get savedCards => savedCardsNotifier.value;
  bool get hasMoreTransactions => hasMoreTransactionsNotifier.value;
  bool get isLoadingMoreTransactions => isLoadingMoreTransactionsNotifier.value;

  void _updateCombinedTransactions() {
    final Map<String, WalletTransactionModel> map = {
      for (final tx in _pageOneTransactions) tx.id: tx,
      for (final tx in _olderTransactions) tx.id: tx,
    };
    transactionsNotifier.value = map.values.toList();
  }

  /// بدء الاستماع الحي للمحفظة وسجل المعاملات والبطاقات
  void startListening(String userId) {
    if (userId.isEmpty) return;
    stopListening();

    _walletSubscription = _firestore
        .collection(AppConstants.walletsCollection)
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            walletNotifier.value = WalletModel.fromMap(
              snapshot.data() as Map<String, dynamic>,
              snapshot.id,
            );
          } else {
            _createInitialWallet(userId);
          }
        }, onError: (e) => debugPrint('❌ [WalletService] Wallet error: $e'));

    _transactionsSubscription = _firestore
        .collection(AppConstants.walletTransactionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(defaultPageSize)
        .snapshots()
        .listen(
          (query) {
            _pageOneTransactions.clear();
            for (final doc in query.docs) {
              _pageOneTransactions.add(
                WalletTransactionModel.fromMap(doc.data(), doc.id),
              );
            }
            if (_olderTransactions.isEmpty) {
              _lastTransactionDoc = query.docs.isNotEmpty
                  ? query.docs.last
                  : null;
              hasMoreTransactionsNotifier.value =
                  query.docs.length == defaultPageSize;
            }
            _updateCombinedTransactions();
          },
          onError: (e) =>
              debugPrint('❌ [WalletService] Transactions error: $e'),
        );

    _cardsSubscription = _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.savedCardsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (query) {
            savedCardsNotifier.value = query.docs
                .map((doc) => SavedCardModel.fromMap(doc.data(), doc.id))
                .toList();
          },
          onError: (e) => debugPrint('❌ [WalletService] Saved cards error: $e'),
        );

    _financialSettingsSubscription = _firestore
        .collection('settings')
        .doc('financial')
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              final data = snapshot.data() as Map<String, dynamic>;
              final dynamic rawRate = data['iqdExchangeRate'];
              if (rawRate is num && rawRate > 0) {
                _iqdExchangeRate = rawRate.toDouble();
                _exchangeRates['IQ'] = rawRate.toDouble();
              }
              final dynamic rawRates = data['exchangeRates'];
              if (rawRates is Map) {
                rawRates.forEach((k, v) {
                  if (v is num && v > 0) {
                    _exchangeRates[k.toString().toUpperCase()] = v.toDouble();
                  }
                });
              }
            }
          },
          onError: (e) =>
              debugPrint('⚠️ [WalletService] Financial settings error: $e'),
        );
  }

  /// تحميل الدفعة التالية من المعاملات الأقدم (Pagination)
  Future<void> loadMoreTransactions(
    String userId, {
    int pageSize = defaultPageSize,
  }) async {
    if (userId.isEmpty ||
        isLoadingMoreTransactionsNotifier.value ||
        !hasMoreTransactionsNotifier.value ||
        _lastTransactionDoc == null) {
      return;
    }
    isLoadingMoreTransactionsNotifier.value = true;
    try {
      final query = await _firestore
          .collection(AppConstants.walletTransactionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastTransactionDoc!)
          .limit(pageSize)
          .get();

      if (query.docs.isEmpty) {
        hasMoreTransactionsNotifier.value = false;
      } else {
        _lastTransactionDoc = query.docs.last;
        for (final doc in query.docs) {
          _olderTransactions.add(
            WalletTransactionModel.fromMap(doc.data(), doc.id),
          );
        }
        hasMoreTransactionsNotifier.value = query.docs.length == pageSize;
        _updateCombinedTransactions();
      }
    } catch (e) {
      debugPrint('❌ [WalletService] loadMoreTransactions error: $e');
    } finally {
      isLoadingMoreTransactionsNotifier.value = false;
    }
  }

  /// إعادة تحديث المعاملات إلى الصفحة الأولى
  void refreshTransactions(String userId) {
    _olderTransactions.clear();
    _lastTransactionDoc = null;
    hasMoreTransactionsNotifier.value = true;
    isLoadingMoreTransactionsNotifier.value = false;
    if (userId.isNotEmpty) startListening(userId);
  }

  /// إيقاف المستمعات وتصفير الذاكرة المؤقتة
  void stopListening() {
    _walletSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _cardsSubscription?.cancel();
    _financialSettingsSubscription?.cancel();
    _walletSubscription = null;
    _transactionsSubscription = null;
    _cardsSubscription = null;
    _financialSettingsSubscription = null;
    _pageOneTransactions.clear();
    _olderTransactions.clear();
    _lastTransactionDoc = null;
    hasMoreTransactionsNotifier.value = true;
    isLoadingMoreTransactionsNotifier.value = false;
  }

  /// تعيين وثيقة محفظة أولية للمستخدم في الذاكرة
  void _createInitialWallet(String userId) {
    final initial = WalletModel.initial(userId);
    walletNotifier.value = initial;
  }

  bool hasSufficientBalance(double requiredAmount) =>
      currentBalance >= requiredAmount;

  /// إضافة بطاقة دفع مع منع تضارب البطاقة الافتراضية
  Future<bool> addSavedCard({
    required String userId,
    required SavedCardModel card,
  }) async {
    try {
      final actualUserId = userId.isNotEmpty
          ? userId
          : (FirebaseAuth.instance.currentUser?.uid ?? '');
      if (actualUserId.isEmpty) return false;

      final paymentMethodId = card.paymentMethodId;
      if (paymentMethodId == null || paymentMethodId.isEmpty) return false;

      return await StripePaymentService.instance.attachPaymentMethodToCustomer(
        paymentMethodId: paymentMethodId,
        userId: actualUserId,
        cardId: card.id,
        isDefault: card.isDefault,
        userName: card.holderName,
      );
    } catch (e) {
      debugPrint('❌ [WalletService] addSavedCard error: $e');
      return false;
    }
  }

  /// حذف بطاقة وفصلها من Stripe وترقية البطاقة البديلة كافتراضية تلقائياً
  Future<bool> deleteSavedCard({
    required String userId,
    required String cardId,
  }) async {
    try {
      final actualUserId = userId.isNotEmpty
          ? userId
          : (FirebaseAuth.instance.currentUser?.uid ?? '');
      if (actualUserId.isEmpty || cardId.isEmpty) return false;

      return await StripePaymentService.instance
          .detachPaymentMethodFromCustomer(
            paymentMethodId: cardId,
            userId: actualUserId,
          );
    } catch (e) {
      debugPrint('❌ [WalletService] deleteSavedCard error: $e');
      return false;
    }
  }

  /// تعيين بطاقة كافتراضية وإلغاء الافتراضية عن بقية البطاقات
  Future<void> setDefaultCard({
    required String userId,
    required String cardId,
  }) async {
    try {
      final actualUserId = userId.isNotEmpty
          ? userId
          : (FirebaseAuth.instance.currentUser?.uid ?? '');
      if (actualUserId.isEmpty || cardId.isEmpty) return;

      await StripePaymentService.instance.setDefaultPaymentMethod(
        cardId: cardId,
        userId: actualUserId,
      );
    } catch (e) {
      debugPrint('❌ [WalletService] setDefaultCard error: $e');
    }
  }

  /// تهيئة المحفظة عند بدء تشغيل التطبيق أو تسجيل الدخول
  void initForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) startListening(user.uid);
  }
}
