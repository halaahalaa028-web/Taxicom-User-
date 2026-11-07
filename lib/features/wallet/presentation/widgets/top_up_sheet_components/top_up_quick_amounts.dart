import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../trips/utils/trip_calculation_helper.dart';

/// مكون أزرار المبالغ السريعة لشحن الرصيد
class TopUpQuickAmounts extends StatelessWidget {
  final List<double> presetAmounts;
  final double selectedAmount;
  final ValueChanged<double> onSelect;

  const TopUpQuickAmounts({
    super.key,
    required this.presetAmounts,
    required this.selectedAmount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: presetAmounts.map((amt) {
        final isSelected = selectedAmount == amt;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: () => onSelect(amt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    TripCalculationHelper.formatPrice(amt),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
