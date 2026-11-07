/// القائمة الجانبية الكاملة للتطبيق (Full-Page Animated Side Menu)
///
/// صفحة كاملة فاخرة تنزلق بنعومة من الجانب بالهوية الملكية والذهبية لتاكسيكوم
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/language_service.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../profile/models/user_model.dart';
import '../../profile/screens/coupons_gifts_screen.dart';
import '../../profile/screens/profile_details_screen.dart';
import '../../profile/services/user_service.dart';
import '../../wallet/presentation/screens/user_wallet_screen.dart';
import '../../settings/screens/about_screen.dart';
import '../../settings/screens/help_support_screen.dart';
import '../../settings/screens/language_settings_screen.dart';
import '../../trips/screens/my_trips_screen.dart';
import 'drawer/drawer_logout_dialog.dart';
import 'drawer/menu_group_section.dart';
import 'drawer/menu_legal_and_footer.dart';
import 'drawer/menu_profile_hero_card.dart';
import 'drawer/menu_top_app_bar.dart';

// رابط الشروط والأحكام للزبائن
const String _customerTermsUrl = 'https://sites.google.com/view/taxicoma/%D8%A7%D9%84%D8%B5%D9%81%D8%AD%D8%A9-%D8%A7%D9%84%D8%B1%D8%A6%D9%8A%D8%B3%D9%8A%D8%A9';
// رابط سياسة الخصوصية
const String _privacyUrl =
    'https://sites.google.com/view/taxicoma/%D8%A7%D9%84%D8%B5%D9%81%D8%AD%D8%A9-%D8%A7%D9%84%D8%B1%D8%A6%D9%8A%D8%B3%D9%8A%D8%A9';

/// فتح القائمة الجانبية الكاملة
void showMenuBottomSheet(BuildContext context) {
  Scaffold.of(context).openDrawer();
}

/// ويدجت القائمة الجانبية الكاملة (Full-Page Side Drawer)
class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

/// للتوافق مع المسميات السابقة
typedef MenuBottomSheet = MenuDrawer;

class _MenuDrawerState extends State<MenuDrawer> {
  String _userName = '';
  String _userPhone = '';
  UserModel? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// تحميل بيانات المستخدم من الكاش أو التخزين المحلي أو فايرستور
  Future<void> _loadUserData() async {
    var cachedUser = UserService.instance.cachedUser;
    cachedUser ??= await UserService.instance.loadUserFromLocalStorage();

    if (cachedUser != null && mounted) {
      setState(() {
        _userData = cachedUser;
        _userName = cachedUser!.name.isNotEmpty ? cachedUser.name : '';
        _userPhone = PhoneFormatter.format(cachedUser.phone);
      });
    }

    if (cachedUser == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await UserService.instance.loadCurrentUser(user.uid);
        cachedUser = UserService.instance.cachedUser;

        if (cachedUser != null && mounted) {
          setState(() {
            _userData = cachedUser;
            _userName = cachedUser!.name.isNotEmpty ? cachedUser.name : '';
            _userPhone = PhoneFormatter.format(cachedUser.phone);
          });
        }
      }
    }

    if (_userName.isEmpty && mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userName = user.displayName ?? '';
          _userPhone = PhoneFormatter.format(user.phoneNumber ?? '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final l10n = AppLocalizations.of(context);
    final currentLangName = LanguageService.instance.currentLanguage.name;

    return Drawer(
      width: screenWidth,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          // 1. الشريط العلوي مع زر الإغلاق وشعار تاكسيكوم
          MenuTopAppBar(
            onClose: () => Navigator.of(context).pop(),
          ),

          // 2. المحتوى التفاعلي القابل للتمرير
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بطاقة الملف الشخصي الملكية
                  MenuProfileHeroCard(
                    userData: _userData,
                    userName: _userName,
                    userPhone: _userPhone,
                    onTap: _navigateToProfile,
                  ),

                  const SizedBox(height: 8),

                  // القسم الأول: الخدمات والرحلات
                  MenuGroupSection(
                    sectionTitle: 'الخدمات والرحلات',
                    items: [
                      MenuActionItem(
                        icon: Icons.history_rounded,
                        iconColor: AppColors.primary,
                        title: l10n.myTrips,
                        subtitle: l10n.myTripsSubtitle,
                        onTap: _navigateToTrips,
                      ),
                      MenuActionItem(
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: const Color(0xFFD97706),
                        title: l10n.wallet,
                        subtitle: l10n.walletSubtitle,
                        onTap: _navigateToWallet,
                      ),
                      MenuActionItem(
                        icon: Icons.card_giftcard_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        title: l10n.couponsAndGifts,
                        subtitle: l10n.couponsAndGiftsSubtitle,
                        onTap: _navigateToCoupons,
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // القسم الثاني: الإعدادات والدعم
                  MenuGroupSection(
                    sectionTitle: 'الإعدادات والمساعدة',
                    items: [
                      MenuActionItem(
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF0284C7),
                        title: l10n.settings,
                        subtitle: l10n.settingsSubtitle,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.border,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            currentLangName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        onTap: _navigateToSettings,
                      ),
                      MenuActionItem(
                        icon: Icons.headset_mic_rounded,
                        iconColor: const Color(0xFF059669),
                        title: l10n.helpAndSupport,
                        subtitle: l10n.helpAndSupportSubtitle,
                        onTap: _navigateToHelp,
                      ),
                      MenuActionItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF64748B),
                        title: l10n.aboutApp,
                        subtitle: l10n.aboutAppSubtitle,
                        onTap: _navigateToAbout,
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // 3. القسم السفلي: زر تسجيل الخروج، الروابط القانونية، ورقم الإصدار
                  MenuLegalAndFooter(
                    onTermsTap: () => _openUrl(context, _customerTermsUrl),
                    onPrivacyTap: () => _openUrl(context, _privacyUrl),
                    onLogoutTap: () => showDrawerLogoutDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile() {
    if (_userData != null) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileDetailsScreen(user: _userData!),
        ),
      );
    }
  }

  void _navigateToTrips() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyTripsScreen()),
    );
  }

  void _navigateToWallet() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserWalletScreen()),
    );
  }

  void _navigateToCoupons() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CouponsGiftsScreen()),
    );
  }

  void _navigateToSettings() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()),
    );
  }

  void _navigateToHelp() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
    );
  }

  void _navigateToAbout() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutScreen()),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    Navigator.pop(context);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر فتح الرابط',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
