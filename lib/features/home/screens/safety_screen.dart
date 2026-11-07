import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/country_service.dart';
import '../../trips/models/trip_request_model.dart';
import '../../trips/utils/trip_calculation_helper.dart';
import '../../../core/services/location_service.dart';

class SafetyScreen extends StatelessWidget {
  final TripRequestModel trip;

  const SafetyScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.safety,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Illustration
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.security_rounded,
                  size: 100,
                  color: AppColors.primary,
                ),
                Positioned(
                  right: 40,
                  top: 40,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            // Options
            _buildOptionItem(
              context,
              icon: Icons.share_outlined,
              title: l10n.shareTrip,
              subtitle: l10n.shareTripSubtitle,
              onTap: () => _shareTripDetails(context),
            ),
            const Divider(height: 1),
            _buildOptionItem(
              context,
              icon: Icons.support_agent_rounded,
              title: l10n.dontFeelSafe,
              subtitle: l10n.contactSafetyTeam,
              onTap: () => _contactSupport(context),
            ),
            const Divider(height: 1),
            _buildOptionItem(
              context,
              icon: Icons.notification_important_rounded,
              iconColor: Colors.red,
              title: l10n.requestAmbulance,
              subtitle: l10n.callEmergencyNumber,
              onTap: () => _callEmergency(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      onTap: onTap,
      leading: Icon(
        Icons.arrow_back_ios_rounded,
        size: 16,
        color: Colors.grey[400],
      ),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? Colors.grey[600]),
      ),
      title: Text(
        title,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Cairo',
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _shareTripDetails(BuildContext context) async {
    // الحصول على الموقع الحالي للزبون
    final position = await LocationService.instance.getCurrentPosition();
    String locationLink = '';
    
    if (position != null) {
      // إنشاء رابط خرائط جوجل
      locationLink = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
    }
    
    final liveTrackLink = 'https://taxicom.app/track/${trip.id}';
    
    // Prepare comprehensive trip details for sharing
    final String details = '''
🚕 تفاصيل رحلة Taxicom الحية

━━━━━━━━━━━━━━━━━━━
👤 معلومات السائق والسيارة:
الاسم: ${trip.driverName ?? 'غير معروف'}
رقم الهاتف: ${trip.driverPhone ?? 'غير متوفر'}
${trip.carModel != null && trip.carModel!.isNotEmpty ? 'السيارة: ${trip.carModel}${trip.carColor != null && trip.carColor!.isNotEmpty ? ' - ${trip.carColor}' : ''}\n' : ''}${trip.carNumber != null && trip.carNumber!.isNotEmpty ? 'رقم اللوحة: ${trip.carNumber}\n' : ''}
━━━━━━━━━━━━━━━━━━━
📍 تفاصيل الرحلة:
من: ${trip.pickupAddress}
إلى: ${trip.destinationAddress}

السعر: ${TripCalculationHelper.formatPrice(trip.price)} ${CountryService.instance.selectedCountry.currencyAr}

━━━━━━━━━━━━━━━━━━━
🛡️ تتبع مسار رحلتي مباشرة:
$liveTrackLink

📌 نقطة موقعي الحالية:
${locationLink.isNotEmpty ? locationLink : 'غير متاح'}

━━━━━━━━━━━━━━━━━━━
تطبيق Taxicom - أسرع وأأمن 🛡️
    ''';
    
    // Use native share dialog
    Share.share(
      details,
      subject: 'مشاركة مسار رحلة Taxicom',
    );
  }

  Future<void> _contactSupport(BuildContext context) async {
    // Support number
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: '+9647737007700',
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).cannotMakeCall)),
        );
      }
    }
  }

  Future<void> _callEmergency() async {
    final countryCode = CountryService.instance.selectedCountry.code.toUpperCase();
    String emergencyNumber = '104'; // Default Iraq Police / 112
    if (countryCode == 'EG') {
      emergencyNumber = '122'; // Egypt
    } else if (countryCode == 'SA') {
      emergencyNumber = '999'; // Saudi
    } else if (countryCode == 'AE') {
      emergencyNumber = '999'; // UAE
    } else if (countryCode == 'JO') {
      emergencyNumber = '911'; // Jordan
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: emergencyNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}
