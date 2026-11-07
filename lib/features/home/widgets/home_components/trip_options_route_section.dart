import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

/// قسم إعدادات المسار (الوجهة الثانية، وقت الانتظار، ذهاب وإياب)
class TripOptionsRouteSection extends StatelessWidget {
  final bool hasSecondDestination;
  final String? secondDestinationAddress;
  final String? waitTime;
  final List<String> waitTimeOptions;
  final bool isRoundTrip;
  final VoidCallback onSelectSecondDestination;
  final VoidCallback onRemoveSecondDestination;
  final ValueChanged<String?> onWaitTimeChanged;
  final ValueChanged<bool> onRoundTripChanged;

  const TripOptionsRouteSection({
    super.key,
    required this.hasSecondDestination,
    required this.secondDestinationAddress,
    required this.waitTime,
    required this.waitTimeOptions,
    required this.isRoundTrip,
    required this.onSelectSecondDestination,
    required this.onRemoveSecondDestination,
    required this.onWaitTimeChanged,
    required this.onRoundTripChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // خيار الوجهة الثانية
        _buildTile(
          icon: Icons.add_location_alt_rounded,
          title: hasSecondDestination && secondDestinationAddress != null
              ? '${l10n.secondDestination} ${secondDestinationAddress!.length > 20 ? "${secondDestinationAddress!.substring(0, 20)}..." : secondDestinationAddress}'
              : l10n.addSecondDestination,
          subtitle: hasSecondDestination
              ? l10n.tapToChangeOrDelete
              : l10n.addSecondDestSubtitle,
          trailing: hasSecondDestination
              ? IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: onRemoveSecondDestination,
                )
              : const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          onTap: onSelectSecondDestination,
        ),

        // خيار وقت الانتظار (يظهر فقط عند وجود وجهة ثانية)
        if (hasSecondDestination) ...[
          const Divider(height: 1),
          _buildTile(
            icon: Icons.timer_rounded,
            title: l10n.waitTime,
            subtitle: waitTime != null ? l10n.formatWaitTime(waitTime!) : l10n.waitTimeSubtitle,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: waitTime,
                hint: Text(l10n.choose, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                items: waitTimeOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(l10n.formatWaitTime(value), style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
                  );
                }).toList(),
                onChanged: onWaitTimeChanged,
              ),
            ),
            onTap: () {},
          ),
        ],

        const Divider(height: 1),

        // خيار ذهاب وإياب
        _buildTile(
          icon: Icons.loop_rounded,
          title: l10n.roundTripLabel,
          subtitle: l10n.roundTripSubtitle,
          trailing: Switch(
            value: isRoundTrip,
            activeThumbColor: AppColors.primary,
            onChanged: onRoundTripChanged,
          ),
          onTap: () => onRoundTripChanged(!isRoundTrip),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
