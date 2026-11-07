import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/country_service.dart';
import '../../../../core/services/promo_service.dart';
import '../../../profile/models/coupon_model.dart';
import '../../../profile/services/user_service.dart';
import 'trip_options_price_summary.dart';
import 'trip_options_promo_section.dart';
import 'trip_options_route_section.dart';

/// نافذة خيارات الرحلة الإضافية (وجهة ثانية، انتظار، ذهاب وإياب، كوبونات)
class TripOptionsModalSheet extends StatefulWidget {
  final String? secondDestinationAddress;
  final bool hasSecondDestination;
  final String? waitTime;
  final List<String> waitTimeOptions;
  final bool isRoundTrip;
  final CouponModel? appliedCoupon;
  final String manualPromoCode;
  final double estimatedPrice;
  final double Function({String? waitTime, bool isRoundTrip})? onCalculatePrice;
  final VoidCallback onRemoveSecondDestination;
  final VoidCallback onSelectSecondDestination;
  final ValueChanged<String?> onWaitTimeChanged;
  final ValueChanged<bool> onRoundTripChanged;
  final Function(CouponModel? coupon, String promoCode) onPromoUpdated;
  final VoidCallback onOpenCouponsGifts;
  final Function(double finalPrice, double discountAmount, double originalPrice) onConfirm;

  const TripOptionsModalSheet({
    super.key,
    required this.secondDestinationAddress,
    required this.hasSecondDestination,
    required this.waitTime,
    required this.waitTimeOptions,
    required this.isRoundTrip,
    required this.appliedCoupon,
    required this.manualPromoCode,
    required this.estimatedPrice,
    this.onCalculatePrice,
    required this.onRemoveSecondDestination,
    required this.onSelectSecondDestination,
    required this.onWaitTimeChanged,
    required this.onRoundTripChanged,
    required this.onPromoUpdated,
    required this.onOpenCouponsGifts,
    required this.onConfirm,
  });

  @override
  State<TripOptionsModalSheet> createState() => _TripOptionsModalSheetState();
}

class _TripOptionsModalSheetState extends State<TripOptionsModalSheet> {
  late bool _isRoundTrip;
  late String? _waitTime;
  CouponModel? _appliedCoupon;
  late String _manualPromoCode;
  String? _promoError;
  final TextEditingController _promoCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isRoundTrip = widget.isRoundTrip;
    _waitTime = widget.waitTime;
    _appliedCoupon = widget.appliedCoupon;
    _manualPromoCode = widget.manualPromoCode;
    _promoCodeController.text = _manualPromoCode;
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  double _getCalculatedPrice() {
    if (widget.onCalculatePrice != null) {
      return widget.onCalculatePrice!(waitTime: _waitTime, isRoundTrip: _isRoundTrip);
    }
    return widget.estimatedPrice;
  }

  Future<void> _handleApplyCode() async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) return;

    final currentEstimatedPrice = _getCalculatedPrice();
    final userPhone = UserService.instance.cachedUser?.phone ?? '';
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final coupon = await PromoService.instance.getCouponByCode(code);
    final validation = await PromoService.instance.validateCouponAsync(
      coupon: coupon,
      tripPrice: currentEstimatedPrice,
      userPhone: userPhone,
      userId: userId,
    );

    if (validation.isValid && coupon != null) {
      setState(() {
        _appliedCoupon = coupon;
        _manualPromoCode = code;
        _promoError = null;
      });
      widget.onPromoUpdated(coupon, code);
    } else {
      setState(() {
        if (validation.errorMessage == 'promoLimitReached') {
          _promoError = AppLocalizations.of(context).promoLimitReached;
        } else {
          _promoError = AppLocalizations.of(context).promoInvalid;
        }
      });
    }
  }

  void _handleClearPromo() {
    setState(() {
      _appliedCoupon = null;
      _manualPromoCode = '';
      _promoCodeController.clear();
      _promoError = null;
    });
    widget.onPromoUpdated(null, '');
  }

  @override
  Widget build(BuildContext context) {
    final currentEstimatedPrice = _getCalculatedPrice();

    // حساب الخصم
    double discount = 0.0;
    String? appliedCodeName;

    if (_appliedCoupon != null) {
      final validation = PromoService.instance.validateCoupon(
        coupon: _appliedCoupon,
        tripPrice: currentEstimatedPrice,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      if (validation.isValid) {
        discount = validation.discountAmount;
        appliedCodeName = _appliedCoupon!.code;
      } else {
        _appliedCoupon = null;
      }
    }

    double rawFinalPrice = currentEstimatedPrice - discount;
    if (rawFinalPrice < 0) rawFinalPrice = 0.0;

    final step = CountryService.instance.selectedCountry.roundingStep;
    final double finalPrice;
    if (step >= 1) {
      finalPrice = (rawFinalPrice / step).round() * step;
    } else if (step > 0) {
      final factor = (1 / step).round();
      finalPrice = (rawFinalPrice * factor).round() / factor;
    } else {
      finalPrice = rawFinalPrice;
    }

    double finalDiscount = currentEstimatedPrice - finalPrice;
    if (finalDiscount < 0) finalDiscount = 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // شريط العنوان وزر الإغلاق
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).tripOptions,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // قسم المسار (الوجهة الثانية، ذهاب وإياب، وقت الانتظار)
                TripOptionsRouteSection(
                  secondDestinationAddress: widget.secondDestinationAddress,
                  hasSecondDestination: widget.hasSecondDestination,
                  waitTime: _waitTime,
                  waitTimeOptions: widget.waitTimeOptions,
                  isRoundTrip: _isRoundTrip,
                  onSelectSecondDestination: () {
                    Navigator.pop(context);
                    widget.onSelectSecondDestination();
                  },
                  onRemoveSecondDestination: () {
                    widget.onRemoveSecondDestination();
                    setState(() {});
                  },
                  onWaitTimeChanged: (val) {
                    setState(() => _waitTime = val);
                    widget.onWaitTimeChanged(val);
                  },
                  onRoundTripChanged: (val) {
                    setState(() => _isRoundTrip = val);
                    widget.onRoundTripChanged(val);
                  },
                ),

                const Divider(height: 24),

                // قسم الكوبونات الموحد
                TripOptionsPromoSection(
                  appliedCodeName: appliedCodeName,
                  discount: discount,
                  promoCodeController: _promoCodeController,
                  promoError: _promoError,
                  onApplyCode: _handleApplyCode,
                  onClearPromo: _handleClearPromo,
                  onOpenCouponsGifts: () {
                    Navigator.pop(context);
                    widget.onOpenCouponsGifts();
                  },
                ),

                const Divider(height: 24),

                // ملخص السعر وزر التأكيد
                TripOptionsPriceSummary(
                  estimatedPrice: currentEstimatedPrice,
                  finalDiscount: finalDiscount,
                  finalPrice: finalPrice,
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(finalPrice, finalDiscount, currentEstimatedPrice);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      AppLocalizations.of(context).confirm,
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
