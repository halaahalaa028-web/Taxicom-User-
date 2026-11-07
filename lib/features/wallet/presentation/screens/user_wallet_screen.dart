import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/wallet_service.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../trips/utils/trip_calculation_helper.dart';
import '../controllers/wallet_controller.dart';
import '../widgets/add_card_sheet.dart';
import '../widgets/saved_cards_list.dart';
import '../widgets/top_up_sheet.dart';
import '../widgets/transaction_history_list.dart';
import '../widgets/wallet_balance_card.dart';

/// الشاشة الرئيسية لمحفظة الراكب (User Wallet Screen)
class UserWalletScreen extends StatefulWidget {
  final bool autoOpenTopUp;

  const UserWalletScreen({
    super.key,
    this.autoOpenTopUp = false,
  });

  @override
  State<UserWalletScreen> createState() => _UserWalletScreenState();
}

class _UserWalletScreenState extends State<UserWalletScreen> {
  late final WalletController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = WalletController();
    _controller.addListener(_onControllerUpdate);
    _scrollController.addListener(_onScroll);

    if (widget.autoOpenTopUp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showTopUpSheet();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      if (_controller.hasMoreTransactions && !_controller.isLoadingMoreTransactions) {
        _controller.loadMoreTransactions();
      }
    }
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _showTopUpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !_controller.isProcessingTopUp,
      enableDrag: !_controller.isProcessingTopUp,
      builder: (ctx) => TopUpSheet(
        currency: _controller.currency,
        savedCards: _controller.savedCards,
        selectedCard: _controller.selectedCard,
        onSelectCard: _controller.setSelectedCard,
        onAddNewCard: () {
          Navigator.pop(ctx);
          _showAddCardSheet();
        },
        isLoading: _controller.isProcessingTopUp,
        onTopUpConfirm: (amount, paymentMethod, card) async {
          if (card != null) {
            _controller.setSelectedCard(card);
          }
          final paymentMethodId = paymentMethod == 'stripe' ? (card?.paymentMethodId ?? _controller.selectedCard?.paymentMethodId) : null;
          final success = await _controller.topUpWallet(
            amount: amount,
            paymentMethodId: paymentMethodId,
          );

          if (ctx.mounted) {
            Navigator.pop(ctx);
          }

          if (!mounted) return;

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${AppLocalizations.of(context).topUpSuccess} (${TripCalculationHelper.formatPrice(amount)} ${_controller.currency})',
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (_controller.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _controller.errorMessage!,
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      ),
    );
  }

  void _showAddCardSheet() {
    AddCardSheet.show(
      context,
      onSaveCard: (card) async {
        final success = await _controller.addSavedCard(card);
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمت إضافة البطاقة بنجاح!', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return success;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_controller.isProcessingTopUp,
      child: LoadingOverlay(
        isLoading: _controller.isProcessingTopUp,
        message: 'جاري معالجة شحن المحفظة بأمان...',
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            centerTitle: true,
            title: Text(
              l10n.wallet,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: _controller.isProcessingTopUp
                    ? AppColors.textSecondary.withValues(alpha: 0.3)
                    : AppColors.textPrimary,
              ),
              onPressed: _controller.isProcessingTopUp ? null : () => Navigator.pop(context),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _controller.refreshTransactions,
            color: AppColors.primary,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بطاقة الرصيد
                  WalletBalanceCard(
                    balance: _controller.balance,
                    currency: _controller.currency,
                    onTopUpPressed: _showTopUpSheet,
                  ),

                  const SizedBox(height: 24),

                  // قائمة البطاقات المحفوظة
                  ValueListenableBuilder(
                    valueListenable: WalletService.instance.savedCardsNotifier,
                    builder: (context, cards, _) {
                      return SavedCardsList(
                        cards: cards,
                        onSelectCard: _controller.setSelectedCard,
                        onDeleteCard: (id) async {
                          await _controller.deleteSavedCard(id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.cardDeleteSuccess,
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
                                backgroundColor: AppColors.textPrimary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        onSetDefaultCard: _controller.setDefaultCard,
                        onAddCard: _showAddCardSheet,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // سجل المعاملات المالية
                  TransactionHistoryList(
                    transactions: _controller.transactions,
                    isLoadingMore: _controller.isLoadingMoreTransactions,
                    hasMore: _controller.hasMoreTransactions,
                    onLoadMore: _controller.loadMoreTransactions,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
