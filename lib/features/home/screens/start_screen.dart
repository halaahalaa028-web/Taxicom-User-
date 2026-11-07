/// شاشة البداية للتطبيق
/// 
/// شاشة رئيسية مخصصة وفائقة الأناقة لحجز وتتبع رحلات التكسي حصرياً
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/location_service.dart';
import '../../home/widgets/menu_bottom_sheet.dart';
import '../../notifications/services/notification_inbox_service.dart';
import '../../trips/models/trip_request_model.dart';
import '../../trips/services/trip_request_service.dart';
import '../widgets/start_components/start_app_bar.dart';
import '../widgets/start_components/start_active_trip_banner.dart';
import '../widgets/start_components/start_hero_taxi_card.dart';
import '../widgets/start_components/start_quick_actions.dart';
import '../widgets/start_components/start_safety_card.dart';
import 'home_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late Stream<int> _unreadNotificationsStream;
  late Stream<TripRequestModel?> _activeTripStream;

  @override
  void initState() {
    super.initState();
    LanguageService.instance.addListener(_onLanguageChanged);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _unreadNotificationsStream = NotificationService.instance.getCustomerUnreadCountStream(uid);
    _activeTripStream = TripRequestService.instance.watchPassengerActiveTrip();

    // التحقق عند الدخول للشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForActiveTrip();
    });
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkForActiveTrip() async {
    try {
      final activeTrip = await TripRequestService.instance.getActiveTripForPassenger();
      if (activeTrip != null && mounted) {
        _showActiveTripDialog();
      }
    } catch (e) {
      debugPrint('Error checking for active trip: $e');
    }
  }

  void _showActiveTripDialog() {
    if (!mounted) return;
    
    // التحقق من أن الشاشة الحالية هي الشاشة النشطة
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.local_taxi_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              l10n.appName,
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          l10n.activeTripDialogMessage,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleTaxiRequestClick();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              l10n.goToDetails,
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// التعامل مع الضغط على طلب تكسي (التحقق من GPS والإذن أولاً)
  Future<void> _handleTaxiRequestClick() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!serviceEnabled || permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showGpsRequiredDialog(
          isPermission: permission == LocationPermission.denied || permission == LocationPermission.deniedForever,
        );
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      ).then((_) => _checkForActiveTrip());
    }
  }

  /// إظهار حوار تفعيل خدمة الموقع (GPS)
  void _showGpsRequiredDialog({bool isPermission = false}) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              isPermission ? l10n.locationPermissionTitle : l10n.enableGpsTitle,
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          isPermission
              ? l10n.locationPermissionDialogDesc
              : l10n.enableGpsDialogDesc,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (isPermission) {
                await LocationService.instance.openAppSettings();
              } else {
                await LocationService.instance.openLocationSettings();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isPermission ? l10n.openSettings : l10n.enableGps,
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const MenuDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // 1. شريط العنوان العلوي (Header Bar)
            StartAppBar(
              unreadNotificationsStream: _unreadNotificationsStream,
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. شريط الرحلة النشطة الحية (Active Trip Banner)
                    StartActiveTripBanner(
                      activeTripStream: _activeTripStream,
                      onTap: _handleTaxiRequestClick,
                    ),

                    const SizedBox(height: 16),

                    // 3. البانر الرئيسي القيادي: طلب تكسي (Hero Taxi Card)
                    StartHeroTaxiCard(
                      key: ValueKey('hero_card_${l10n.language.code}'),
                      onTap: _handleTaxiRequestClick,
                    ),

                    const SizedBox(height: 28),

                    // 4. قسم الوصول السريع (Quick Actions)
                    Text(
                      l10n.quickServices,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    StartQuickActions(
                      key: ValueKey('quick_actions_${l10n.language.code}'),
                    ),

                    const SizedBox(height: 24),

                    // 5. بطاقة الأمان
                    StartSafetyCard(
                      key: ValueKey('safety_card_${l10n.language.code}'),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
