/// شاشة إكمال بيانات المستخدم الجديد
/// 
/// تظهر مرة واحدة فقط عند تسجيل المستخدم لأول مرة عبر رقم الهاتف
/// تطلب الاسم والمحافظة أساسياً، والجنس وتاريخ الميلاد اختيارياً أسفل الواجهة مع الشروط
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_provinces.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../services/auth_service.dart';
import '../../profile/models/user_model.dart';
import '../../profile/services/user_service.dart';
import '../../profile/widgets/widgets.dart';
import '../../home/screens/start_screen.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/country_service.dart';

/// شاشة إكمال بيانات الملف الشخصي
class CompleteProfileScreen extends StatefulWidget {
  final String uid;
  final String phone;

  const CompleteProfileScreen({
    super.key,
    required this.uid,
    required this.phone,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  late String _countryCode;
  late String _selectedProvince;
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  final UserService _userService = UserService.instance;

  @override
  void initState() {
    super.initState();
    _countryCode = AppProvinces.detectCountryCodeFromPhone(widget.phone);
    _selectedProvince = AppProvinces.getDefaultProvinceForCountry(_countryCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _saveProfileAndStart() async {
    // 1. التحقق من الاسم
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('يرجى إدخال الاسم الكامل', isError: true);
      _formKey.currentState?.validate();
      return;
    }
    if (_nameController.text.trim().length < 3) {
      _showSnackBar('الاسم المدخل قصير جداً', isError: true);
      _formKey.currentState?.validate();
      return;
    }

    // 2. التحقق من المحافظة
    if (_selectedProvince.trim().isEmpty) {
      _showSnackBar('يرجى اختيار المحافظة', isError: true);
      _formKey.currentState?.validate();
      return;
    }

    // 3. التحقق العام من النموذج
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('يرجى إكمال جميع الحقول المطلوبة', isError: true);
      return;
    }

    // 4. التحقق من الشروط والأحكام
    if (!_acceptedTerms) {
      _showSnackBar('يرجى الموافقة على الشروط والأحكام للمتابعة', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userModel = UserModel(
        uid: widget.uid,
        phone: widget.phone,
        name: _nameController.text.trim(),
        province: _selectedProvince,
        gender: _selectedGender,
        birthDate: _selectedBirthDate,
        userType: 'customer',
      );

      await _userService.saveUser(userModel);
      await _userService.updateCache(userModel);

      final countryCode = AppProvinces.detectCountryCodeFromPhone(widget.phone);
      final country = CountryService.instance.allCountries[countryCode];
      if (country != null) {
        await CountryService.instance.selectCountry(country);
      }

      await SessionService.instance.registerDevice(widget.uid, 'customer');
      await NotificationService.instance.updateFcmTokenOnLogin();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const StartScreen()),
          (route) => false,
        );

        await SessionService.instance.startSessionListener(widget.uid, 'customer');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('حدث خطأ أثناء حفظ البيانات. حاول مرة أخرى.', isError: true);
      }
    }
  }

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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'إكمال البيانات الحسابية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
              tooltip: 'تسجيل الخروج',
              onPressed: () => AuthService.instance.signOut(),
            ),
          ],
        ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'جاري إنشاء حسابك...',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // أيقونة ترحيبية
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'مرحباً بك في تاكسيكوم!',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'يرجى إدخال اسمك ومحافظتك للبدء في استخدام التطبيق',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  // 1. حقل الاسم الكامل (إجباري)
                  TextFormField(
                    controller: _nameController,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال الاسم الكامل';
                      }
                      if (val.trim().length < 3) {
                        return 'الاسم قصير جداً';
                      }
                      return null;
                    },
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'الاسم الكامل *',
                      hintText: 'أدخل اسمك الكريم',
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. المحافظة (إجباري)
                  ProvinceCityPicker(
                    value: _selectedProvince,
                    countryCode: _countryCode,
                    labelText: 'المحافظة',
                    isRequired: true,
                    fillColor: Colors.white,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedProvince = val);
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── قسم الخيارات الاختيارية (الجنس وتاريخ الميلاد) ─────────────
                  ProfileAdditionalInfoCard(
                    selectedGender: _selectedGender,
                    selectedBirthDate: _selectedBirthDate,
                    onGenderChanged: (val) => setState(() => _selectedGender = val),
                    onSelectBirthDate: _selectBirthDate,
                  ),

                  const SizedBox(height: 20),

                  // ── الشروط والأحكام ──────────────────────────────────────────
                  TermsConditionsCheckbox(
                    value: _acceptedTerms,
                    onChanged: (val) => setState(() => _acceptedTerms = val),
                  ),

                  const SizedBox(height: 24),

                  // زر الحفظ والدخول
                  CustomButton(
                    text: 'إكمال والدخول للتطبيق',
                    onPressed: _saveProfileAndStart,
                    isLoading: _isLoading,
                    borderRadius: 16,
                    height: 56,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
