import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/promo_service.dart';
import '../models/coupon_model.dart';
import '../services/user_service.dart';
import '../widgets/coupons_gifts/coupon_card.dart';
import '../widgets/coupons_gifts/promo_empty_state.dart';

/// شاشة الكوبونات والمكافآت الموحدة
class CouponsGiftsScreen extends StatefulWidget {
  const CouponsGiftsScreen({super.key});

  @override
  State<CouponsGiftsScreen> createState() => _CouponsGiftsScreenState();

  /// الكوبون النشط والمطبق حالياً للرحلة القادمة
  static CouponModel? activeAppliedCoupon;

  /// الحصول على الكوبون النشط
  static Map<String, dynamic>? getActivePromo() {
    if (activeAppliedCoupon != null) {
      return {
        'type': 'coupon',
        'id': activeAppliedCoupon!.id,
        'coupon': activeAppliedCoupon,
      };
    }
    return null;
  }

  /// مسح الكوبون النشط بعد إتمام الحجز
  static void clearActivePromo() {
    activeAppliedCoupon = null;
  }
}

class _CouponsGiftsScreenState extends State<CouponsGiftsScreen> {
  final TextEditingController _promoInputController = TextEditingController();
  String _userPhone = '';
  bool _isLoadingUser = true;
  bool _isValidatingCode = false;

  @override
  void initState() {
    super.initState();
    final cachedUser = UserService.instance.cachedUser;
    if (cachedUser != null && cachedUser.phone.isNotEmpty) {
      _userPhone = cachedUser.phone;
      _isLoadingUser = false;
    }
    _initUserData();
  }

  Future<void> _initUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (UserService.instance.cachedUser != null && UserService.instance.cachedUser!.phone.isNotEmpty) {
        _userPhone = UserService.instance.cachedUser!.phone;
      }

      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final phone = userDoc.data()!['phone'] as String?;
          if (phone != null && phone.isNotEmpty) {
            _userPhone = phone;
          }
        }
      } catch (e) {
        if (_userPhone.isEmpty) {
          _userPhone = currentUser.phoneNumber ?? '';
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  @override
  void dispose() {
    _promoInputController.dispose();
    super.dispose();
  }

  Future<void> _applyManualCode(AppLocalizations l10n) async {
    final code = _promoInputController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingCode = true);
    final coupon = await PromoService.instance.getCouponByCode(code);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    
    if (coupon != null && currentUid != null) {
      final userUsage = await PromoService.instance.getUserCouponUsageCount(
        userId: currentUid,
        couponId: coupon.id,
      );
      final allowedPerUser = coupon.usageLimitPerUser ?? 1;
      if (userUsage >= allowedPerUser) {
        setState(() => _isValidatingCode = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.promoLimitReached, style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }
    }
    
    setState(() => _isValidatingCode = false);

    if (!mounted) return;

    if (coupon == null || coupon.isExpired || coupon.isLimitReached || !coupon.isValidForUser(currentUid ?? '')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.promoInvalid, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    _toggleCoupon(coupon, l10n);
    _promoInputController.clear();
  }

  void _toggleCoupon(CouponModel coupon, AppLocalizations l10n) {
    setState(() {
      if (CouponsGiftsScreen.activeAppliedCoupon?.id == coupon.id) {
        CouponsGiftsScreen.activeAppliedCoupon = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.couponDeactivatedSuccess, style: const TextStyle(fontFamily: 'Cairo')),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        CouponsGiftsScreen.activeAppliedCoupon = coupon;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.promoAppliedSuccess, style: const TextStyle(fontFamily: 'Cairo')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.couponsAndGifts,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // حقل إدخال رمز الكوبون اليدوي
                _buildPromoCodeInput(l10n),
                const SizedBox(height: 20),

                // عنوان قائمة الكوبونات المتاحة
                Text(
                  l10n.myCouponsLabel,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // عرض الكوبونات المتاحة من Firestore
                StreamBuilder<List<CouponModel>>(
                  stream: PromoService.instance.getUserAvailableCouponsStream(
                    userPhone: _userPhone,
                    userId: FirebaseAuth.instance.currentUser?.uid,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );
                    }

                    final coupons = snapshot.data ?? [];
                    if (coupons.isEmpty) {
                      return PromoEmptyState(
                        icon: Icons.confirmation_number_outlined,
                        title: l10n.noCouponsYet,
                        subtitle: l10n.noCouponsSubtitle,
                      );
                    }

                    return Column(
                      children: coupons.map((coupon) {
                        final isApplied = CouponsGiftsScreen.activeAppliedCoupon?.id == coupon.id;
                        return CouponCard(
                          coupon: coupon,
                          isApplied: isApplied,
                          onApply: () => _toggleCoupon(coupon, l10n),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildPromoCodeInput(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promoInputController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: l10n.promoCodeHint,
                hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 20),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: _isValidatingCode ? null : () => _applyManualCode(l10n),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: _isValidatingCode
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    l10n.applyPromo,
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                  ),
          ),
        ],
      ),
    );
  }
}
