/// شريط البحث واختيار الموقع للشاشة الرئيسية
///
/// مكون مونوكروم موحد قابل لإعادة الاستخدام في اختيار نقطة الانطلاق والوصول
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

class HomeLocationSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isExpanded;
  final bool isLoading;
  final String currentAddress;
  final String placeholderText;
  final Color dotColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onCollapsedTap;

  const HomeLocationSearchBar({
    super.key,
    required this.controller,
    required this.isExpanded,
    required this.isLoading,
    required this.currentAddress,
    required this.placeholderText,
    this.dotColor = AppColors.primary,
    required this.onChanged,
    required this.onCollapsedTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة البحث
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: isExpanded
                ? TextField(
                    controller: controller,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.searchLocationHint,
                      hintStyle: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: onChanged,
                  )
                : GestureDetector(
                    onTap: onCollapsedTap,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: isLoading
                              ? Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      l10n.locating,
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  currentAddress.isNotEmpty ? currentAddress : placeholderText,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
