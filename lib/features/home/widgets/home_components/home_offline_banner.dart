/// شريط تنبيه انقطاع الإنترنت التفاعلي أعلى الشاشة الرئيسية
///
/// يظهر بشكل انسيابي متحرك أعلى الخريطة فور اكتشاف انقطاع الإنترنت
/// ويوفر زراً فورياً لإعادة الفحص وتحديث الخريطة
library;

import 'package:flutter/material.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/widgets/dialogs/no_internet_dialog.dart';

class HomeOfflineBanner extends StatefulWidget {
  final VoidCallback? onReconnected;

  const HomeOfflineBanner({
    super.key,
    this.onReconnected,
  });

  @override
  State<HomeOfflineBanner> createState() => _HomeOfflineBannerState();
}

class _HomeOfflineBannerState extends State<HomeOfflineBanner> {
  bool _isChecking = false;

  Map<String, String> _getTexts() {
    final lang = LanguageService.instance.currentLanguage;
    switch (lang) {
      case AppLanguage.english:
        return {
          'offline': 'No Internet — Maps are offline',
          'retry': 'Retry',
        };
      case AppLanguage.kurdish:
        return {
          'offline': 'هێڵی ئینتەرنێت نییە — نەخشە پەیوەست نییە',
          'retry': 'دووبارە',
        };
      case AppLanguage.arabic:
      default:
        return {
          'offline': 'لا يوجد إنترنت — الخريطة غير متصلة',
          'retry': 'إعادة المحاولة',
        };
    }
  }

  Future<void> _handleRetry() async {
    setState(() => _isChecking = true);
    final isConnected = await NetworkService.instance.hasInternetConnection(forceRefresh: true);
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (isConnected) {
      widget.onReconnected?.call();
    } else {
      NoInternetDialog.show(context, onRetry: widget.onReconnected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = _getTexts();

    return ValueListenableBuilder<bool>(
      valueListenable: NetworkService.instance.isConnectedNotifier,
      builder: (context, isConnected, child) {
        return AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: !isConnected ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.6), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    texts['offline']!,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _isChecking ? null : _handleRetry,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text(
                            texts['retry']!,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          secondChild: const SizedBox.shrink(),
        );
      },
    );
  }
}
