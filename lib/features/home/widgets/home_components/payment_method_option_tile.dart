import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// عنصر خيار طريقة الدفع في شيت اختيار وسيلة الدفع
class PaymentMethodOptionTile extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isWarning;
  final String? warningText;
  final bool isDisabled;
  final Widget? trailingAction;

  const PaymentMethodOptionTile({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isWarning = false,
    this.warningText,
    this.isDisabled = false,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.surfaceVariant.withValues(alpha: 0.5)
              : (isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.background),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDisabled
                ? AppColors.border.withValues(alpha: 0.6)
                : (isSelected ? AppColors.primary : AppColors.border),
            width: isSelected && !isDisabled ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDisabled
                    ? AppColors.border.withValues(alpha: 0.4)
                    : (isSelected ? AppColors.primary : AppColors.surface),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : (isSelected ? Colors.white : AppColors.textPrimary),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDisabled ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                      if (isDisabled) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'غير متاح',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: isDisabled
                          ? AppColors.textSecondary.withValues(alpha: 0.7)
                          : (isWarning ? AppColors.warning : AppColors.textSecondary),
                    ),
                  ),
                  if (warningText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        warningText!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailingAction != null) ...[
              const SizedBox(width: 8),
              trailingAction!,
            ] else
              Icon(
                isDisabled
                    ? Icons.block_rounded
                    : (isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                color: isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : (isSelected ? AppColors.primary : AppColors.textSecondary),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
