// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxicom_user_app/features/trips/services/trip_request_service.dart';

class MockFirebasePlatform extends FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return FirebaseAppPlatform(
      name ?? 'test',
      options ??
          const FirebaseOptions(
            apiKey: 'test',
            appId: 'test',
            messagingSenderId: 'test',
            projectId: 'test',
          ),
    );
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return FirebaseAppPlatform(
      name,
      const FirebaseOptions(
        apiKey: 'test',
        appId: 'test',
        messagingSenderId: 'test',
        projectId: 'test',
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = MockFirebasePlatform();

  group('Fare Cap Safety Valve Unit Tests', () {
    final tripRequestService = TripRequestService.instance;

    test('getCappedDistance - Normal route (no detour)', () {
      const pickup = LatLng(33.0, 44.0);
      const destination = LatLng(33.036, 44.0); // 4.0 km straight distance

      const double googleDistance = 4.8; // Normal detour (1.2x straight line)

      final double cappedDistance = tripRequestService.getCappedDistance(
        googleDistance: googleDistance,
        pickup: pickup,
        destination: destination,
      );

      expect(cappedDistance, equals(4.8));
    });

    test('getCappedDistance - Extreme detour (detour capped)', () {
      const pickup = LatLng(33.0, 44.0);
      const destination = LatLng(33.036, 44.0); // 4.0 km straight distance

      const double googleDistance =
          10.0; // Winding route detour (2.5x straight line)

      final double cappedDistance = tripRequestService.getCappedDistance(
        googleDistance: googleDistance,
        pickup: pickup,
        destination: destination,
      );

      expect(cappedDistance, closeTo(6.0, 0.1));
    });

    test('getCappedDistance - Short trip buffer (no unfair capping)', () {
      const pickup = LatLng(33.0, 44.0);
      const destination = LatLng(33.009, 44.0); // 1.0 km straight distance

      const double googleDistance = 2.8; // Detour for turnarounds

      final double cappedDistance = tripRequestService.getCappedDistance(
        googleDistance: googleDistance,
        pickup: pickup,
        destination: destination,
      );

      expect(cappedDistance, equals(2.8));
    });

    test('calculatePrice - pricing consistency with coordinates', () {
      const pickup = LatLng(33.0, 44.0);
      const destination = LatLng(33.036, 44.0); // 4.0 km straight distance

      const double detourDistance = 10.0;

      final double rawPrice =
          tripRequestService.calculatePrice(detourDistance);

      final double cappedPrice = tripRequestService.calculatePrice(
        detourDistance,
        pickupLocation: pickup,
        destinationLocation: destination,
      );

      expect(cappedPrice, lessThan(rawPrice));
    });
  });
}
