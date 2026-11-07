/// الشاشة الرئيسية (Home Screen)
///
/// الشاشة الرئيسية للتطبيق تعرض الخريطة ولوحات حجز وتأكيد وتتبع الرحلة
/// تركز هذه الشاشة فقط على بناء الواجهات (View Layer) وترتبط بـ HomeController
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/location_service.dart';
import '../../trips/models/trip_request_model.dart';
import '../../trips/services/trip_request_service.dart';
import '../../profile/services/user_service.dart';
import '../../chat/screens/trip_chat_screen.dart';
import '../../profile/screens/coupons_gifts_screen.dart';
import '../../trips/widgets/trip_rating_dialog.dart';
import '../../trips/widgets/cancel_trip_dialog.dart';
import '../../trips/widgets/passenger_trip_completed_dialog.dart';
import '../controllers/home_controller.dart';
import '../widgets/map_widget.dart';
import '../widgets/home_components/home_app_bar.dart';
import '../widgets/home_components/home_after_pickup_sheet.dart';
import '../widgets/home_components/home_trip_confirmation_sheet.dart';
import '../widgets/home_components/home_active_trip_panel.dart';
import '../widgets/home_components/trip_options_modal_sheet.dart';
import '../widgets/home_components/home_pickup_selection_sheet.dart';
import '../widgets/home_components/home_destination_selection_sheet.dart';
import '../../../core/services/network_service.dart';
import '../../../core/widgets/dialogs/no_internet_dialog.dart';
import '../widgets/home_components/home_offline_banner.dart';
import '../widgets/home_components/no_drivers_found_dialog.dart';
import 'delivery_details_screen.dart';
import 'safety_screen.dart';

