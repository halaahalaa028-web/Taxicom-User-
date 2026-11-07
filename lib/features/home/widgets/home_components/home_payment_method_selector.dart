import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/wallet_service.dart';
import '../../../trips/utils/trip_calculation_helper.dart';
import '../../../wallet/presentation/screens/user_wallet_screen.dart';
import '../../../wallet/presentation/widgets/add_card_sheet.dart';
import 'payment_method_option_tile.dart';

/// ويدجت اختيار وسيلة الدفع في شيت تأكيد الرحلة
class HomePaymentMethodSelector extends StatelessWidget {
  final String selectedPaymentMethod;
  final ValueChanged<String> onPaymentMethodChanged;
  final double tripPrice;
  final VoidCallback? onOpenWallet;

  const HomePaymentMethodSelector({
    super.key,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.tripPrice,
    this.onOpenWallet,
  });

  void _openAddCard(BuildContext context) {
    AddCardSheet.show(
      context,
      onSaveCard: (card) async {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final success = await WalletService.instance.addSavedCard(
          userId: uid,
          card: card,
        );
        if (success) {
          onPaymentMethodChanged('card:${card.id}');
        }
        return success;
      },
    );
  }

  void _openTopUp(BuildContext context) {
    if (onOpenWallet != null) {
      onOpenWallet!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const UserWalletScreen(autoOpenTopUp: true),
        ),
      );
    }
  }

  void _showPaymentSelectionSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final walletBalance = WalletService.instance.currentBalance;
    final isWalletSufficient = walletBalance >= tripPrice;
    final savedCards = WalletService.instance.savedCardsNotifier.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.paymentMethod,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. نقداً
                PaymentMethodOptionTile(
                  id: 'cash',
                  title: l10n.cash,
                  subtitle: 'الدفع نقداً للسائق عند انتهاء الرحلة',
                  icon: Icons.payments_rounded,
                  isSelected: selectedPaymentMethod == 'cash',
                  onTap: () {
                    onPaymentMethodChanged('cash');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),

                // 2. المحفظة
                PaymentMethodOptionTile(
                  id: 'wallet',
                  title: l10n.walletPayment,
                  subtitle: '${l10n.availableBalance} ${TripCalculationHelper.formatPrice(walletBalance)} ${l10n.currency}',
                  icon: Icons.account_balance_wallet_rounded,
                  isSelected: selectedPaymentMethod == 'wallet' && isWalletSufficient,
                  isWarning: !isWalletSufficient,
                  warningText: !isWalletSufficient
                      ? '${l10n.insufficientBalance} (مطلوب ${TripCalculationHelper.formatPrice(tripPrice)} ${l10n.currency})'
                      : null,
                  isDisabled: !isWalletSufficient,
                  trailingAction: !isWalletSufficient
                      ? GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _openTopUp(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_card_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'شحن الرصيد',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : null,
                  onTap: isWalletSufficient
                      ? () {
                          onPaymentMethodChanged('wallet');
                          Navigator.pop(ctx);
                        }
                      : () {
                          _openTopUp(context);
                        },
                ),
                const SizedBox(height: 16),

                // 3. البطاقات البنكية المباشرة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'البطاقات البنكية المباشرة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _openAddCard(context);
                      },
                      child: const Text(
                        '+ إضافة بطاقة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (savedCards.isEmpty)
                  PaymentMethodOptionTile(
                    id: 'add_card',
                    title: 'إضافة بطاقة بنكية',
                    subtitle: 'الدفع المباشر لكل رحلة عبر Visa أو Mastercard',
                    icon: Icons.credit_card_rounded,
                    isSelected: selectedPaymentMethod.startsWith('card:') || selectedPaymentMethod == 'stripe',
                    onTap: () {
                      Navigator.pop(ctx);
                      _openAddCard(context);
                    },
                  )
                else
                  ...savedCards.map((card) {
                    final cardKey = 'card:${card.id}';
                    final isSelected = selectedPaymentMethod == cardKey ||
                        (selectedPaymentMethod == 'stripe' && card.isDefault);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PaymentMethodOptionTile(
                        id: cardKey,
                        title: '${card.brand.toUpperCase()} (${card.maskedNumber})',
                        subtitle: card.isDefault ? 'البطاقة الافتراضية • تنتهي ${card.formattedExpiry}' : 'تنتهي ${card.formattedExpiry}',
                        icon: Icons.credit_card_rounded,
                        isSelected: isSelected,
                        onTap: () {
                          onPaymentMethodChanged(cardKey);
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMethodTitle(BuildContext context, String method) {
    final l10n = AppLocalizations.of(context);
    if (method == 'wallet') return l10n.walletPayment;
    if (method == 'cash') return l10n.cash;

    final cards = WalletService.instance.savedCardsNotifier.value;
    if (method.startsWith('card:')) {
      final cardId = method.replaceFirst('card:', '');
      final matched = cards.where((c) => c.id == cardId);
      if (matched.isNotEmpty) {
        final c = matched.first;
        return '${c.brand.toUpperCase()} (\u200E•••• ${c.last4}\u200E)';
      }
    }

    if (cards.isNotEmpty) {
      final def = cards.firstWhere((c) => c.isDefault, orElse: () => cards.first);
      return '${def.brand.toUpperCase()} (\u200E•••• ${def.last4}\u200E)';
    }

    return l10n.creditCard;
  }

  IconData _getMethodIcon(String method) {
    if (method == 'wallet') return Icons.account_balance_wallet_rounded;
    if (method == 'cash') return Icons.payments_rounded;
    return Icons.credit_card_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _getMethodTitle(context, selectedPaymentMethod);
    final icon = _getMethodIcon(selectedPaymentMethod);

    return GestureDetector(
      onTap: () => _showPaymentSelectionSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              '${l10n.paymentMethod}: ',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
