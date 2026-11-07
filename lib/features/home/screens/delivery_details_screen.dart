/// شاشة إدخال تفاصيل التوصيل
/// 
/// تتيح للمستخدم إدخال بيانات المستلم وتفاصيل الشحنة
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

/// شاشة تفاصيل التوصيل
class DeliveryDetailsScreen extends StatefulWidget {
  final String destinationAddress;
  final Function(String name, String phone, String? description, bool paidByReceiver) onConfirm;

  const DeliveryDetailsScreen({
    super.key,
    required this.destinationAddress,
    required this.onConfirm,
  });

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // المتحكمات
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // حالة الدفع
  bool _paidByReceiver = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.destinationAddress;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// معالجة التأكيد
  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onConfirm(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        _paidByReceiver,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).destinationDetails,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عنوان القسم
                      Text(
                        AppLocalizations.of(context).receiverSection,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // اسم المستلم
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).receiverFullName,
                          labelStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        style: const TextStyle(fontFamily: 'Cairo'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context).enterReceiverName;
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // رقم الهاتف
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).receiverPhone,
                          hintText: AppLocalizations.of(context).phoneExample,
                          hintStyle: const TextStyle(fontSize: 12),
                          helperText: '0/11',
                          labelStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        style: const TextStyle(fontFamily: 'Cairo'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context).enterPhone;
                          }
                          // تحقق بسيط من الطول
                          if (value.trim().length < 10) {
                            return AppLocalizations.of(context).phoneTooShort;
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // العنوان (للقراءة فقط أو للتعديل)
                      TextFormField(
                        controller: _addressController,
                        // readOnly: true, // يمكن جعله للقراءة فقط إذا أردنا الالتزام بالخريطة
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).addressLabel,
                          hintText: AppLocalizations.of(context).addressExample,
                          helperText: AppLocalizations.of(context).addressExample,
                          labelStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        style: const TextStyle(fontFamily: 'Cairo'),
                        maxLines: 2,
                        minLines: 1,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context).enterAddress;
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // وصف اختياري
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).optionalDescription,
                          labelStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        style: const TextStyle(fontFamily: 'Cairo'),
                        maxLines: 2,
                        minLines: 1,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // خيار الدفع
                      Row(
                        children: [
                          Switch(
                            value: _paidByReceiver,
                            onChanged: (value) {
                              setState(() {
                                _paidByReceiver = value;
                              });
                            },
                            activeThumbColor: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).paidByReceiver,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // زر التأكيد
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200], // لون رمادي كما في الصورة
                      foregroundColor: Colors.black, // نص أسود
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).confirmOrder,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
