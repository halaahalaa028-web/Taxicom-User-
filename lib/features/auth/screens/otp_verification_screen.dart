/// شاشة التحقق من OTP
/// 
/// شاشة منفصلة للتحقق من رقم الهاتف عبر Firebase Phone Auth
/// قبل الدخول أو إتمام حفظ بيانات الحساب
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../models/registration_data.dart';
import '../services/auth_service.dart';
import '../widgets/otp_header_widget.dart';
import '../widgets/otp_input_field.dart';
import 'complete_profile_screen.dart';
import '../../profile/services/user_service.dart';
import '../../home/screens/start_screen.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/session_service.dart';

/// شاشة التحقق من OTP
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final String initialChannel;
  final int? resendToken;
  final RegistrationData? registrationData;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.initialChannel = 'whatsapp',
    this.resendToken,
    this.registrationData,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  
  final AuthService _authService = AuthService.instance;
  final UserService _userService = UserService.instance;
  
  late String _currentVerificationId;
  late String _currentChannel;
  
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isRegistering = false;
  
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _currentChannel = widget.initialChannel;
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendCountdown = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _resendTimer?.cancel();
          }
        });
      } else {
        _resendTimer?.cancel();
      }
    });
  }

  /// إعادة إرسال رمز OTP عبر Cloud Functions (يدعم تحديد القناة مثل SMS)
  Future<void> _resendOtp({String? forcedChannel}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSendingOtp = true);

    try {
      final targetChannel = forcedChannel ?? (_currentChannel == 'whatsapp' ? 'sms' : 'whatsapp');
      final result = await _authService.resendCustomOtp(
        phoneNumber: widget.phoneNumber,
        channel: targetChannel,
      );

      if (mounted) {
        setState(() {
          _isSendingOtp = false;
          _currentVerificationId = result['verificationId']?.toString() ?? _currentVerificationId;
          _currentChannel = result['channelSent']?.toString() ?? targetChannel;
          _startResendTimer();
        });

        final channelMsg = _currentChannel == 'whatsapp'
            ? 'تم إرسال رمز التحقق إلى واتساب'
            : 'تم إرسال رمز التحقق عبر رسالة SMS';
        _showSnackBar(channelMsg, isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingOtp = false);
        _showSnackBar(l10n.otpSendError, isError: true);
      }
    }
  }

  /// التحقق من رمز OTP المدخل وتسجيل الدخول بواسطة Custom Token
  Future<void> _verifyAndProceed() async {
    final l10n = AppLocalizations.of(context);
    
    String otpCode = _otpController.text.trim();
    if (otpCode.length != 6) {
      _showSnackBar(l10n.otpInvalid, isError: true);
      return;
    }
    
    setState(() => _isVerifyingOtp = true);
    
    try {
      final user = await _authService.verifyCustomOtpAndSignIn(
        phoneNumber: widget.phoneNumber,
        otpCode: otpCode,
        verificationId: _currentVerificationId,
      );

      if (user != null) {
        await _onAuthSuccess(user);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  /// بعد نجاح المصادقة بـ Firebase Auth
  Future<void> _onAuthSuccess(User user) async {
    setState(() {
      _isVerifyingOtp = false;
      _isRegistering = true;
    });

    try {
      final existingUser = await _userService.getUser(user.uid);

      if (existingUser != null) {
        // مستخدم قديم لديه حساب مسبقاً -> التوجيه المباشر للشاشة الرئيسية
        final userType = existingUser.userType;
        await SessionService.instance.registerDevice(user.uid, userType);
        await NotificationService.instance.updateFcmTokenOnLogin();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const StartScreen(),
            ),
            (route) => false,
          );

          await SessionService.instance.startSessionListener(user.uid, userType);
        }
      } else {
        // مستخدم جديد يسجل لأول مرة برقم الهاتف -> توجيه لإكمال بيانات الاسم والمحافظة
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(
                uid: user.uid,
                phone: widget.phoneNumber,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  /// عرض رسالة SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLoading = _isSendingOtp || _isVerifyingOtp || _isRegistering;
    
    String loadingMessage = '';
    if (_isSendingOtp) {
      loadingMessage = l10n.sendingOtp;
    } else if (_isVerifyingOtp) {
      loadingMessage = l10n.verifyingOtp;
    } else if (_isRegistering) {
      loadingMessage = l10n.creatingAccount;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.otpTitle,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        message: loadingMessage,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),
                
                // ترويسة الشاشة (الأيقونة، العنوان، ورقم الهاتف، وقناة الإرسال)
                OtpHeaderWidget(
                  phoneNumber: widget.phoneNumber,
                  channel: _currentChannel,
                ),
                
                const SizedBox(height: 32),
                
                // حقل إدخال OTP
                OtpInputField(controller: _otpController),
                
                const SizedBox(height: 16),
                
                // خيارات إعادة الإرسال والتحويل إلى SMS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: (_isSendingOtp || _resendCountdown > 0)
                          ? null
                          : () => _resendOtp(),
                      icon: Icon(
                        _currentChannel == 'whatsapp' ? Icons.chat_bubble_outline : Icons.sms_outlined,
                        size: 16,
                      ),
                      label: Text(
                        _resendCountdown > 0 
                            ? '${l10n.resendOtp} ($_resendCountdown)' 
                            : l10n.resendOtp,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: _resendCountdown > 0 ? AppColors.textSecondary : AppColors.primary,
                        ),
                      ),
                    ),
                    if (_currentChannel == 'whatsapp') ...[
                      const Text(' | ', style: TextStyle(color: AppColors.border)),
                      TextButton.icon(
                        onPressed: _isSendingOtp ? null : () => _resendOtp(forcedChannel: 'sms'),
                        icon: const Icon(Icons.sms_rounded, size: 16),
                        label: const Text(
                          'إرسال عبر SMS',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                const Spacer(flex: 2),
                
                // زر التحقق
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _verifyAndProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_rounded),
                        const SizedBox(width: 8),
                        Text(
                          l10n.verifyAndRegister,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
