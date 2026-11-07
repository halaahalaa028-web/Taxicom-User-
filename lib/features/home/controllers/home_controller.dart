/// متحكم الشاشة الرئيسية (Home Controller & Orchestrator)
///
/// يعمل كمنسق رئيسي (Facade / Orchestrator) يربط بين:
/// - إدارة الخريطة والموقع والبحث والـ Debouncers
/// - إدارة المسارات والتسعير عبر [HomeRouteManager]
/// - إدارة تتبع السائق والأنيميشن عبر [HomeDriverTrackingManager]
/// - إدارة دورة حياة الرحلة مع Firebase / Firestore
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/network_service.dart';
import '../../../core/services/places_service.dart';
import '../../../core/services/promo_service.dart';
import '../../../core/services/country_service.dart';
import '../../../core/services/driver_tracking_service.dart';
import '../../../core/services/wallet_service.dart';
import '../../trips/models/trip_request_model.dart';
import '../../trips/services/trip_request_service.dart';
import '../../profile/services/user_service.dart';
import '../../profile/models/user_model.dart';
import '../../profile/models/coupon_model.dart';
import '../../profile/screens/coupons_gifts_screen.dart';
import '../../chat/services/chat_service.dart';
import '../services/favorite_locations_service.dart';
import 'home_driver_tracking_manager.dart';
import 'home_route_manager.dart';
import 'home_search_radius_manager.dart';

class HomeController extends ChangeNotifier {
  // المدراء التخصصيون
  final HomeRouteManager _routeManager = HomeRouteManager();
  final HomeDriverTrackingManager _driverTrackingManager = HomeDriverTrackingManager();
  final HomeSearchRadiusManager _searchRadiusManager = HomeSearchRadiusManager();
  final ChatService _chatService = ChatService();

  // الخدمات الأساسية
  final LocationService _locationService = LocationService.instance;
  final TripRequestService _tripService = TripRequestService.instance;
  final UserService _userService = UserService.instance;
  final FavoriteLocationsService _favoritesService = FavoriteLocationsService.instance;
  final PlacesService _placesService = PlacesService.instance;

  // متحكم الخريطة والكاميرا
  GoogleMapController? mapController;
  double cameraBearing = 0.0;
  bool ignoreNextCameraIdle = false;
  bool ignoreNextDestinationCameraIdle = false;

  // حالة الموقع ونقطة الانطلاق
  LatLng currentLocation = const LatLng(AppConstants.samawahLat, AppConstants.samawahLng);
  LatLng? selectedPickupLocation;
  String currentAddress = '';
  bool isLoadingLocation = true;
  bool isLoadingAddress = true;
  bool isMapMoving = false;
  bool pickupConfirmed = false;
  Timer? _addressDebounceTimer;

  // حالة الوجهة والوجهة الثانية
  bool isSelectingDestination = false;
  LatLng? selectedDestinationLocation;
  String tempDestinationAddress = '';
  bool isLoadingDestinationAddress = false;
  bool isDestinationMapMoving = false;
  Timer? _destinationAddressDebounceTimer;

  LatLng? destination;
  String? destinationAddress;
  LatLng? secondDestination;
  String? secondDestinationAddress;
  bool isSelectingSecondDestination = false;
  String? waitTime;
  bool isRoundTrip = false;

  final List<String> waitTimeOptions = const [
    '0-5 دقائق',
    '5-10 دقائق',
    '10-20 دقيقة',
    '20-30 دقيقة',
    '30-45 دقيقة',
    '45-60 دقيقة',
  ];

  // الكوبونات والمكافآت والتسعير
  CouponModel? appliedCoupon;
  double? discountAmount;
  double? originalPrice;
  double finalPrice = 0.0;
  String manualPromoCode = '';
  TripType selectedTripType = TripType.ride;
  String selectedPaymentMethod = 'cash'; // 'cash', 'wallet', 'stripe', 'apple_pay'
  bool isCreatingTrip = false;

  // البحث والمواقع المفضلة
  final TextEditingController searchController = TextEditingController();
  List<PlaceSuggestion> searchResults = [];
  bool isSearching = false;
  Timer? _searchDebounceTimer;

  final TextEditingController destinationSearchController = TextEditingController();
  List<PlaceSuggestion> destinationSearchResults = [];
  bool isDestinationSearching = false;
  Timer? _destinationSearchDebounceTimer;

