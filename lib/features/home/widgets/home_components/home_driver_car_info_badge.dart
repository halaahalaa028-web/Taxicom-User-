import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

/// بطاقة عرض بيانات سيارة السائق (الموديل، اللون، ورقم اللوحة)
class HomeDriverCarInfoBadge extends StatelessWidget {
  final String? carNumber;
  final String? carModel;
  final String? carColor;
  final String? carType;

  const HomeDriverCarInfoBadge({
    super.key,
    this.carNumber,
    this.carModel,
    this.carColor,
    this.carType,
  });

  /// التحقق من توفر أي معلومات عن السيارة
  bool get hasCarInfo =>
      (carNumber != null && carNumber!.trim().isNotEmpty) ||
      (carModel != null && carModel!.trim().isNotEmpty) ||
      (carColor != null && carColor!.trim().isNotEmpty) ||
      (carType != null && carType!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final modelText = (carModel != null && carModel!.trim().isNotEmpty)
        ? carModel!.trim()
        : (carType != null && carType!.trim().isNotEmpty)
            ? carType!.trim()
            : null;

    final colorText = (carColor != null && carColor!.trim().isNotEmpty) ? carColor!.trim() : null;

    final carDescription = [
      if (modelText != null) modelText,
      if (colorText != null) colorText,
    ].join(' - ');

    final plateText = (carNumber != null && carNumber!.trim().isNotEmpty) ? carNumber!.trim() : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          // أيقونة السيارة
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),

          // موديل ولون السيارة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  carDescription.isNotEmpty ? carDescription : l10n.unknownCar,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l10n.carDetails,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // لوحة أرقام السيارة المميزة
          if (plateText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tag_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    plateText,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
