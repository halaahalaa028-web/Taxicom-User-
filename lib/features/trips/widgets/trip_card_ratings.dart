import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/trip_request_model.dart';

/// قسم عرض تقييمات الرحلة (تقييم الراكب والسائق)
class TripCardRatings extends StatelessWidget {
  final TripRequestModel trip;

  const TripCardRatings({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.ratingsSection,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (trip.passengerRating != null)
          _buildRatingItem(
            label: loc.yourRatingForDriver,
            rating: trip.passengerRating!,
            note: trip.passengerNote,
          ),
        if (trip.driverRating != null)
          _buildRatingItem(
            label: loc.driverRatingForYou,
            rating: trip.driverRating!,
            note: trip.driverNote,
          ),
      ],
    );
  }

  Widget _buildRatingItem({
    required String label,
    required int rating,
    String? note,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < rating ? Colors.black : AppColors.border,
                    size: 15,
                  );
                }),
              ),
            ],
          ),
          if (note != null && note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '"$note"',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
