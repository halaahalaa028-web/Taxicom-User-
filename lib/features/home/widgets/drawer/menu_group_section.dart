import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// نموذج بيانات عنصر القائمة المجمعة
class MenuActionItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBgColor;
  final Widget? trailing;
  final bool isDestructive;

  const MenuActionItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.iconBgColor,
    this.trailing,
    this.isDestructive = false,
  });
}

/// بطاقة مجمعة فاخرة تحتوي على مجموعة من الخيارات مع فواصل أنيقة
class MenuGroupSection extends StatelessWidget {
  final String? sectionTitle;
  final List<MenuActionItem> items;

  const MenuGroupSection({
    super.key,
    this.sectionTitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sectionTitle != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 8),
              child: Text(
                sectionTitle!,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.border,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  indent: 64,
                  endIndent: 16,
                  color: AppColors.border.withValues(alpha: 0.6),
                ),
                itemBuilder: (context, index) {
                  return _MenuItemTile(item: items[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final MenuActionItem item;

  const _MenuItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = item.isDestructive
        ? Colors.red
        : (item.iconColor ?? AppColors.primary);
    final effectiveIconBgColor = item.isDestructive
        ? Colors.red.withValues(alpha: 0.1)
        : (item.iconBgColor ?? AppColors.primary.withValues(alpha: 0.08));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              // مربع الأيقونة الملون بنعومة
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: effectiveIconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: effectiveIconColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 14),

              // نصوص العنصر
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: item.isDestructive
                            ? Colors.red
                            : AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                          color: AppColors.textSecondary,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // الجزء الأخير (شارة أو سهم)
              if (item.trailing != null)
                item.trailing!
              else
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
