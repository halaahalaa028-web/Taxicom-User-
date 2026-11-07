import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../trips/utils/trip_calculation_helper.dart';
import '../../data/models/wallet_transaction_model.dart';

/// قائمة الحركات المالية للمحفظة
class TransactionHistoryList extends StatelessWidget {
  final List<WalletTransactionModel> transactions;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  const TransactionHistoryList({
    super.key,
    required this.transactions,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
  });

  IconData _getTransactionIcon(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.topUp:
        return Icons.add_circle_outline_rounded;
      case WalletTransactionType.tripPayment:
        return Icons.local_taxi_rounded;
      case WalletTransactionType.refund:
        return Icons.replay_rounded;
      case WalletTransactionType.bonus:
        return Icons.card_giftcard_rounded;
      case WalletTransactionType.withdrawal:
        return Icons.arrow_outward_rounded;
    }
  }

  Color _getIconColor(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.topUp:
      case WalletTransactionType.refund:
      case WalletTransactionType.bonus:
        return AppColors.success;
      case WalletTransactionType.tripPayment:
      case WalletTransactionType.withdrawal:
        return AppColors.textPrimary;
    }
  }

  String _formatDate(DateTime dt) {
    return DateFormat('yyyy/MM/dd - hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentTransactions,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 44,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.noTransactions,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.noTransactionsDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isCredit = tx.isCredit;
              final formattedAmount = TripCalculationHelper.formatPrice(tx.amount);
              final sign = isCredit ? '+' : '-';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getIconColor(tx.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTransactionIcon(tx.type),
                        color: _getIconColor(tx.type),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.title.isNotEmpty ? tx.title : l10n.wallet,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(tx.createdAt),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$sign$formattedAmount ${tx.currency}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isCredit ? AppColors.success : AppColors.textPrimary,
                          ),
                        ),
                        if (tx.status != WalletTransactionStatus.completed)
                          Text(
                            tx.status.name,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: AppColors.warning,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        if (isLoadingMore)
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