/// الشاشة الرئيسية
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final HomeController _controller;
  BitmapDescriptor? _carIcon;

  Future<void> _loadCarIcon() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/car_marker.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 45, // حجم 45 مطابق وموحد لكلا التطبيقين
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? byteData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData != null && mounted) {
        setState(() {
          _carIcon = BitmapDescriptor.bytes(byteData.buffer.asUint8List());
        });
      }
    } catch (e) {
      debugPrint('Error loading car icon in HomeScreen: $e');
    }
  }

  Set<Marker> _buildNearbyDriverMarkers() {
    final nearby = _controller.nearbyDrivers;
    if (nearby.isEmpty) return {};

    return nearby.entries.map((entry) {
      final driverId = entry.key;
      final driver = entry.value;
      return Marker(
        markerId: MarkerId('nearby_driver_$driverId'),
        position: driver.latLng,
        icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        rotation: driver.heading,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        infoWindow: const InfoWindow(title: 'سائق متاح'),
      );
    }).toSet();
  }

  @override
  void initState() {
    super.initState();
    _loadCarIcon();
    LanguageService.instance.addListener(_onLanguageChanged);
    WidgetsBinding.instance.addObserver(this);

    _controller = HomeController();
    _controller.onGpsRequired = ({required bool isPermission}) {
      if (mounted) {
        _showGpsRequiredDialog(isPermission: isPermission);
      }
    };
    _controller.onDriverCancelled = (trip) {
      if (mounted) {
        _handleDriverCancellation(trip);
      }
    };
    _controller.onTripCompleted = (trip) {
      if (mounted) {
        _handleTripCompleted(trip);
      }
    };
    _controller.onNoInternet = (onRetry) {
      if (mounted) {
        NoInternetDialog.show(
          context,
          onRetry: onRetry,
        );
      }
    };
    _controller.onSearchTimeout = () {
      if (mounted) {
        NoDriversFoundDialog.show(
          context,
          onRetry: () {
            _controller.confirmTrip();
          },
          onCancel: () {
            _controller.resetTripState();
          },
        );
      }
    };
    _controller.onShowMessage = (message, {bool isError = false, bool isWarning = false, bool isSuccess = false}) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: isError
                ? AppColors.error
                : isWarning
                    ? Colors.orange
                    : AppColors.success,
          ),
        );
      }
    };

    _controller.init(vsync: this);
    NetworkService.instance.startPeriodicCheck();
  }

  @override
  void dispose() {
    NetworkService.instance.stopPeriodicCheck();
    LanguageService.instance.removeListener(_onLanguageChanged);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NetworkService.instance.hasInternetConnection(forceRefresh: true);
      _controller.checkGpsAndRefreshLocation();
    }
  }

  // ==========================================
  // النوافذ الحوارية والتفاعلية (Dialogs & Sheets)
  // ==========================================

  /// إظهار حوار تفعيل خدمة الموقع (GPS) أو السماح بالإذن
  void _showGpsRequiredDialog({bool isPermission = false}) {
    if (!mounted) return;
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
            child: Text(l10n.cancel, style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isPermission ? l10n.openSettings : l10n.enableGps,
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة خيارات الرحلة الإضافية
  void _showTripOptionsDialog() {
    final basePrice = _controller.calculateBasePrice();
    _controller.syncActivePromos(basePrice);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TripOptionsModalSheet(
        secondDestinationAddress: _controller.secondDestinationAddress,
        hasSecondDestination: _controller.secondDestination != null,
        waitTime: _controller.waitTime,
        waitTimeOptions: _controller.waitTimeOptions,
        isRoundTrip: _controller.isRoundTrip,
        appliedCoupon: _controller.appliedCoupon,
        manualPromoCode: _controller.manualPromoCode,
        estimatedPrice: basePrice,
        onCalculatePrice: ({String? waitTime, bool isRoundTrip = false}) {
          return _controller.calculateBasePrice(
            customWaitTime: waitTime,
            customIsRoundTrip: isRoundTrip,
          );
        },
        onRemoveSecondDestination: _controller.removeSecondDestination,
        onSelectSecondDestination: () {
          Navigator.pop(context);
          _controller.startSelectingSecondDestination();
        },
        onWaitTimeChanged: _controller.setWaitTime,
        onRoundTripChanged: _controller.setRoundTrip,
        onPromoUpdated: _controller.updatePromo,
        onOpenCouponsGifts: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CouponsGiftsScreen()),
          );
          if (mounted) {
            setState(() {});
          }
        },
        onConfirm: (finalPrice, discountAmount, originalPrice) {
          _controller.confirmOptionsPrice(
            newFinalPrice: finalPrice,
            newDiscountAmount: discountAmount,
            newOriginalPrice: originalPrice,
          );
        },
      ),
    );
  }

  /// إضافة موقع مفضل
  Future<void> _addFavorite() async {
    if (_controller.selectedPickupLocation == null && _controller.currentAddress.isEmpty) return;

    final location = _controller.selectedPickupLocation ?? _controller.currentLocation;

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).addFavoriteLocation,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _controller.currentAddress,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).locationNameHint,
                hintStyle: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel, style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await _controller.addFavoriteLocation(
        name: name,
        location: location,
        address: _controller.currentAddress,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).locationAddedToFav, style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  /// الاتصال بالسائق
  Future<void> _callDriver() async {
    final phone = _controller.activeTrip?.driverPhone;
    if (phone == null) return;

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// فتح شاشة المحادثة
  void _openChat() async {
    if (_controller.activeTripId == null || _controller.activeTrip == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripChatScreen(
          tripId: _controller.activeTripId!,
          otherPartyName: _controller.activeTrip!.driverName ?? 'السائق',
          otherPartyPhotoUrl: _controller.activeTrip!.driverPhotoUrl,
          currentUserName: _controller.activeTrip!.passengerName,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  /// إلغاء الطلب النشط
  Future<void> _cancelActiveTrip() async {
    final status = _controller.activeTrip?.status ?? TripStatus.pending;

    final reason = await showCancelTripDialog(
      context,
      tripStatus: status,
    );

    if (reason != null) {
      final success = await _controller.cancelActiveTrip(reason);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).tripCancelledSuccessfully,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  /// معالجة إلغاء الطلب من قبل السائق
  Future<void> _handleDriverCancellation(TripRequestModel trip) async {
    final tripId = trip.id;
    final driverName = trip.driverName ?? 'السائق';
    _controller.resetTripState();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(dialogContext).tripCancelled, style: const TextStyle(fontFamily: 'Cairo')),
          ],
        ),
        content: Text(
          AppLocalizations.of(dialogContext).sorryTripCancelled,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(dialogContext).ok, style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (!mounted) return;

    final rating = await showTripRatingDialog(
      context: context,
      title: AppLocalizations.of(context).rateYourExperience,
      driverName: driverName,
    );

    if (rating != null) {
      try {
        await TripRequestService.instance.submitPassengerRating(
          tripId: tripId,
          rating: rating.rating,
          note: rating.note,
        );
      } catch (e) {
        debugPrint('Error submitting rating: $e');
      }
    }
  }

  /// معالجة إكمال الرحلة
  Future<void> _handleTripCompleted(TripRequestModel trip) async {
    final tripId = trip.id;
    final driverName = trip.driverName ?? AppLocalizations.of(context).theDriver;
    _controller.resetTripState();

    if (!mounted) return;

    // عرض فاتورة وتفاصيل إكمال الرحلة للراكب مع توضيح وسيلة الدفع (محفظة / كاش / بطاقة)
    await PassengerTripCompletedDialog.show(
      context,
      trip: trip,
      onContinue: () async {
        if (!mounted) return;
        final rating = await showTripRatingDialog(
          context: context,
          title: AppLocalizations.of(context).rateYourTrip,
          driverName: driverName,
        );

        if (rating != null) {
          try {
            await TripRequestService.instance.submitPassengerRating(
              tripId: tripId,
              rating: rating.rating,
              note: rating.note,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).thankYouForRating, style: const TextStyle(fontFamily: 'Cairo')),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error submitting rating: $e');
          }
        }
      },
    );
  }

  // ==========================================
  // بناء الواجهات (View Builders)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        Widget screenWidget;

        if (_controller.activeTripId != null && _controller.activeTrip != null) {
          screenWidget = _buildActiveTripScreen();
        } else if (_controller.isSelectingDestination) {
          screenWidget = _buildDestinationPickerScreen();
        } else if (_controller.pickupConfirmed && _controller.destination != null) {
          screenWidget = _buildTripSummaryScreen();
        } else if (_controller.pickupConfirmed) {
          screenWidget = _buildAfterPickupScreen();
        } else {
          screenWidget = _buildPickupSelectionScreen();
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) return;

            // 1. شاشة اختيار الوجهة
            if (_controller.isSelectingDestination) {
              if (_controller.destinationSheetExtent > 0.32) {
                _controller.destinationSheetController.animateTo(
                  0.28,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              } else {
                _controller.backToPickupConfirmed();
              }
              return;
            }

            // 2. شاشة اختيار نقطة الانطلاق (الرئيسية)
            if (!_controller.pickupConfirmed && _controller.activeTripId == null) {
              if (_controller.sheetExtent > 0.32) {
                _controller.sheetController.animateTo(
                  0.28,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
                return;
              }
            }

            // 3. شاشة ما بعد تأكيد نقطة الانطلاق وقبل اختيار الوجهة
            if (_controller.pickupConfirmed && _controller.destination == null && _controller.activeTripId == null) {
              _controller.backToPickupSelection();
              return;
            }

            // 4. الخروج من الشاشة أو التطبيق
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              SystemNavigator.pop();
            }
          },
          child: screenWidget,
        );
      },
    );
  }

  /// شاشة اختيار نقطة الانطلاق (الواجهة الرئيسية)
  Widget _buildPickupSelectionScreen() {
    return Scaffold(
      body: Stack(
        children: [
          // الخريطة
          GoogleMap(
            onMapCreated: _controller.onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _controller.currentLocation,
              zoom: AppConstants.defaultZoom,
            ),
            onCameraMove: _controller.onCameraMove,
            onCameraIdle: () => _controller.onCameraIdle(
              unknownFallback: AppLocalizations.of(context).unknownLocation,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            markers: _buildNearbyDriverMarkers(),
          ),

          // العلامة الثابتة في المنتصف
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 20,
                    color: AppColors.textPrimary,
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // شريط العنوان العلوي
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeAppBar(
              onBack: () => Navigator.pop(context),
              onMyLocation: () => _controller.fetchCurrentLocationAndMove(showDialogOnFailure: true),
            ),
          ),

          // شريط تنبيه انقطاع الإنترنت التفاعلي
          Positioned(
            top: 105,
            left: 0,
            right: 0,
            child: HomeOfflineBanner(
              onReconnected: () {
                _controller.fetchCurrentLocationAndMove(showDialogOnFailure: false);
              },
            ),
          ),

          // Bottom Sheet القابل للسحب
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              _controller.setSheetExtent(notification.extent);
              return true;
            },
            child: HomePickupSelectionSheet(
              sheetController: _controller.sheetController,
              sheetExtent: _controller.sheetExtent,
              searchController: _controller.searchController,
              isLoadingAddress: _controller.isLoadingAddress ||
                  _controller.isLoadingLocation ||
                  _controller.isMapMoving ||
                  _controller.currentAddress.isEmpty,
              isMapMoving: _controller.isMapMoving,
              currentAddress: _controller.currentAddress,
              searchResults: _controller.searchResults,
              isSearching: _controller.isSearching,
              favorites: _controller.favorites,
              province: UserService.instance.cachedUser?.province,
              onSearchChanged: _controller.searchPlaces,
              onSelectSearchResult: _controller.selectSearchResult,
              onSelectSuggestedLocation: _controller.moveToLocation,
              onAddFavorite: _addFavorite,
              onConfirmPickup: _controller.confirmPickupLocation,
              onCollapsedSearchTap: () {
                _controller.sheetController.animateTo(
                  0.5,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            ),
          ),

          // طبقة التحميل الشفافة
          IgnorePointer(
            ignoring: !_controller.isLoadingLocation,
            child: AnimatedOpacity(
              opacity: _controller.isLoadingLocation ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: AppColors.background,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppLocalizations.of(context).locatingYou,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).pleaseWait,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// شاشة بعد تأكيد نقطة الانطلاق (تعرض زر اختيار الوجهة)
  Widget _buildAfterPickupScreen() {
    return Scaffold(
      body: Stack(
        children: [
          // الخريطة
          GoogleMap(
            onMapCreated: _controller.onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _controller.currentLocation,
              zoom: AppConstants.defaultZoom,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('pickup'),
                position: _controller.currentLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              ),
              ..._buildNearbyDriverMarkers(),
            },
          ),

          // شريط العنوان العلوي
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeAppBar(
              onBack: _controller.backToPickupSelection,
              onMyLocation: () => _controller.fetchCurrentLocationAndMove(showDialogOnFailure: true),
            ),
          ),

          // شريط تنبيه انقطاع الإنترنت التفاعلي
          Positioned(
            top: 105,
            left: 0,
            right: 0,
            child: HomeOfflineBanner(
              onReconnected: () {
                _controller.fetchCurrentLocationAndMove(showDialogOnFailure: false);
              },
            ),
          ),

          // Bottom Sheet مع معلومات نقطة الانطلاق وزر تحديد الوجهة
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: HomeAfterPickupSheet(
              pickupAddress: _controller.currentAddress,
              onSelectDestination: _controller.startDestinationSelection,
            ),
          ),
        ],
      ),
    );
  }

  /// شاشة اختيار نقطة الوصول
  Widget _buildDestinationPickerScreen() {
    return Scaffold(
      body: Stack(
        children: [
          // الخريطة
          GoogleMap(
            onMapCreated: _controller.onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _controller.currentLocation,
              zoom: AppConstants.defaultZoom,
            ),
            onCameraMove: _controller.onDestinationCameraMove,
            onCameraIdle: _controller.onDestinationCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('pickup'),
                position: _controller.currentLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              ),
              ..._buildNearbyDriverMarkers(),
            },
          ),

          // العلامة الثابتة في المنتصف (حمراء للوجهة)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 20,
                    color: AppColors.textPrimary,
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // شريط العنوان العلوي
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppColors.textPrimary,
                        onPressed: _controller.backToPickupConfirmed,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        AppLocalizations.of(context).selectDestination,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.my_location_rounded),
                        color: AppColors.primary,
                        onPressed: () => _controller.fetchCurrentLocationAndMove(showDialogOnFailure: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // شريط تنبيه انقطاع الإنترنت التفاعلي
          Positioned(
            top: 105,
            left: 0,
            right: 0,
            child: HomeOfflineBanner(
              onReconnected: () {
                _controller.fetchCurrentLocationAndMove(showDialogOnFailure: false);
              },
            ),
          ),

          // Bottom Sheet القابل للسحب
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              _controller.setDestinationSheetExtent(notification.extent);
              return true;
            },
            child: HomeDestinationSelectionSheet(
              sheetController: _controller.destinationSheetController,
              sheetExtent: _controller.destinationSheetExtent,
              searchController: _controller.destinationSearchController,
              isLoadingAddress: _controller.isLoadingDestinationAddress,
              isMapMoving: _controller.isDestinationMapMoving,
              tempAddress: _controller.tempDestinationAddress,
              searchResults: _controller.destinationSearchResults,
              isSearching: _controller.isDestinationSearching,
              favorites: _controller.favorites,
              province: UserService.instance.cachedUser?.province,
              onSearchChanged: _controller.searchDestinationPlaces,
              onSelectSearchResult: _controller.selectDestinationSearchResult,
              onSelectSuggestedLocation: _controller.moveToLocation,
              onAddFavorite: _addFavorite,
              onConfirmDestination: () => _controller.confirmDestinationLocation(
                onNeedOptionsDialog: _showTripOptionsDialog,
              ),
              onCollapsedSearchTap: () {
                _controller.destinationSheetController.animateTo(
                  0.5,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// شاشة ملخص وتأكيد الرحلة
  Widget _buildTripSummaryScreen() {
    if (_controller.isLoadingRoute) {
      return Scaffold(
        body: Container(
          color: AppColors.background,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context).calculatingRoute,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).pleaseWait,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final estimatedDistance = _controller.getCappedEstimatedTotalDistance();
    final price = _controller.calculateBasePrice();
    _controller.syncActivePromos(price);
    if (!_controller.isWatchingNearbyDrivers) {
      _controller.startWatchingNearbyDrivers();
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // الجزء العلوي - الخريطة
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  MapWidget(
                    mapController: _controller.mapController,
                    onMapCreated: _controller.onMapCreated,
                    currentLocation: _controller.currentLocation,
                    destination: _controller.destination,
                    nearbyDrivers: _controller.nearbyDrivers,
                    polylinePoints: _controller.polylinePoints,
                    isLoadingLocation: _controller.isLoadingLocation,
                    onMyLocationPressed: () => _controller.fetchCurrentLocationAndMove(showDialogOnFailure: true),
                  ),

                  // شريط العنوان العلوي
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_taxi_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context).appName,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  color: AppColors.textPrimary,
                                  onPressed: _controller.backToPickupSelection,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: _showTripOptionsDialog,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.tune_rounded, color: AppColors.primary, size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            AppLocalizations.of(context).tripOptions,
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // شريط تنبيه انقطاع الإنترنت التفاعلي
                  Positioned(
                    top: 65,
                    left: 0,
                    right: 0,
                    child: HomeOfflineBanner(
                      onReconnected: () {
                        _controller.fetchCurrentLocationAndMove(showDialogOnFailure: false);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // الجزء السفلي - لوحة تأكيد الرحلة
            HomeTripConfirmationSheet(
              selectedTripType: _controller.selectedTripType,
              onTripTypeChanged: _controller.setTripType,
              isRoundTrip: _controller.isRoundTrip,
              waitTime: _controller.waitTime,
              formattedDistance: TripRequestService.instance.formatDistance(estimatedDistance),
              originalPrice: _controller.originalPrice ?? price,
              finalPrice: _controller.finalPrice,
              discountAmount: _controller.discountAmount ?? 0.0,
              appliedCoupon: _controller.appliedCoupon,
              selectedPaymentMethod: _controller.selectedPaymentMethod,
              onPaymentMethodChanged: (method) {
                _controller.setPaymentMethod(method);
                setState(() {});
              },
              onOpenTripOptions: _showTripOptionsDialog,
              onOpenPromos: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CouponsGiftsScreen()),
                );
                if (mounted) {
                  setState(() {});
                }
              },
              isCreatingTrip: _controller.isCreatingTrip,
              onConfirmTrip: () {
                if (_controller.selectedTripType == TripType.delivery) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeliveryDetailsScreen(
                        destinationAddress: _controller.destinationAddress ?? '',
                        onConfirm: (name, phone, desc, paid) {
                          Navigator.pop(context);
                          _controller.confirmTrip(
                            receiverName: name,
                            receiverPhone: phone,
                            packageDescription: desc,
                            paidByReceiver: paid,
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  _controller.confirmTrip();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// شاشة الرحلة النشطة (انتظار أو سائق في الطريق)
  Widget _buildActiveTripScreen() {
    if (_controller.activeTrip?.status == TripStatus.pending && !_controller.isWatchingNearbyDrivers) {
      _controller.startWatchingNearbyDrivers();
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  MapWidget(
                    mapController: _controller.mapController,
                    onMapCreated: _controller.onMapCreated,
                    currentLocation: _controller.currentLocation,
                    destination: _controller.destination,
                    driverLocation: _controller.driverLocation,
                    driverRotation: _controller.driverHeading,
                    nearbyDrivers: _controller.driverLocation == null ? _controller.nearbyDrivers : null,
                    polylinePoints: _controller.polylinePoints,
                    isLoadingLocation: _controller.isLoadingLocation,
                    searchRadiusMeters: _controller.currentSearchRadiusMeters,
                    isSearchingForDriver: _controller.isSearchingForDriver,
                    onMyLocationPressed: () => _controller.fetchCurrentLocationAndMove(showDialogOnFailure: true),
                  ),

                  // مؤشر اتجاه السائق عندما يكون خارج الشاشة
                  if (!_controller.isDriverVisible && _controller.driverLocation != null)
                    Builder(
                      builder: (context) {
                        final angle = _controller.getAngleToDriver();
                        final rad = angle * (math.pi / 180);
                        final alignX = math.sin(rad);
                        final alignY = -math.cos(rad);

                        return Align(
                          alignment: Alignment(alignX, alignY),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Transform.rotate(
                              angle: rad,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded),
                              color: AppColors.textPrimary,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_taxi_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context).appName,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (_controller.activeTrip?.status == TripStatus.pickedUp)
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.security_rounded),
                                color: AppColors.error,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SafetyScreen(trip: _controller.activeTrip!),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            HomeActiveTripPanel(
              activeTrip: _controller.activeTrip,
              totalDistance: _controller.activeTrip?.distance ?? _controller.getCappedEstimatedTotalDistance(),
              price: _controller.activeTrip?.price ?? _controller.finalPrice,
              paymentMethod: _controller.activeTrip?.paymentMethod ?? _controller.selectedPaymentMethod,
              searchRadiusKm: _controller.currentSearchRadiusKm,
              searchStageDescription: _controller.searchStageDescription,
              searchProgress: _controller.searchProgress,
              searchElapsedSeconds: _controller.searchElapsedSeconds,
              unreadMessagesCount: _controller.unreadMessagesCount,
              onCancelTrip: _cancelActiveTrip,
              onCallDriver: _callDriver,
              onChatWithDriver: _openChat,
            ),
          ],
        ),
      ),
    );
  }
}
