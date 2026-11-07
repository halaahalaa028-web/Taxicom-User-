import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_provinces.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/widgets.dart';
import '../../settings/widgets/delete_account_dialog.dart';
import '../../settings/widgets/delete_account_section.dart';

/// شاشة تفاصيل وتعديل بيانات الملف الشخصي
class ProfileDetailsScreen extends StatefulWidget {
  final UserModel user;

  const ProfileDetailsScreen({super.key, required this.user});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;

  late UserModel _currentUser;
  late String _selectedProvince;
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _nameController = TextEditingController(text: _currentUser.name);
    _addressController = TextEditingController(text: _currentUser.address ?? '');

    final countryCode = AppProvinces.detectCountryCodeFromPhone(_currentUser.phone);
    final defaultProv = AppProvinces.getDefaultProvinceForCountry(countryCode);
    final prov = (_currentUser.province ?? defaultProv).toLowerCase();
    _selectedProvince = prov;
    _selectedGender = _currentUser.gender;
    _selectedBirthDate = _currentUser.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedUser = _currentUser.copyWith(
        name: _nameController.text.trim(),
        province: _selectedProvince,
        address: _addressController.text.trim(),
        gender: _selectedGender,
        birthDate: _selectedBirthDate,
      );

      await UserService.instance.saveUser(updatedUser);
      await UserService.instance.updateCache(updatedUser);

      if (mounted) {
        setState(() {
          _currentUser = updatedUser;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).saveSuccess,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).generalError,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.profileTitle,
          style: const TextStyle(
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: l10n.saving,
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

                  // صورة البروفايل الرمزية (مونوكروم نظيف)
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // رقم الهاتف (للقراءة فقط)
                  Text(
                    _currentUser.phone,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  // 1. حقل الاسم الكامل
                  TextFormField(
                    controller: _nameController,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n.enterFullName;
                      }
                      if (val.trim().length < 3) {
                        return l10n.nameTooShort;
                      }
                      return null;
                    },
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                    decoration: InputDecoration(
                      labelText: '${l10n.fullNameField} *',
                      hintText: l10n.fullNameHint,
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

                  // 2. المحافظة
                  ProvinceCityPicker(
                    value: _selectedProvince,
                    countryCode: AppProvinces.detectCountryCodeFromPhone(_currentUser.phone),
                    labelText: l10n.provinceField,
                    isRequired: true,
                    fillColor: Colors.white,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedProvince = val);
                    },
                  ),

                  const SizedBox(height: 16),

                  // 3. العنوان التفصيلي
                  TextFormField(
                    controller: _addressController,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                    decoration: InputDecoration(
                      labelText: l10n.detailedAddress,
                      hintText: l10n.detailedAddressHint,
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                      prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
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

                  const SizedBox(height: 28),

                  // ── قسم الخيارات الاختيارية (الجنس وتاريخ الميلاد) ─────────────
                  ProfileAdditionalInfoCard(
                    selectedGender: _selectedGender,
                    selectedBirthDate: _selectedBirthDate,
                    onGenderChanged: (val) => setState(() => _selectedGender = val),
                    onSelectBirthDate: _selectBirthDate,
                  ),

                  const SizedBox(height: 32),

                  // زر حفظ التغييرات
                  CustomButton(
                    text: l10n.saveChanges,
                    onPressed: _saveProfile,
                    isLoading: _isLoading,
                    borderRadius: 16,
                    height: 56,
                  ),

                  const SizedBox(height: 24),

                  // زر وبطاقة حذف الحساب
                  DeleteAccountSection(
                    onTap: () => DeleteAccountDialog.show(context),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