  List<FavoriteLocation> favorites = [];

  // الـ Bottom Sheets
  double sheetExtent = 0.28;
  final DraggableScrollableController sheetController = DraggableScrollableController();
  double destinationSheetExtent = 0.28;
  final DraggableScrollableController destinationSheetController = DraggableScrollableController();

  // تتبع الرحلة النشطة
  String? activeTripId;
  TripRequestModel? activeTrip;
  StreamSubscription? _tripSubscription;
  TickerProvider? _vsync;

  // عدد الرسائل غير المقروءة في المحادثة
  int unreadMessagesCount = 0;
  StreamSubscription<int>? _chatUnreadSubscription;

  void _startWatchingUnreadMessages(String tripId) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    _chatUnreadSubscription?.cancel();
    _chatUnreadSubscription = _chatService.watchUnreadCount(
      tripId: tripId,
      currentUserId: currentUserId,
    ).listen((count) {
      if (unreadMessagesCount != count) {
        unreadMessagesCount = count;
        notifyListeners();
      }
    });
  }

  void _stopWatchingUnreadMessages() {
    _chatUnreadSubscription?.cancel();
    _chatUnreadSubscription = null;
    unreadMessagesCount = 0;
  }

  // خصائص المسار المفوضة لـ HomeRouteManager
  List<LatLng> get polylinePoints => _routeManager.polylinePoints;
  set polylinePoints(List<LatLng> points) => _routeManager.polylinePoints = points;
  double? get distance => _routeManager.distance;
  set distance(double? dist) => _routeManager.distance = dist;
  double? get secondDestinationDistance => _routeManager.secondDestinationDistance;
  set secondDestinationDistance(double? dist) => _routeManager.secondDestinationDistance = dist;
  int? get estimatedDuration => _routeManager.estimatedDuration;
  set estimatedDuration(int? dur) => _routeManager.estimatedDuration = dur;
  int? get secondDestinationDuration => _routeManager.secondDestinationDuration;
  set secondDestinationDuration(int? dur) => _routeManager.secondDestinationDuration = dur;
  bool get isLoadingRoute => _routeManager.isLoadingRoute;
  set isLoadingRoute(bool val) => _routeManager.isLoadingRoute = val;

  // خصائص السائق المفوضة لـ HomeDriverTrackingManager
  LatLng? get driverLocation => _driverTrackingManager.driverLocation;
  double get driverHeading => _driverTrackingManager.driverHeading;
  bool get isDriverVisible => _driverTrackingManager.isDriverVisible;
  Map<String, DriverLocation> get nearbyDrivers => _driverTrackingManager.nearbyDrivers;

  // خصائص نطاق البحث والرادار المفوضة لـ HomeSearchRadiusManager
  double get currentSearchRadiusKm => _searchRadiusManager.currentSearchRadiusKm;
  double get currentSearchRadiusMeters => _searchRadiusManager.currentSearchRadiusMeters;
  String get searchStageDescription => _searchRadiusManager.searchStageDescription;
  double get searchProgress => _searchRadiusManager.searchProgress;
  int get searchElapsedSeconds => _searchRadiusManager.searchElapsedSeconds;
  bool get isSearchingForDriver => activeTrip != null && activeTrip!.status == TripStatus.pending;

  // ردود أفعال الواجهة (UI Callbacks)
  void Function({required bool isPermission})? onGpsRequired;
  void Function(TripRequestModel trip)? onDriverCancelled;
  void Function(TripRequestModel trip)? onTripCompleted;
  void Function()? onSearchTimeout;
  void Function(VoidCallback onRetry)? onNoInternet;
  void Function(String message, {bool isError, bool isWarning, bool isSuccess})? onShowMessage;

  // التهيئة والتخلص
  void init({required TickerProvider vsync}) {
    _vsync = vsync;
    initLocation();
    loadUserToCache();
    checkForPendingTrip();
    loadFavorites();
  }

  @override
  void dispose() {
    mapController?.dispose();
    _tripSubscription?.cancel();
    _stopWatchingUnreadMessages();
    _driverTrackingManager.dispose();
    _searchRadiusManager.dispose();
    _addressDebounceTimer?.cancel();
    _searchDebounceTimer?.cancel();
    searchController.dispose();
    _destinationAddressDebounceTimer?.cancel();
    _destinationSearchDebounceTimer?.cancel();
    destinationSearchController.dispose();
    sheetController.dispose();
    destinationSheetController.dispose();
    super.dispose();
  }

  // ==========================================
  // منطق الموقع والـ GPS
  // ==========================================
  Future<void> initLocation() async {
    final hasNet = await NetworkService.instance.hasInternetConnection(forceRefresh: true);
    if (!hasNet) {
      onNoInternet?.call(() => initLocation());
    }
    await fetchCurrentLocationAndMove(showDialogOnFailure: true);
  }

  Future<void> loadUserToCache() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _userService.loadCurrentUser(user.uid);
    }
  }

  Future<void> loadFavorites() async {
    favorites = await _favoritesService.getFavorites();
    notifyListeners();
  }

  Future<void> checkGpsAndRefreshLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final LocationPermission permission = await Geolocator.checkPermission();
    if (serviceEnabled &&
        (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always)) {
      if (currentAddress.isEmpty ||
          currentAddress == 'تعذر تحديد المكان' ||
          currentAddress == 'كركوك، العراق' ||
          isLoadingLocation) {
        await fetchCurrentLocationAndMove(showDialogOnFailure: false);
      }
    }
  }

  Future<void> fetchCurrentLocationAndMove({bool showDialogOnFailure = true}) async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!serviceEnabled ||
        permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      isLoadingLocation = false;
      notifyListeners();
      if (showDialogOnFailure) {
        onGpsRequired?.call(
          isPermission: permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever,
        );
      }
      return;
    }

    isLoadingLocation = true;
    notifyListeners();

    final Position? position = await _locationService.getCurrentPosition();
    if (position != null) {
      final realLoc = LatLng(position.latitude, position.longitude);
      currentLocation = realLoc;
      selectedPickupLocation = realLoc;
      isLoadingLocation = false;
      isLoadingAddress = true;
      notifyListeners();

      try {
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation, AppConstants.defaultZoom),
        );
      } catch (e) {
        debugPrint('⚠️ [Map] animateCamera failed: $e');
      }

      await getAddress();
      startWatchingNearbyDrivers();
    } else {
      isLoadingLocation = false;
      notifyListeners();
      if (showDialogOnFailure) {
        onGpsRequired?.call(isPermission: false);
      }
    }
  }

  Future<void> getAddress() async {
    final address = await _locationService.getAddressFromCoordinates(
      currentLocation.latitude,
      currentLocation.longitude,
    );
    currentAddress = address.isNotEmpty ? address : 'موقعك الحالي';
    isLoadingAddress = false;
    notifyListeners();
  }

  Future<void> getAddressForLocation(LatLng location, {String unknownFallback = 'موقع غير معروف'}) async {
    isLoadingAddress = true;
    notifyListeners();
    final address = await _locationService.getAddressFromCoordinates(
      location.latitude,
      location.longitude,
    );
    currentAddress = address.isNotEmpty ? address : unknownFallback;
    isLoadingAddress = false;
    notifyListeners();
  }

  Future<void> getDestinationAddressForLocation(LatLng location) async {
    isLoadingDestinationAddress = true;
    notifyListeners();
    final address = await _locationService.getAddressFromCoordinates(
      location.latitude,
      location.longitude,
    );
    tempDestinationAddress = address.isNotEmpty ? address : 'موقع غير معروف';
    isLoadingDestinationAddress = false;
    notifyListeners();
  }

  // ==========================================
  // أحداث الخريطة والكاميرا
  // ==========================================
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (!isLoadingLocation) {
      try {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation, AppConstants.defaultZoom),
        );
      } catch (e) {
        debugPrint('⚠️ [Map] onMapCreated animateCamera failed: $e');
      }
    }
  }

  void onCameraMove(CameraPosition position) {
    if (!pickupConfirmed) {
      selectedPickupLocation = position.target;
      isMapMoving = true;
      cameraBearing = position.bearing;
      notifyListeners();
    }
  }

  void onCameraIdle({String unknownFallback = 'موقع غير معروف'}) {
    if (isLoadingLocation) return;
    if (ignoreNextCameraIdle) {
      ignoreNextCameraIdle = false;
      isMapMoving = false;
      notifyListeners();
      return;
    }

    if (!pickupConfirmed && selectedPickupLocation != null) {
      isMapMoving = false;
      notifyListeners();

      _addressDebounceTimer?.cancel();
      _addressDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        getAddressForLocation(selectedPickupLocation!, unknownFallback: unknownFallback);
      });
    }
  }

  void onDestinationCameraMove(CameraPosition position) {
    selectedDestinationLocation = position.target;
    isDestinationMapMoving = true;
    notifyListeners();
  }

  void onDestinationCameraIdle() {
    if (ignoreNextDestinationCameraIdle) {
      ignoreNextDestinationCameraIdle = false;
      isDestinationMapMoving = false;
      notifyListeners();
      return;
    }

    if (selectedDestinationLocation != null) {
      isDestinationMapMoving = false;
      notifyListeners();

      _destinationAddressDebounceTimer?.cancel();
      _destinationAddressDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        getDestinationAddressForLocation(selectedDestinationLocation!);
      });
    }
  }

  void moveToLocation(LatLng location) {
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, AppConstants.defaultZoom),
    );
  }

  // ==========================================
  // المسار والاتجاهات والتسعير
  // ==========================================
  Future<void> getRoutePolyline() async {
    if (destination == null) return;
    await _routeManager.fetchRoutePolyline(
      origin: currentLocation,
      destination: destination!,
      secondDestination: secondDestination,
      onShowMessage: onShowMessage,
      onUpdate: notifyListeners,
    );
  }

  Future<void> getSecondDestinationRoute() async {
    if (destination == null || secondDestination == null) return;
    await _routeManager.fetchSecondDestinationRoute(
      destination: destination!,
      secondDestination: secondDestination!,
      onUpdate: notifyListeners,
    );
  }

  void fitBothMarkers() {
    _routeManager.fitBounds(
      mapController: mapController,
      origin: currentLocation,
      destination: destination,
    );
  }

  double getEstimatedTotalDistance() => _routeManager.getEstimatedTotalDistance();

  double getCappedEstimatedTotalDistance() {
    return _routeManager.getCappedEstimatedTotalDistance(
      pickup: currentLocation,
      destination: destination,
      secondDestination: secondDestination,
    );
  }

  int getEstimatedTotalDuration() => _routeManager.getEstimatedTotalDuration();

  double calculateBasePrice({String? customWaitTime, bool? customIsRoundTrip}) {
    return _routeManager.calculateBasePrice(
      pickup: currentLocation,
      destination: destination,
      secondDestination: secondDestination,
      waitTime: customWaitTime ?? waitTime,
      isRoundTrip: customIsRoundTrip ?? isRoundTrip,
    );
  }

  void syncActivePromos(double basePrice) {
    final activePromo = CouponsGiftsScreen.getActivePromo();
    if (activePromo != null && appliedCoupon == null && manualPromoCode.isEmpty) {
      if (activePromo['coupon'] is CouponModel) {
        appliedCoupon = activePromo['coupon'] as CouponModel;
      }
    }

    double discount = 0.0;
    if (appliedCoupon != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final validation = PromoService.instance.validateCoupon(
        coupon: appliedCoupon,
        tripPrice: basePrice,
        userId: userId,
      );
      if (validation.isValid) {
        discount = validation.discountAmount;
      } else {
        appliedCoupon = null;
      }
    }

    final double rawFinalPrice = math.max(0.0, basePrice - discount);
    final step = CountryService.instance.selectedCountry.roundingStep;
    if (step >= 1) {
      finalPrice = (rawFinalPrice / step).round() * step;
    } else if (step > 0) {
      final factor = (1 / step).round();
      finalPrice = (rawFinalPrice * factor).round() / factor;
    } else {
      finalPrice = rawFinalPrice;
    }
    discountAmount = discount > 0 ? (basePrice - finalPrice) : 0.0;
    originalPrice = basePrice;
  }

  // ==========================================
  // التنقل بين مراحل الحجز (Navigation / Steps)
  // ==========================================
  Future<void> confirmPickupLocation() async {
    final isConnected = await NetworkService.instance.hasInternetConnection();
    if (!isConnected) {
      if (onNoInternet != null) {
        onNoInternet!(() => confirmPickupLocation());
      } else {
        onShowMessage?.call(
          'لا يوجد اتصال بالإنترنت. يرجى تفعيل Wi-Fi أو بيانات الهاتف للمتابعة.',
          isError: true,
        );
      }
      return;
    }

    final newPickup = selectedPickupLocation ?? currentLocation;
    final pickupChanged = selectedPickupLocation != null &&
        (selectedPickupLocation!.latitude != currentLocation.latitude ||
            selectedPickupLocation!.longitude != currentLocation.longitude);

    currentLocation = newPickup;
    pickupConfirmed = true;
    isSelectingDestination = true;
    selectedDestinationLocation = currentLocation;
    tempDestinationAddress = '';
    destinationSearchResults.clear();
    destinationSearchController.clear();
    notifyListeners();

    if (pickupChanged && destination != null) {
      _routeManager.clearRoute(onUpdate: notifyListeners);
      _routeManager.isLoadingRoute = true;
      notifyListeners();

      getRoutePolyline().then((_) {
        _routeManager.isLoadingRoute = false;
        notifyListeners();
      });
    }
  }

  void backToPickupSelection() {
    stopWatchingNearbyDrivers();
    pickupConfirmed = false;
    isSelectingDestination = false;
    destination = null;
    destinationAddress = null;
    _routeManager.clearRoute(onUpdate: notifyListeners);
    secondDestination = null;
    secondDestinationAddress = null;
    waitTime = null;
    isRoundTrip = false;
    isSelectingSecondDestination = false;
    notifyListeners();
  }

  void startDestinationSelection() {
    isSelectingDestination = true;
    selectedDestinationLocation = currentLocation;
    tempDestinationAddress = '';
    destinationSearchResults.clear();
    destinationSearchController.clear();
    notifyListeners();
  }

  void backToPickupConfirmed() {
    isSelectingDestination = false;
    selectedDestinationLocation = null;
    tempDestinationAddress = '';
    destinationSearchResults.clear();
    notifyListeners();
  }

  Future<void> confirmDestinationLocation({VoidCallback? onNeedOptionsDialog}) async {
    if (selectedDestinationLocation == null) return;

    final isConnected = await NetworkService.instance.hasInternetConnection();
    if (!isConnected) {
      if (onNoInternet != null) {
        onNoInternet!(() => confirmDestinationLocation(onNeedOptionsDialog: onNeedOptionsDialog));
      } else {
        onShowMessage?.call(
          'لا يوجد اتصال بالإنترنت. يرجى تفعيل Wi-Fi أو بيانات الهاتف للمتابعة.',
          isError: true,
        );
      }
      return;
    }

    if (isSelectingSecondDestination) {
      final secondDest = selectedDestinationLocation!;
      final secondAddr = tempDestinationAddress;

      _routeManager.isLoadingRoute = true;
      secondDestination = secondDest;
      secondDestinationAddress = secondAddr;
      isSelectingDestination = false;
      isSelectingSecondDestination = false;
      _routeManager.secondDestinationDistance = null;
      notifyListeners();

      await getSecondDestinationRoute();

      _routeManager.isLoadingRoute = false;
      notifyListeners();

      if (onNeedOptionsDialog != null) {
        Future.delayed(const Duration(milliseconds: 300), onNeedOptionsDialog);
      }
      return;
    }

    _routeManager.isLoadingRoute = true;
    destination = selectedDestinationLocation;
    destinationAddress = tempDestinationAddress;
    isSelectingDestination = false;
    _routeManager.clearRoute(onUpdate: notifyListeners);
    notifyListeners();

    await getRoutePolyline();

    _routeManager.isLoadingRoute = false;
    notifyListeners();

    fitBothMarkers();
    startWatchingNearbyDrivers();
  }

  // ==========================================
  // خيارات الرحلة الإضافية
  // ==========================================
  void setTripType(TripType type) {
    selectedTripType = type;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    selectedPaymentMethod = method;
    notifyListeners();
  }

  void setWaitTime(String? value) {
    waitTime = value;
    notifyListeners();
  }

  void setRoundTrip(bool value) {
    isRoundTrip = value;
    notifyListeners();
  }

  void removeSecondDestination() {
    secondDestination = null;
    secondDestinationAddress = null;
    _routeManager.secondDestinationDistance = null;
    _routeManager.secondDestinationDuration = null;
    waitTime = null;
    notifyListeners();
  }

  void startSelectingSecondDestination() {
    isSelectingSecondDestination = true;
    isSelectingDestination = true;
    destinationSheetExtent = 0.28;
    destinationSearchResults = [];
    notifyListeners();
  }

  void updatePromo(CouponModel? coupon, String promoCode) {
    appliedCoupon = coupon;
    manualPromoCode = promoCode;
    notifyListeners();
  }

  void confirmOptionsPrice({
    required double newFinalPrice,
    required double newDiscountAmount,
    required double newOriginalPrice,
  }) {
    finalPrice = newFinalPrice;
    discountAmount = newDiscountAmount;
    originalPrice = newOriginalPrice;
    notifyListeners();
  }

  void setSheetExtent(double extent) {
    sheetExtent = extent;
    notifyListeners();
  }

  void setDestinationSheetExtent(double extent) {
    destinationSheetExtent = extent;
    notifyListeners();
  }

  // ==========================================
  // البحث والمواقع المفضلة
  // ==========================================
  void searchPlaces(String query) {
    _searchDebounceTimer?.cancel();
    if (query.isEmpty) {
      searchResults.clear();
      isSearching = false;
      notifyListeners();
      return;
    }

    isSearching = true;
    notifyListeners();

    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      searchResults = await _placesService.searchPlaces(
        query,
        location: selectedPickupLocation ?? currentLocation,
      );
      isSearching = false;
      notifyListeners();
    });
  }

  Future<void> selectSearchResult(PlaceSuggestion suggestion) async {
    isSearching = true;
    notifyListeners();

    final details = await _placesService.getPlaceDetails(suggestion.placeId);
    if (details != null) {
      ignoreNextCameraIdle = true;
      currentAddress = suggestion.description;
      moveToLocation(details.location);
      searchController.clear();
      searchResults.clear();
      isSearching = false;
      notifyListeners();

      sheetController.animateTo(
        0.28,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      isSearching = false;
      notifyListeners();
    }
  }

  void searchDestinationPlaces(String query) {
    _destinationSearchDebounceTimer?.cancel();
    if (query.isEmpty) {
      destinationSearchResults.clear();
      isDestinationSearching = false;
      notifyListeners();
      return;
    }

    isDestinationSearching = true;
    notifyListeners();

    _destinationSearchDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      destinationSearchResults = await _placesService.searchPlaces(
        query,
        location: selectedDestinationLocation ?? currentLocation,
      );
      isDestinationSearching = false;
      notifyListeners();
    });
  }

  Future<void> selectDestinationSearchResult(PlaceSuggestion suggestion) async {
    isDestinationSearching = true;
    notifyListeners();

    final details = await _placesService.getPlaceDetails(suggestion.placeId);
    if (details != null) {
      ignoreNextDestinationCameraIdle = true;
      tempDestinationAddress = suggestion.description;
      moveToLocation(details.location);
      destinationSearchController.clear();
      destinationSearchResults.clear();
      isDestinationSearching = false;
      notifyListeners();

      destinationSheetController.animateTo(
        0.28,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      isDestinationSearching = false;
      notifyListeners();
    }
  }

  Future<void> addFavoriteLocation({required String name, required LatLng location, required String address}) async {
    await _favoritesService.addFavorite(
      name: name,
      address: address,
      location: location,
    );
    await loadFavorites();
  }

  // ==========================================
  // إنشاء وإدارة الرحلة (Trip Lifecycle)
  // ==========================================
  Future<void> checkForPendingTrip() async {
    try {
      final trip = await _tripService.getActiveTripForPassenger();
      if (trip != null) {
        activeTripId = trip.id;
        activeTrip = trip;
        _startWatchingUnreadMessages(trip.id);
        destination = trip.destinationLocation;
        destinationAddress = trip.destinationAddress;
        _routeManager.distance = trip.distance;
        currentLocation = trip.pickupLocation;
        currentAddress = trip.pickupAddress;
        isLoadingAddress = false;
        _routeManager.clearRoute(onUpdate: notifyListeners);
        notifyListeners();

        getRoutePolyline();

        if (trip.status == TripStatus.accepted ||
            trip.status == TripStatus.arrivedAtPickup ||
            trip.status == TripStatus.pickedUp) {
          if (!_driverTrackingManager.isTracking) {
            startDriverTracking();
          }
        } else if (trip.status == TripStatus.pending) {
          _searchRadiusManager.startSearch(
            tripId: trip.id,
            createdAt: trip.createdAt,
            onUpdate: notifyListeners,
            onTimeout: () {
              resetTripState();
              onSearchTimeout?.call();
            },
          );
        }

        _tripSubscription = _tripService.watchTripRequest(trip.id).listen((updatedTrip) {
          if (updatedTrip != null) {
            activeTrip = updatedTrip;
            notifyListeners();

            if (updatedTrip.status != TripStatus.pending) {
              _searchRadiusManager.stopSearch();
            }

            if ((updatedTrip.status == TripStatus.accepted ||
                    updatedTrip.status == TripStatus.arrivedAtPickup ||
                    updatedTrip.status == TripStatus.pickedUp) &&
                !_driverTrackingManager.isTracking) {
              startDriverTracking();
            }

            if (updatedTrip.status == TripStatus.cancelledByDriver) {
              onDriverCancelled?.call(updatedTrip);
            }

            if (updatedTrip.status == TripStatus.completed) {
              _tripSubscription?.cancel();
              _tripSubscription = null;
              onTripCompleted?.call(updatedTrip);
            }
          }
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          fitBothMarkers();
        });
      }
    } catch (e) {
      debugPrint('Error checking for active trip: $e');
    }
  }

  Future<bool> confirmTrip({
    String? receiverName,
    String? receiverPhone,
    String? packageDescription,
    bool paidByReceiver = false,
  }) async {
    if (isCreatingTrip) return false;
    if (destination == null || distance == null) return false;

    isCreatingTrip = true;
    notifyListeners();

    final isConnected = await NetworkService.instance.hasInternetConnection();
    if (!isConnected) {
      isCreatingTrip = false;
      notifyListeners();
      if (onNoInternet != null) {
        onNoInternet!(() => confirmTrip(
          receiverName: receiverName,
          receiverPhone: receiverPhone,
          packageDescription: packageDescription,
          paidByReceiver: paidByReceiver,
        ));
      } else {
        onShowMessage?.call(
          'لا يوجد اتصال بالإنترنت. يرجى تفعيل Wi-Fi أو بيانات الهاتف للمتابعة.',
          isError: true,
        );
      }
      return false;
    }

    if (!LocationService.isWithinServiceArea(
      currentLocation.latitude,
      currentLocation.longitude,
    )) {
      onShowMessage?.call(
        'يجب أن يكون موقع الانطلاق داخل نطاق الخدمة (جميع محافظات العراق)',
        isError: true,
      );
      isCreatingTrip = false;
      notifyListeners();
      return false;
    }

    if (!LocationService.isWithinServiceArea(
      destination!.latitude,
      destination!.longitude,
    )) {
      onShowMessage?.call(
        'يجب أن يكون موقع الوصول داخل نطاق الخدمة (كركوك أو بغداد)',
        isError: true,
      );
      isCreatingTrip = false;
      notifyListeners();
      return false;
    }

    if (secondDestination != null &&
        !LocationService.isWithinServiceArea(
          secondDestination!.latitude,
          secondDestination!.longitude,
        )) {
      onShowMessage?.call(
        'يجب أن تكون الوجهة الثانية داخل نطاق الخدمة (كركوك أو بغداد)',
        isError: true,
      );
      isCreatingTrip = false;
      notifyListeners();
      return false;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        isCreatingTrip = false;
        notifyListeners();
        return false;
      }

      final UserModel? userData = await _userService.getUser(user.uid);
      if (userData == null) {
        isCreatingTrip = false;
        notifyListeners();
        return false;
      }

      final totalDistance = getCappedEstimatedTotalDistance();
      final effectivePrice = (discountAmount != null && discountAmount! > 0)
          ? finalPrice
          : calculateBasePrice();

      // التحقق من رصيد المحفظة في حال اختيار الدفع بالمحفظة
      if (selectedPaymentMethod == 'wallet' &&
          !WalletService.instance.hasSufficientBalance(effectivePrice)) {
        onShowMessage?.call(
          'رصيد المحفظة غير كافٍ لدفع أجرة الرحلة. يرجى شحن المحفظة أو اختيار طريقة دفع أخرى.',
          isError: true,
        );
        isCreatingTrip = false;
        notifyListeners();
        return false;
      }

      final tripId = await _tripService.createTripRequest(
        passengerName: userData.name,
        passengerPhone: userData.phone,
        pickupLocation: currentLocation,
        pickupAddress: currentAddress,
        destinationLocation: destination!,
        destinationAddress: destinationAddress!,
        distance: totalDistance,
        estimatedDuration: getEstimatedTotalDuration(),
        tripType: selectedTripType,
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        packageDescription: packageDescription,
        paidByReceiver: paidByReceiver,
        paymentMethod: selectedPaymentMethod,
        secondDestinationLocation: secondDestination,
        secondDestinationAddress: secondDestinationAddress,
        waitTime: waitTime,
        isRoundTrip: isRoundTrip,
        customPrice: discountAmount != null && discountAmount! > 0 ? finalPrice : null,
        couponCode: appliedCoupon?.code,
        couponId: appliedCoupon?.id,
        discountAmount: discountAmount,
        originalPrice: originalPrice,
      );

      activeTripId = tripId;
      _startWatchingUnreadMessages(tripId);
      appliedCoupon = null;
      discountAmount = null;
      originalPrice = null;
      finalPrice = 0.0;
      manualPromoCode = '';
      CouponsGiftsScreen.clearActivePromo();
      startWatchingNearbyDrivers(force: true);
      notifyListeners();

      _searchRadiusManager.startSearch(
        tripId: tripId,
        onUpdate: notifyListeners,
        onTimeout: () {
          resetTripState();
          onSearchTimeout?.call();
        },
      );

      _tripSubscription = _tripService.watchTripRequest(tripId).listen((trip) {
        if (trip != null) {
          activeTrip = trip;
          notifyListeners();

          if (trip.status != TripStatus.pending) {
            _searchRadiusManager.stopSearch();
          }

          if (trip.status == TripStatus.accepted && !_driverTrackingManager.isTracking) {
            startDriverTracking();
          }

          if (trip.status == TripStatus.cancelledByDriver) {
            onDriverCancelled?.call(trip);
          }

          if (trip.status == TripStatus.completed) {
            _tripSubscription?.cancel();
            _tripSubscription = null;
            onTripCompleted?.call(trip);
          }
        }
      });

      return true;
    } catch (e) {
      onShowMessage?.call('حدث خطأ: ${e.toString()}', isError: true);
      isCreatingTrip = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelActiveTrip(String reason) async {
    if (activeTripId == null) return false;
    _tripSubscription?.cancel();
    _searchRadiusManager.stopSearch();

    try {
      await _tripService.cancelTrip(activeTripId!, cancellationReason: reason);
      resetTripState();
      return true;
    } catch (e) {
      onShowMessage?.call('حدث خطأ: ${e.toString()}', isError: true);
      return false;
    }
  }

  void resetTripState() {
    _tripSubscription?.cancel();
    _tripSubscription = null;
    activeTripId = null;
    activeTrip = null;
    destination = null;
    destinationAddress = null;
    secondDestination = null;
    secondDestinationAddress = null;
    waitTime = null;
    isRoundTrip = false;
    pickupConfirmed = false;
    selectedTripType = TripType.ride;
    isCreatingTrip = false;
    _routeManager.reset();
    _driverTrackingManager.reset();
    _searchRadiusManager.reset();
    _stopWatchingUnreadMessages();
    startWatchingNearbyDrivers();
    notifyListeners();
  }

  // ==========================================
  // تتبع موقع وحركة السائق (Driver Tracking)
  // ==========================================
  bool get isWatchingNearbyDrivers => _driverTrackingManager.isWatchingNearbyDrivers;

  void startWatchingNearbyDrivers({bool force = false}) {
    if (!force && _driverTrackingManager.isWatchingNearbyDrivers) return;
    _driverTrackingManager.startWatchingNearbyDrivers(
      centerLocation: selectedPickupLocation ?? currentLocation,
      onUpdate: notifyListeners,
    );
  }

  void stopWatchingNearbyDrivers() {
    _driverTrackingManager.stopWatchingNearbyDrivers();
  }

  void startDriverTracking() {
    stopWatchingNearbyDrivers();
    final driverId = activeTrip?.driverId;
    if (driverId == null || _vsync == null) return;

    _driverTrackingManager.startTracking(
      driverId: driverId,
      vsync: _vsync!,
      onUpdate: notifyListeners,
      getMapController: () => mapController,
    );
  }

  double getAngleToDriver() {
    return _driverTrackingManager.getAngleToDriver(
      userLocation: currentLocation,
      cameraBearing: cameraBearing,
    );
  }

  void stopDriverTracking() {
    _driverTrackingManager.stopTracking();
  }
}
