/// نماذج وقوائم أسباب إلغاء الرحلة للراكب
library;

import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import 'trip_request_model.dart';

/// نموذج سبب الإلغاء
class CancellationReason {
  final String key;
  final IconData icon;

  const CancellationReason({
    required this.key,
    required this.icon,
  });

  /// الحصول على عنوان السبب المترجم
  String getLocalizedTitle(AppLocalizations loc) {
    switch (key) {
      case 'waitTooLong':
        return loc.cancelReasonWaitTooLong;
      case 'wrongPickupOrDest':
        return loc.cancelReasonWrongPickupOrDest;
      case 'foundAlternative':
        return loc.cancelReasonFoundAlternative;
      case 'priceOrPayment':
        return loc.cancelReasonPriceOrPayment;
      case 'driverDelay':
        return loc.cancelReasonDriverDelay;
      case 'driverWrongDirection':
        return loc.cancelReasonDriverWrongDirection;
      case 'wrongRequest':
        return loc.cancelReasonWrongRequest;
      case 'planChange':
        return loc.cancelReasonPlanChange;
      case 'driverRequested':
        return loc.cancelReasonDriverRequested;
      case 'driverNotFound':
        return loc.cancelReasonDriverNotFound;
      case 'vehicleNotMatching':
        return loc.cancelReasonVehicleNotMatching;
      case 'vehicleCapacityIssue':
        return loc.cancelReasonVehicleCapacityIssue;
      case 'driverRefused':
        return loc.cancelReasonDriverRefused;
      case 'other':
        return loc.cancelReasonOther;
      default:
        return key;
    }
  }

  /// الحصول على وصف السبب المترجم
  String getLocalizedDescription(AppLocalizations loc) {
    switch (key) {
      case 'waitTooLong':
        return loc.cancelReasonWaitTooLongDesc;
      case 'wrongPickupOrDest':
        return loc.cancelReasonWrongPickupOrDestDesc;
      case 'foundAlternative':
        return loc.cancelReasonFoundAlternativeDesc;
      case 'priceOrPayment':
        return loc.cancelReasonPriceOrPaymentDesc;
      case 'driverDelay':
        return loc.cancelReasonDriverDelayDesc;
      case 'driverWrongDirection':
        return loc.cancelReasonDriverWrongDirectionDesc;
      case 'wrongRequest':
        return loc.cancelReasonWrongRequestDesc;
      case 'planChange':
        return loc.cancelReasonPlanChangeDesc;
      case 'driverRequested':
        return loc.cancelReasonDriverRequestedDesc;
      case 'driverNotFound':
        return loc.cancelReasonDriverNotFoundDesc;
      case 'vehicleNotMatching':
        return loc.cancelReasonVehicleNotMatchingDesc;
      case 'vehicleCapacityIssue':
        return loc.cancelReasonVehicleCapacityIssueDesc;
      case 'driverRefused':
        return loc.cancelReasonDriverRefusedDesc;
      case 'other':
      default:
        return '';
    }
  }
}

/// أسباب الإلغاء أثناء مرحلة البحث عن سائق (قبل القبول)
final List<CancellationReason> pendingReasons = const [
  CancellationReason(key: 'waitTooLong', icon: Icons.hourglass_empty_rounded),
  CancellationReason(key: 'wrongPickupOrDest', icon: Icons.wrong_location_outlined),
  CancellationReason(key: 'foundAlternative', icon: Icons.directions_bus_filled_outlined),
  CancellationReason(key: 'priceOrPayment', icon: Icons.payments_outlined),
  CancellationReason(key: 'planChange', icon: Icons.event_busy_rounded),
  CancellationReason(key: 'other', icon: Icons.more_horiz_rounded),
];

/// أسباب الإلغاء بعد قبول السائق وهو في الطريق
final List<CancellationReason> onWayReasons = const [
  CancellationReason(key: 'driverWrongDirection', icon: Icons.alt_route_rounded),
  CancellationReason(key: 'driverDelay', icon: Icons.access_time_rounded),
  CancellationReason(key: 'driverRequested', icon: Icons.person_outline_rounded),
  CancellationReason(key: 'wrongRequest', icon: Icons.error_outline_rounded),
  CancellationReason(key: 'planChange', icon: Icons.event_busy_rounded),
  CancellationReason(key: 'other', icon: Icons.more_horiz_rounded),
];

/// أسباب الإلغاء بعد وصول السائق لموقع الاستلام
final List<CancellationReason> arrivedReasons = const [
  CancellationReason(key: 'driverNotFound', icon: Icons.location_off_rounded),
  CancellationReason(key: 'vehicleNotMatching', icon: Icons.no_accounts_outlined),
  CancellationReason(key: 'vehicleCapacityIssue', icon: Icons.luggage_outlined),
  CancellationReason(key: 'driverRefused', icon: Icons.cancel_presentation_rounded),
  CancellationReason(key: 'planChange', icon: Icons.event_busy_rounded),
  CancellationReason(key: 'other', icon: Icons.more_horiz_rounded),
];

/// جلب قائمة أسباب الإلغاء بحسب مرحلة الرحلة
List<CancellationReason> getCancellationReasonsForStatus(TripStatus status) {
  switch (status) {
    case TripStatus.arrivedAtPickup:
      return arrivedReasons;
    case TripStatus.accepted:
      return onWayReasons;
    case TripStatus.pending:
    default:
      return pendingReasons;
  }
}
