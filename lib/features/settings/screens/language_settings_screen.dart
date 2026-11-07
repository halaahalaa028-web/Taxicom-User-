/// شاشة إعدادات اللغة والحساب
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/language_service.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/delete_account_section.dart';
import '../widgets/language_card.dart';

/// شاشة إعدادات اللغة وخيارات الحساب
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  late AppLanguage _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = LanguageService.instance.currentLanguage;
  }

  /// تغيير اللغة الحالية
  Future<void> _selectLanguage(AppLanguage language) async {
    if (_selectedLanguage == language) return;

    setState(() {
      _selectedLanguage = language;
    });

    await LanguageService.instance.setLanguage(language);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeLanguages = LanguageService.instance.supportedLanguages;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // عنوان قسم اختيار اللغة
          _buildSectionTitle(l10n.selectLanguage),
          const SizedBox(height: 12),

          // قائمة بطاقات اللغات
          ...activeLanguages.map(
            (language) => LanguageCard(
              language: language,
              isSelected: _selectedLanguage == language,
              onTap: () => _selectLanguage(language),
            ),
          ),

          const SizedBox(height: 32),

          // عنوان قسم بيانات الحساب
          _buildSectionTitle(l10n.accountData),
          const SizedBox(height: 12),

          // زر وبطاقة حذف الحساب
          DeleteAccountSection(
            onTap: () => DeleteAccountDialog.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
