import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/wallet_service.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../trips/utils/trip_calculation_helper.dart';
import '../../data/models/saved_card_model.dart';
import '../utils/wallet_currency_helper.dart';
import 'top_up_confirmation_dialog.dart';
import 'top_up_sheet_components/top_up_quick_amounts.dart';
import 'top_up_sheet_components/top_up_saved_cards_list.dart';

/// نافذة منبثقة لشحن رصيد المحفظة بمبالغ مخصصة أو جاهزة مع اختيار البطاقة
class TopUpSheet extends StatefulWidget {
  final String currency;
  final List<SavedCardModel> savedCards;
  final SavedCardModel? selectedCard;
  final Function(SavedCardModel) onSelectCard;
  final VoidCallback onAddNewCard;
  final Function(double amount, String paymentMethod, SavedCardModel? card) onTopUpConfirm;
  final bool isLoading;

  const TopUpSheet({
    super.key,
    required this.currency,
    required this.savedCards,
    this.selectedCard,
    required this.onSelectCard,
    required this.onAddNewCard,
    required this.onTopUpConfirm,
    this.isLoading = false,
  });

  @override
  State<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<TopUpSheet> {
  final TextEditingController _amountController = TextEditingController();
  final List<double> _presetAmounts = [];
  double _selectedAmount = 100.0;
  bool _isSubmitting = false;
  String? _amountError;
  SavedCardModel? _localSelectedCard;

  @override
  void initState() {
    super.initState();
    final presets = WalletCurrencyHelper.getQuickAmounts(null, widget.currency);
    _presetAmounts.addAll(presets);
    _selectedAmount = WalletCurrencyHelper.getDefaultAmount(null, widget.currency);
    _amountController.text = TripCalculationHelper.formatPrice(_selectedAmount);
    _localSelectedCard = widget.selectedCard ?? (widget.savedCards.isNotEmpty ? widget.savedCards.first : null);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onPresetSelected(double amount) {
    if (_isSubmitting || widget.isLoading) return;
    setState(() {
      _selectedAmount = amount;
      _amountController.text = TripCalculationHelper.formatPrice(amount);
      _amountError = null;
    });
  }

  void _onAmountChanged(String val) {
    if (_isSubmitting || widget.isLoading) return;
    final cleaned = val.replaceAll(',', '').trim();
    final parsed = double.tryParse(cleaned);
    final minAmount = WalletCurrencyHelper.getMinAmount(null, widget.currency);
    if (parsed != null && parsed >= minAmount) {
      setState(() {
        _selectedAmount = parsed;
        _amountError = null;
      });
    } else {
      setState(() {
        _amountError = '${AppLocalizations.of(context).minTopUpAmount} (${TripCalculationHelper.formatPrice(minAmount)} ${widget.currency})';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting || widget.isLoading) return;

    final minAmount = WalletCurrencyHelper.getMinAmount(null, widget.currency);
    if (_selectedAmount < minAmount) {
      setState(() {
        _amountError = '${AppLocalizations.of(context).minTopUpAmount} (${TripCalculationHelper.formatPrice(minAmount)} ${widget.currency})';
      });
      return;
    }

    if (widget.savedCards.isEmpty) {
      widget.onAddNewCard();
      return;
    }

    // إظهار نافذة التأكيد قبل الخصم لمنع الضغط بالخطأ
    final confirmed = await TopUpConfirmationDialog.show(
      context,
      amount: _selectedAmount,
      currency: widget.currency,
      currentBalance: WalletService.instance.currentBalance,
      exchangeRate: WalletService.instance.iqdExchangeRate,
      selectedCard: _localSelectedCard,
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onTopUpConfirm(_selectedAmount, 'stripe', _localSelectedCard);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getButtonLabel() {
    final formatted = TripCalculationHelper.formatPrice(_selectedAmount);
    if (widget.savedCards.isEmpty) {
      return 'إضافة بطاقة وشحن $formatted ${widget.currency}';
    }
    return 'شحن $formatted ${widget.currency} الآن';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.topUpWallet,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: (_isSubmitting || widget.isLoading) ? null : () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.enterTopUpAmount,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _amountError != null ? AppColors.error : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: _onAmountChanged,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.currency,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_amountError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _amountError!,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  l10n.quickAmounts,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TopUpQuickAmounts(
                  presetAmounts: _presetAmounts,
                  selectedAmount: _selectedAmount,
                  onSelect: _onPresetSelected,
                ),
                const SizedBox(height: 14),
                TopUpSavedCardsList(
                  savedCards: widget.savedCards,
                  selectedCard: _localSelectedCard,
                  onSelectCard: (card) {
                    setState(() => _localSelectedCard = card);
                    widget.onSelectCard(card);
                  },
                  onAddNewCard: widget.onAddNewCard,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: _getButtonLabel(),
                  isLoading: widget.isLoading || _isSubmitting,
                  height: 50,
                  fontSize: 14,
                  icon: Icons.lock_outline_rounded,
                  backgroundColor: AppColors.primary,
                  textColor: Colors.white,
                  onPressed: (_isSubmitting || widget.isLoading) ? null : _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
