import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/favorite_locations_service.dart';

/// قائمة الأماكن المقترحة والمواقع المفضلة الموحدة
class HomeSuggestionsAndFavorites extends StatelessWidget {
  final List<FavoriteLocation> favorites;
  final String? province;
  final ValueChanged<LatLng> onSelectLocation;
  final VoidCallback onAddFavorite;
  final Color dotColor;

  const HomeSuggestionsAndFavorites({
    super.key,
    required this.favorites,
    required this.province,
    required this.onSelectLocation,
    required this.onAddFavorite,
    this.dotColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final userProvince = province?.toLowerCase();
    final List<Map<String, dynamic>> suggestions;

    // عرض المقترحات فقط للمحافظات الأربع المحددة في النظام، وإلا قائمة فارغة
    if (userProvince == 'baghdad') {
      suggestions = AppConstants.baghdadSuggestions;
    } else if (userProvince == 'basra') {
      suggestions = AppConstants.basraSuggestions;
    } else if (userProvince == 'muthanna' || userProvince == 'samawah') {
      suggestions = AppConstants.samawahSuggestions;
    } else if (userProvince == 'kirkuk') {
      suggestions = AppConstants.kirkukSuggestions;
    } else {
      suggestions = const [];
    }

    if (favorites.isEmpty && suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // قسم المفضلة
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.favoriteLocations,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: onAddFavorite,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                l10n.addLocation,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (favorites.isNotEmpty) ...[
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final fav = favorites[index];
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ActionChip(
                    avatar: const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      fav.name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onPressed: () => onSelectLocation(fav.location),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // الأماكن المقترحة (تظهر فقط إذا كانت المحافظة تحتوي على مقترحات معرفة)
        if (suggestions.isNotEmpty) ...[
          Text(
            l10n.suggestedLocations,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...suggestions.map(
            (place) => _buildSuggestionItem(
              name: place['name'] as String,
              address: place['address'] as String,
              location: LatLng(place['lat'] as double, place['lng'] as double),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestionItem({
    required String name,
    required String address,
    required LatLng location,
  }) {
    return InkWell(
      onTap: () => onSelectLocation(location),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on_rounded, color: dotColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    address,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
