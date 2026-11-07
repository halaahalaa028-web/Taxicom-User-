/// شريط العنوان العلوي لشاشة البداية (Start App Bar)
///
/// تصميم مينيمالي عصري وأنيق بدون حدود خارجية وبدون اسم التطبيق،
/// يركز حصرياً على زر القائمة الجانبية وزر الإشعارات بمظهر حر ونظيف
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../notifications/screens/customer_messages_screen.dart';

class StartAppBar extends StatelessWidget {
  final Stream<int> unreadNotificationsStream;

  const StartAppBar({
    super.key,
    required this.unreadNotificationsStream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. زر فتح القائمة الجانبية الكاملة
          Builder(
            builder: (scaffoldContext) => Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Scaffold.of(scaffoldContext).openDrawer();
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notes_rounded,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // مساحة نظيفة وفارغة بدون اسم التطبيق لراحة العين والتركيز على البطاقة
          const Spacer(),

          // 2. زر الإشعارات مع شارة الأعداد
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerMessagesScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: StreamBuilder<int>(
                        stream: unreadNotificationsStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data! > 0) {
                            return Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                snapshot.data! > 9 ? '9+' : '${snapshot.data}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
