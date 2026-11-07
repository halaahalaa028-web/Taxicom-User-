import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/places_service.dart';
import '../../services/favorite_locations_service.dart';
import 'home_location_search_bar.dart';
import 'home_search_results_list.dart';
import 'home_suggestions_and_favorites.dart';

/// لوحة السحب السفلية لاختيار وتأكيد نقطة الانطلاق (Pickup Sheet)
class HomePickupSelectionSheet extends StatelessWidget {
  final DraggableScrollableController sheetController;
  final double sheetExtent;
  final TextEditingController searchController;
  final bool isLoadingAddress;
  final bool isMapMoving;
  final String currentAddress;
  final List<PlaceSuggestion> searchResults;
  final bool isSearching;
  final List<FavoriteLocation> favorites;
  final String? province;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PlaceSuggestion> onSelectSearchResult;
  final ValueChanged<LatLng> onSelectSuggestedLocation;
  final VoidCallback onAddFavorite;
  final VoidCallback onConfirmPickup;
  final VoidCallback onCollapsedSearchTap;

  const HomePickupSelectionSheet({
    super.key,
    required this.sheetController,
    required this.sheetExtent,
    required this.searchController,
    required this.isLoadingAddress,
    required this.isMapMoving,
    required this.currentAddress,
    required this.searchResults,
    required this.isSearching,
    required this.favorites,
    required this.province,
    required this.onSearchChanged,
    required this.onSelectSearchResult,
    required this.onSelectSuggestedLocation,
    required this.onAddFavorite,
    required this.onConfirmPickup,
    required this.onCollapsedSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = sheetExtent > 0.32;

    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: 0.28,
      minChildSize: 0.28,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.28, 0.55, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              // مقبض السحب
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // شريط البحث الموحد
              HomeLocationSearchBar(
                controller: searchController,
                isExpanded: isExpanded,
                isLoading: isLoadingAddress || isMapMoving,
                currentAddress: currentAddress,
                placeholderText: AppLocalizations.of(context).moveMapToSelectLocation,
                dotColor: AppColors.primary,
                onChanged: onSearchChanged,
                onCollapsedTap: onCollapsedSearchTap,
              ),

              const SizedBox(height: 16),

              // زر تأكيد نقطة الانطلاق
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isMapMoving ? null : onConfirmPickup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.disabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context).confirmPickup,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),
              ),

              // محتوى التمرير الموسع
              if (isExpanded) ...[
                const SizedBox(height: 20),
                if (searchController.text.isNotEmpty)
                  HomeSearchResultsList(
                    searchResults: searchResults,
                    isSearching: isSearching,
                    onSelectResult: onSelectSearchResult,
                    dotColor: AppColors.primary,
                  )
                else
                  HomeSuggestionsAndFavorites(
                    favorites: favorites,
                    province: province,
                    onSelectLocation: onSelectSuggestedLocation,
                    onAddFavorite: onAddFavorite,
                    dotColor: AppColors.primary,
                  ),
              ],
            ],
          ),
        ),
      );
      },
    );
  }
}
