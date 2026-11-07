import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../data/models/saved_card_model.dart';

/// مكون قائمة البطاقات المحفوظة لشحن الرصيد
class TopUpSavedCardsList extends StatelessWidget {
  final List<SavedCardModel> savedCards;
  final SavedCardModel? selectedCard;
  final ValueChanged<SavedCardModel> onSelectCard;
  final VoidCallback onAddNewCard;

  const TopUpSavedCardsList({
    super.key,
    required this.savedCards,
    required this.selectedCard,
    required this.onSelectCard,
    required this.onAddNewCard,
  });

  @override
  Widget build(BuildContext context) {
    if (savedCards.isEmpty) {
      return InkWell(
        onTap: onAddNewCard,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'إضافة بطاقة بنكية للشحن الفوري',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'اختر البطاقة للخصم:',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: onAddNewCard,
              child: const Text(
                '+ بطاقة أخرى',
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
        ...savedCards.map((card) {
          final isSelected = (selectedCard?.id == card.id) ||
              (selectedCard == null && card.isDefault);
          return GestureDetector(
            onTap: () => onSelectCard(card),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card_rounded,
                    size: 18,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${card.brand.toUpperCase()} (\u200E•••• ${card.last4}\u200E)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
