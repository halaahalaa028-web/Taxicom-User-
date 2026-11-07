/// نظام الترجمة والتوطين
/// 
/// يدير الترجمات للغات المدعومة
library;

import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../services/country_service.dart';
import 'translations/ar.dart';
import 'translations/en.dart';
import 'translations/ku.dart';
import 'translations/ru.dart';
import 'translations/de.dart';
import 'translations/fr.dart';
import 'translations/it.dart';
import 'translations/es.dart';
import 'translations/tr.dart';
import 'translations/zh.dart';
import 'translations/fa.dart';
import 'translations/hi.dart';

/// فئة الترجمة الرئيسية
class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  /// الحصول على instance من context
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(LanguageService.instance.currentLanguage);
  }

  /// الحصول على النصوص حسب اللغة الحالية
  Map<String, String> get _strings {
    switch (language) {
      case AppLanguage.arabic:
        return arStrings;
      case AppLanguage.english:
        return enStrings;
      case AppLanguage.kurdish:
        return kuStrings;
      case AppLanguage.russian:
        return ruStrings;
      case AppLanguage.german:
        return deStrings;
      case AppLanguage.french:
        return frStrings;
      case AppLanguage.italian:
        return itStrings;
      case AppLanguage.spanish:
        return esStrings;
      case AppLanguage.turkish:
        return trStrings;
      case AppLanguage.chinese:
        return zhStrings;
      case AppLanguage.persian:
        return faStrings;
      case AppLanguage.hindi:
        return hiStrings;
    }
  }

  /// الحصول على نص مترجم
  String get(String key) {
    return _strings[key] ?? arStrings[key] ?? key;
  }

  /// هل اتجاه اللغة الحالية من اليمين لليسار
  bool get isRtl => language.isRtl;

  // === الوصول المباشر للنصوص ===

  // اسم التطبيق
  String get appName => get('appName');

  // شاشة تسجيل الدخول
  String get loginTitle => get('loginTitle');
  String get loginSubtitle => get('loginSubtitle');
  String get phoneHint => get('phoneHint');
  String get sendCode => get('sendCode');
  String get countryCode => get('countryCode');
  String get selectCountry => get('selectCountry');
  String get searchCountry => get('searchCountry');
  String get noCountriesFound => get('noCountriesFound');

  // شاشة التحقق من الرمز
  String get otpTitle => get('otpTitle');
  String get otpSubtitle => get('otpSubtitle');
  String get verify => get('verify');
  String get resendCode => get('resendCode');
  String get resendIn => get('resendIn');
  String get seconds => get('seconds');

  // شاشة الملف الشخصي
  String get profileTitle => get('profileTitle');
  String get nameField => get('nameField');
  String get nameHint => get('nameHint');
  String get emailField => get('emailField');
  String get emailHint => get('emailHint');
  String get addressField => get('addressField');
  String get addressFieldRequired => get('addressFieldRequired');
  String get addressHint => get('addressHint');
  String get addressError => get('addressError');
  String get genderField => get('genderField');
  String get genderFieldRequired => get('genderFieldRequired');
  String get male => get('male');
  String get female => get('female');
  String get genderError => get('genderError');
  String get birthDateField => get('birthDateField');
  String get birthDateFieldRequired => get('birthDateFieldRequired');
  String get birthDateHint => get('birthDateHint');
  String get birthDateError => get('birthDateError');
  String get save => get('save');

  // الصورة الشخصية
  String get fullNameField => get('fullNameField');
  String get fullNameHint => get('fullNameHint');
  String get profilePhotoField => get('profilePhotoField');
  String get profilePhotoError => get('profilePhotoError');
  String get uploadingPhoto => get('uploadingPhoto');
  String get chooseFromGallery => get('chooseFromGallery');
  String get takePhoto => get('takePhoto');

  // الشاشة الرئيسية
  String get whereAmI => get('whereAmI');
  String get currentLocationHint => get('currentLocationHint');
  String get whereToGo => get('whereToGo');
  String get destinationHint => get('destinationHint');
  String get estimatedPrice => get('estimatedPrice');
  String get confirmTrip => get('confirmTrip');
  String get pickupPoint => get('pickupPoint');
  String get destinationPoint => get('destinationPoint');
  String get confirmTripBtn => get('confirmTripBtn');
  String get selectDestinationPoint => get('selectDestinationPoint');
  String get confirmPickupPoint => get('confirmPickupPoint');
  String get currency => language == AppLanguage.english
      ? CountryService.instance.selectedCountry.currencyEn
      : CountryService.instance.selectedCountry.currencyAr;
  String get distance => get('distance');
  String get km => get('km');

  // صفحة حجز التكسي
  String get selectDestination => get('selectDestination');
  String get confirmDestination => get('confirmDestination');
  String get moveMapToSelectLocation => get('moveMapToSelectLocation');
  String get selectPickup => get('selectPickup');
  String get confirmPickup => get('confirmPickup');
  String get searchingForDriver => get('searchingForDriver');
  String get driverAccepted => get('driverAccepted');
  String get driverOnTheWay => get('driverOnTheWay');
  String get tripInProgress => get('tripInProgress');
  String get tripCompleted => get('tripCompleted');
  String get cancelTrip => get('cancelTrip');
  String get callDriver => get('callDriver');
  String get chatWithDriver => get('chatWithDriver');
  String get waitAMoment => get('waitAMoment');
  String get price => get('price');
  String get tripCancelled => get('tripCancelled');
  String get sorryTripCancelled => get('sorryTripCancelled');
  String get rateYourExperience => get('rateYourExperience');
  String get rateYourTrip => get('rateYourTrip');
  String get thankYouForRating => get('thankYouForRating');
  String get confirmRequest => get('confirmRequest');
  String get driverFoundMessage => get('driverFoundMessage');
  String get theDriver => get('theDriver');
  String get cancelForDriverContact => get('cancelForDriverContact');

  // رسائل الخطأ
  String get phoneError => get('phoneError');
  String get otpError => get('otpError');
  String get nameError => get('nameError');
  String get generalError => get('generalError');
  String get locationError => get('locationError');
  String get connectionError => get('connectionError');

  // رسائل النجاح
  String get saveSuccess => get('saveSuccess');
  String get codeSent => get('codeSent');

  // حالات التحميل
  String get loading => get('loading');
  String get sending => get('sending');
  String get verifying => get('verifying');
  String get saving => get('saving');

  // نظام المصادقة
  String get password => get('password');
  String get passwordHint => get('passwordHint');
  String get confirmPassword => get('confirmPassword');
  String get confirmPasswordHint => get('confirmPasswordHint');
  String get login => get('login');
  String get createAccount => get('createAccount');
  String get chooseAccountType => get('chooseAccountType');
  String get asCustomer => get('asCustomer');
  String get customerDescription => get('customerDescription');
  String get passwordError => get('passwordError');
  String get passwordMismatch => get('passwordMismatch');
  String get phoneAlreadyExists => get('phoneAlreadyExists');
  String get noAccount => get('noAccount');
  String get haveAccount => get('haveAccount');
  String get registerTitle => get('registerTitle');
  String get loggingIn => get('loggingIn');
  String get creatingAccount => get('creatingAccount');
  String get accountData => get('accountData');
  String get personalData => get('personalData');
  String get termsAgree => get('termsAgree');
  String get editProfile => get('editProfile');
  String get logout => get('logout');

  // القائمة الجانبية
  String get myTrips => get('myTrips');
  String get myTripsSubtitle => get('myTripsSubtitle');
  String get offersAndDiscounts => get('offersAndDiscounts');
  String get offersAndDiscountsSubtitle => get('offersAndDiscountsSubtitle');
  String get ratings => get('ratings');
  String get ratingsSubtitle => get('ratingsSubtitle');
  String get settings => get('settings');
  String get settingsSubtitle => get('settingsSubtitle');
  String get termsAndConditions => get('termsAndConditions');
  String get termsAndConditionsSubtitle => get('termsAndConditionsSubtitle');
  String get privacyPolicy => get('privacyPolicy');
  String get privacyPolicySubtitle => get('privacyPolicySubtitle');
  String get helpAndSupport => get('helpAndSupport');
  String get helpAndSupportSubtitle => get('helpAndSupportSubtitle');
  String get aboutApp => get('aboutApp');
  String get aboutAppSubtitle => get('aboutAppSubtitle');
  String get madeBy => get('madeBy');
  String get logoutSubtitle => get('logoutSubtitle');

  // إعدادات اللغة
  String get languageSettings => get('languageSettings');
  String get selectLanguage => get('selectLanguage');
  String get languageChanged => get('languageChanged');

  // الشاشة الرئيسية
  String get bookTaxi => get('bookTaxi');
  String get orderNow => get('orderNow');
  String get offersAndAds => get('offersAndAds');
  String get browseOffers => get('browseOffers');
  String get noOffersNow => get('noOffersNow');
  String get customer => get('customer');
  String get driver => get('driver');
  String get driverRole => get('driver');

  // رسائل عامة
  String get cancel => get('cancel');
  String get confirm => get('confirm');
  String get yes => get('yes');
  String get no => get('no');
  String get ok => get('ok');
  String get error => get('error');
  String get success => get('success');
  String get warning => get('warning');
  String get underDevelopment => get('underDevelopment');
  String get couldNotOpenLink => get('couldNotOpenLink');
  String get logoutConfirmation => get('logoutConfirmation');
  String get logoutError => get('logoutError');
  String get continueText => get('continueText');

  // صفحة عن التطبيق
  String get appDescription => get('appDescription');
  String get version => get('version');
  String get supportAndContact => get('supportAndContact');
  String get contactUsAnytime => get('contactUsAnytime');
  String get supportPhone => get('supportPhone');
  String get allRightsReserved => get('allRightsReserved');
  
  // ميزات التطبيق
  String get appFeatures => get('appFeatures');
  String get featureTracking => get('featureTracking');
  String get featureSafe => get('featureSafe');
  String get featureFast => get('featureFast');
  String get featureFairPrice => get('featureFairPrice');
  
  // صفحة المساعدة والدعم
  String get frequentQuestions => get('frequentQuestions');
  String get faqHowToBook => get('faqHowToBook');
  String get faqHowToBookAnswer => get('faqHowToBookAnswer');
  String get faqHowToCancel => get('faqHowToCancel');
  String get faqHowToCancelAnswer => get('faqHowToCancelAnswer');
  String get faqPayment => get('faqPayment');
  String get faqPaymentAnswer => get('faqPaymentAnswer');

  // التحقق من OTP
  String get sendOtp => get('sendOtp');
  String get enterOtp => get('enterOtp');
  String get otpHint => get('otpHint');
  String get otpSent => get('otpSent');
  String get otpVerified => get('otpVerified');
  String get phoneNotVerified => get('phoneNotVerified');
  String get otpExpired => get('otpExpired');
  String get sendingOtp => get('sendingOtp');
  String get verifyingOtp => get('verifyingOtp');
  String get otpSendError => get('otpSendError');
  String get otpInvalid => get('otpInvalid');
  String get resendOtp => get('resendOtp');
  String get resendOtpIn => get('resendOtpIn');
  String get verifyPhone => get('verifyPhone');
  String get otpSentTo => get('otpSentTo');
  String get verifyAndRegister => get('verifyAndRegister');

  // إلغاء الطلب
  String get cancelTripTitle => get('cancelTripTitle');
  String get selectCancellationReason => get('selectCancellationReason');
  String get cancelReasonDriverDelay => get('cancelReasonDriverDelay');
  String get cancelReasonDriverDelayDesc => get('cancelReasonDriverDelayDesc');
  String get cancelReasonWaitTooLong => get('cancelReasonWaitTooLong');
  String get cancelReasonWaitTooLongDesc => get('cancelReasonWaitTooLongDesc');
  String get cancelReasonPriceOrPayment => get('cancelReasonPriceOrPayment');
  String get cancelReasonPriceOrPaymentDesc => get('cancelReasonPriceOrPaymentDesc');
  String get cancelReasonWrongPickupOrDest => get('cancelReasonWrongPickupOrDest');
  String get cancelReasonWrongPickupOrDestDesc => get('cancelReasonWrongPickupOrDestDesc');
  String get cancelReasonFoundAlternative => get('cancelReasonFoundAlternative');
  String get cancelReasonFoundAlternativeDesc => get('cancelReasonFoundAlternativeDesc');
  String get cancelReasonDriverWrongDirection => get('cancelReasonDriverWrongDirection');
  String get cancelReasonDriverWrongDirectionDesc => get('cancelReasonDriverWrongDirectionDesc');
  String get cancelReasonWrongRequest => get('cancelReasonWrongRequest');
  String get cancelReasonWrongRequestDesc => get('cancelReasonWrongRequestDesc');
  String get cancelReasonPlanChange => get('cancelReasonPlanChange');
  String get cancelReasonPlanChangeDesc => get('cancelReasonPlanChangeDesc');
  String get cancelReasonDriverRequested => get('cancelReasonDriverRequested');
  String get cancelReasonDriverRequestedDesc => get('cancelReasonDriverRequestedDesc');
  String get cancelReasonDriverNotFound => get('cancelReasonDriverNotFound');
  String get cancelReasonDriverNotFoundDesc => get('cancelReasonDriverNotFoundDesc');
  String get cancelReasonVehicleNotMatching => get('cancelReasonVehicleNotMatching');
  String get cancelReasonVehicleNotMatchingDesc => get('cancelReasonVehicleNotMatchingDesc');
  String get cancelReasonVehicleCapacityIssue => get('cancelReasonVehicleCapacityIssue');
  String get cancelReasonVehicleCapacityIssueDesc => get('cancelReasonVehicleCapacityIssueDesc');
  String get cancelReasonDriverRefused => get('cancelReasonDriverRefused');
  String get cancelReasonDriverRefusedDesc => get('cancelReasonDriverRefusedDesc');
  String get cancelReasonOther => get('cancelReasonOther');
  String get confirmCancellation => get('confirmCancellation');
  String get tripCancelledSuccessfully => get('tripCancelledSuccessfully');

  // حذف الحساب
  String get deleteAccount => get('deleteAccount');
  String get deleteAccountSubtitle => get('deleteAccountSubtitle');
  String get deleteAccountWarning => get('deleteAccountWarning');
  String get deleteAccountConfirm => get('deleteAccountConfirm');
  String get enterPasswordToDelete => get('enterPasswordToDelete');
  String get deletingAccount => get('deletingAccount');
  String get accountDeletedSuccess => get('accountDeletedSuccess');
  String get accountDeleteError => get('accountDeleteError');

  // شاشة رحلاتي السابقة
  String get myTripsTitle => get('myTripsTitle');
  String get tripsLoadError => get('tripsLoadError');
  String get retry => get('retry');
  String get noTrips => get('noTrips');
  String get tripsWillAppear => get('tripsWillAppear');
  String get totalTrips => get('totalTrips');
  String get loadMoreError => get('loadMoreError');
  String get statusPending => get('statusPending');
  String get statusAccepted => get('statusAccepted');
  String get statusCompleted => get('statusCompleted');
  String get statusCancelled => get('statusCancelled');
  String get statusCancelledByDriver => get('statusCancelledByDriver');
  String get from => get('from');
  String get to => get('to');
  String get thePassenger => get('thePassenger');
  String get ratingsSection => get('ratingsSection');
  String get yourRatingForPassenger => get('yourRatingForPassenger');
  String get passengerRatingForYou => get('passengerRatingForYou');
  String get yourRatingForDriver => get('yourRatingForDriver');
  String get driverRatingForYou => get('driverRatingForYou');
  String get today => get('today');
  String get yesterday => get('yesterday');

  // شاشة الرسائل والإشعارات
  String get messagesAndNotifications => get('messagesAndNotifications');
  String get generalTab => get('generalTab');
  String get personalTab => get('personalTab');
  String get messagesLoadError => get('messagesLoadError');
  String get noMessages => get('noMessages');
  String get newBadge => get('newBadge');
  String get close => get('close');
  String minutesAgo(int count) => get('minutesAgo').replaceAll('{n}', '$count');
  String hoursAgo(int count) => get('hoursAgo').replaceAll('{n}', '$count');
  String daysAgo(int count) => get('daysAgo').replaceAll('{n}', '$count');

  // شاشة تفاصيل التوصيل
  String get destinationDetails => get('destinationDetails');
  String get receiverSection => get('receiverSection');
  String get receiverFullName => get('receiverFullName');
  String get enterReceiverName => get('enterReceiverName');
  String get receiverPhone => get('receiverPhone');
  String get phoneExample => get('phoneExample');
  String get enterPhone => get('enterPhone');
  String get phoneTooShort => get('phoneTooShort');
  String get addressLabel => get('addressLabel');
  String get addressExample => get('addressExample');
  String get enterAddress => get('enterAddress');
  String get optionalDescription => get('optionalDescription');
  String get paidByReceiver => get('paidByReceiver');
  String get confirmOrder => get('confirmOrder');

  // الشاشة الرئيسية - نصوص إضافية
  String get locatingYou => get('locatingYou');
  String get pleaseWait => get('pleaseWait');
  String get calculatingRoute => get('calculatingRoute');
  String get rideTab => get('rideTab');
  String get deliveryTab => get('deliveryTab');
  String get unknownLocation => get('unknownLocation');
  String get addFavoriteLocation => get('addFavoriteLocation');
  String get locationNameHint => get('locationNameHint');
  String get locationAddedToFav => get('locationAddedToFav');

  String get tripInfo => get('tripInfo');
  String get distanceToYou => get('distanceToYou');
  String get deliveryDetails => get('deliveryDetails');
  String get receiver => get('receiver');
  String get phone => get('phone');
  String get package => get('package');
  String get rideRequest => get('rideRequest');
  String get deliveryRequest => get('deliveryRequest');
  String get showOnMap => get('showOnMap');
  String get roundTrip => get('roundTrip');
  String get minute => get('minute');

  // شاشة معاينة الرحلة
  String get tripDetails => get('tripDetails');
  String get loadingRoute => get('loadingRoute');
  String get tripDistance => get('tripDistance');
  String get tripTime => get('tripTime');
  String get dropoffPoint => get('dropoffPoint');
  String get distanceToPassenger => get('distanceToPassenger');
  String get timeToPassenger => get('timeToPassenger');

  // نصوص إضافية
  String get tripOptions => get('tripOptions');
  String get enterDetails => get('enterDetails');
  String get tripOptionsInfo => get('tripOptionsInfo');
  String get addSecondDestination => get('addSecondDestination');
  String get secondDestination => get('secondDestination');
  String get addSecondDestSubtitle => get('addSecondDestSubtitle');
  String get tapToChangeOrDelete => get('tapToChangeOrDelete');
  String get waitTime => get('waitTime');
  String get waitTimeSubtitle => get('waitTimeSubtitle');
  String get choose => get('choose');
  String get roundTripLabel => get('roundTripLabel');
  String get roundTripSubtitle => get('roundTripSubtitle');
  String get estimatedPriceLabel => get('estimatedPriceLabel');
  String get confirmOptions => get('confirmOptions');

  // حقل المحافظة
  String get provinceField => get('provinceField');
  String get provinceBaghdad => get('provinceBaghdad');
  String get provinceKirkuk => get('provinceKirkuk');
  String get provinceError => get('provinceError');

  // إدارة توفر السائق - GPS
  String get gpsDisabledTitle => get('gpsDisabledTitle');
  String get locationPermissionRequired => get('locationPermissionRequired');
  String get openLocationSettings => get('openLocationSettings');
  String get openAppSettings => get('openAppSettings');
  String get noInternetConnection => get('noInternetConnection');
  String get updating => get('updating'); // جارٍ التحديث...

  // الكوبونات والهدايا
  String get couponsAndGifts => get('couponsAndGifts');
  String get promoCodeLabel => get('promoCodeLabel');
  String get applyPromo => get('applyPromo');
  String get promoCodeHint => get('promoCodeHint');
  String get promoAppliedSuccess => get('promoAppliedSuccess');
  String get promoInvalid => get('promoInvalid');
  String get promoLimitReached => get('promoLimitReached');
  String get myGiftsLabel => get('myGiftsLabel');
  String get myCouponsLabel => get('myCouponsLabel');
  String get noGiftsYet => get('noGiftsYet');
  String get noCouponsYet => get('noCouponsYet');
  String get useGiftBtn => get('useGiftBtn');
  String get giftUsedSuccess => get('giftUsedSuccess');
  String get giftUsedAlready => get('giftUsedAlready');
  String get giftExpired => get('giftExpired');
  String get freeRideGift => get('freeRideGift');
  String get expiryDate => get('expiryDate');

  String promoMinPriceError(String minPrice) => get('promoMinPriceError').replaceAll('{minPrice}', minPrice);
  String discountApplied(String discount) => get('discountApplied').replaceAll('{discount}', discount);
  String fixedDiscountGift(String amount) => get('fixedDiscountGift').replaceAll('{amount}', amount);

  // شاشة البداية ومكوناتها
  String get quickServices => get('quickServices');
  String get startHeroDescription => get('startHeroDescription');
  String get bookRideNow => get('bookRideNow');
  String get couponsAndGiftsSubtitle => get('couponsAndGiftsSubtitle');
  String get safetyCardTitle => get('safetyCardTitle');
  String get safetyCardSubtitle => get('safetyCardSubtitle');
  String get activeTripNow => get('activeTripNow');
  String get activeTripDialogMessage => get('activeTripDialogMessage');
  String get goToDetails => get('goToDetails');
  String get locationPermissionTitle => get('locationPermissionTitle');
  String get enableGpsTitle => get('enableGpsTitle');
  String get locationPermissionDialogDesc => get('locationPermissionDialogDesc');
  String get enableGpsDialogDesc => get('enableGpsDialogDesc');
  String get openSettings => get('openSettings');
  String get enableGps => get('enableGps');
  String get track => get('track');
  String get searchingNearbyDriverStatus => get('searchingNearbyDriverStatus');
  String get driverAcceptedStatus => get('driverAcceptedStatus');
  String get driverArrivedPickupStatus => get('driverArrivedPickupStatus');
  String get inTransitStatus => get('inTransitStatus');

  // مراحل الرادار ونطاق البحث
  String searchNearbyRadius(int radius) => get('searchNearbyRadius').replaceAll('{radius}', '$radius');
  String expandingSearchRadius(int radius) => get('expandingSearchRadius').replaceAll('{radius}', '$radius');
  String expandingSearchMaxRadius(int radius) => get('expandingSearchMaxRadius').replaceAll('{radius}', '$radius');

  // مربعات الحوار والشاشة الرئيسية
  String get noDriversTitle => get('noDriversTitle');
  String get noDriversDesc => get('noDriversDesc');
  String get retryNow => get('retryNow');
  String get cancelAndReturnHome => get('cancelAndReturnHome');
  String get driverArrivedAtYourLocation => get('driverArrivedAtYourLocation');
  String get tripDistanceLabel => get('tripDistanceLabel');
  String get expectedTimeLabel => get('expectedTimeLabel');
  String get searchLocationHint => get('searchLocationHint');
  String get locating => get('locating');
  String get searchResults => get('searchResults');
  String get favoriteLocations => get('favoriteLocations');
  String get addLocation => get('addLocation');
  String get suggestedLocations => get('suggestedLocations');
  String get roundTripBadge => get('roundTripBadge');
  String waitingWithTime(String time) => get('waitingWithTime').replaceAll('{time}', time);
  String get estimatedPriceColon => get('estimatedPriceColon');
  String get discountColon => get('discountColon');
  String get finalPriceColon => get('finalPriceColon');
  String get chooseFromCouponsAndGifts => get('chooseFromCouponsAndGifts');
  String get tripPrice => get('tripPrice');

  // شاشة السلامة والطوارئ
  String get safety => get('safety');
  String get shareTrip => get('shareTrip');
  String get shareTripSubtitle => get('shareTripSubtitle');
  String get dontFeelSafe => get('dontFeelSafe');
  String get contactSafetyTeam => get('contactSafetyTeam');
  String get requestAmbulance => get('requestAmbulance');
  String get callEmergencyNumber => get('callEmergencyNumber');
  String get cannotMakeCall => get('cannotMakeCall');
  String get tripDetailsShareSubject => get('tripDetailsShareSubject');
  String get unknownDriver => get('unknownDriver');
  String get unavailablePhone => get('unavailablePhone');

  // الكوبونات والهدايا والمكافآت
  String get loginRequiredTitle => get('loginRequiredTitle');
  String get loginRequiredGiftsSubtitle => get('loginRequiredGiftsSubtitle');
  String get noGiftsSubtitle => get('noGiftsSubtitle');
  String get noCouponsSubtitle => get('noCouponsSubtitle');
  String get specialReward => get('specialReward');
  String get applied => get('applied');
  String get deactivate => get('deactivate');
  String get codeCopiedSuccess => get('codeCopiedSuccess');
  String discountLabel(String value) => get('discountLabel').replaceAll('{value}', value);
  String minTripPriceLabel(String price) => get('minTripPriceLabel').replaceAll('{price}', price);
  String maxDiscountLimitLabel(String price) => get('maxDiscountLimitLabel').replaceAll('{price}', price);
  String get applyNow => get('applyNow');
  String get giftDeactivatedSuccess => get('giftDeactivatedSuccess');
  String get couponDeactivatedSuccess => get('couponDeactivatedSuccess');

  // الرحلات والتقييم
  String get allTripsTab => get('allTripsTab');
  String get completedTripsTab => get('completedTripsTab');
  String get cancelledTripsTab => get('cancelledTripsTab');
  String get noPastTrips => get('noPastTrips');
  String get noCompletedTrips => get('noCompletedTrips');
  String get noCancelledTrips => get('noCancelledTrips');
  String get pastTripsEmptySubtitle => get('pastTripsEmptySubtitle');
  String cancellationReasonLabel(String reason) => get('cancellationReasonLabel').replaceAll('{reason}', reason);
  String rateDriverTitle(String driver) => get('rateDriverTitle').replaceAll('{driver}', driver);
  String get ratingFeedbackHint => get('ratingFeedbackHint');
  String get skip => get('skip');
  String get submitRating => get('submitRating');
  String get ratingVeryBad => get('ratingVeryBad');
  String get ratingBad => get('ratingBad');
  String get ratingAcceptable => get('ratingAcceptable');
  String get ratingGood => get('ratingGood');
  String get ratingExcellent => get('ratingExcellent');
  String get driverArrived => get('driverArrived');
  String get onTheWay => get('onTheWay');
  String get refresh => get('refresh');

  // الملف الشخصي والمعلومات الإضافية
  String get saveChanges => get('saveChanges');
  String get genderMale => get('genderMale');
  String get genderFemale => get('genderFemale');
  String get selectGenderError => get('selectGenderError');
  String get selectBirthDateError => get('selectBirthDateError');
  String get selectProvinceError => get('selectProvinceError');
  String get genderColon => get('genderColon');
  String get birthDateColon => get('birthDateColon');
  String get chooseDate => get('chooseDate');
  String get additionalInfoOptional => get('additionalInfoOptional');
  String get agreeToTermsPrefix => get('agreeToTermsPrefix');
  String get enterFullName => get('enterFullName');
  String get nameTooShort => get('nameTooShort');
  String get detailedAddress => get('detailedAddress');
  String get detailedAddressHint => get('detailedAddressHint');

  // وضع المطور
  String devModeTapPrompt(int count) => get('devModeTapPrompt').replaceAll('{count}', count.toString());
  String get devModeTitle => get('devModeTitle');
  String get devModeEnabledDesc => get('devModeEnabledDesc');
  String get minutesUnit => get('minutesUnit');
  String get minutes => get('minutesUnit');

  // المحفظة والمدفوعات
  String get wallet => get('wallet');
  String get walletSubtitle => get('walletSubtitle');
  String get currentBalance => get('currentBalance');
  String get topUp => get('topUp');
  String get topUpWallet => get('topUpWallet');
  String get enterTopUpAmount => get('enterTopUpAmount');
  String get quickAmounts => get('quickAmounts');
  String get savedCards => get('savedCards');
  String get addCard => get('addCard');
  String get noSavedCards => get('noSavedCards');
  String get noSavedCardsDesc => get('noSavedCardsDesc');
  String get recentTransactions => get('recentTransactions');
  String get noTransactions => get('noTransactions');
  String get noTransactionsDesc => get('noTransactionsDesc');
  String get paymentMethod => get('paymentMethod');
  String get cash => get('cash');
  String get walletPayment => get('walletPayment');
  String get creditCard => get('creditCard');
  String get applePay => get('applePay');
  String get insufficientBalance => get('insufficientBalance');
  String get topUpSuccess => get('topUpSuccess');
  String get topUpFailed => get('topUpFailed');
  String get cardAddedSuccess => get('cardAddedSuccess');
  String get cardDeleteSuccess => get('cardDeleteSuccess');
  String get confirmDeleteCard => get('confirmDeleteCard');
  String get transactionTopUp => get('transactionTopUp');
  String get transactionTripPayment => get('transactionTripPayment');
  String get transactionRefund => get('transactionRefund');
  String get transactionBonus => get('transactionBonus');
  String get payWithWallet => get('payWithWallet');
  String get availableBalance => get('availableBalance');
  String get manageCards => get('manageCards');
  String get defaultCard => get('defaultCard');
  String get setAsDefault => get('setAsDefault');
  String get delete => get('delete');
  String get stripeInitError => get('stripeInitError');
  String get invalidAmount => get('invalidAmount');
  String get minTopUpAmount => get('minTopUpAmount');
  String paymentMethodCashBadge(String amount) => get('paymentMethodCashBadge').replaceAll('{amount}', amount);
  String paymentMethodElectronicBadge(String method) => get('paymentMethodElectronicBadge').replaceAll('{method}', method);
  String get carPlateNumber => get('carPlateNumber');
  String get carDetails => get('carDetails');
  String get unknownCar => get('unknownCar');

  /// تنسيق وقت الانتظار ديناميكياً بحسب اللغة
  String formatWaitTime(String raw) {
    final numbers = raw.replaceAll(RegExp(r'[^0-9\-]'), '');
    if (numbers.isEmpty) return raw;
    return '$numbers $minutesUnit';
  }
}
