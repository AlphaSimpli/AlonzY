import 'package:supabase_flutter_app/models/matching_models.dart';
import 'package:supabase_flutter_app/services/matching_service.dart';

void main() {
  final service = MatchingService();

  final idealOffer = RideOffer(
    id: 'offer_01',
    driverName: 'Aisha',
    startLatitude: 38.9284,
    startLongitude: -77.0322,
    endLatitude: 38.9450,
    endLongitude: -77.0010,
    departureTime: DateTime.utc(2026, 9, 20, 18, 0),
    availableSeats: 2,
    allowsSmoking: false,
    acceptsPets: true,
    hasLargeTrunk: true,
  );

  final idealRequest = PassengerRequest(
    id: 'request_01',
    passengerName: 'Leo',
    pickupLatitude: 38.9290,
    pickupLongitude: -77.0305,
    dropoffLatitude: 38.9442,
    dropoffLongitude: -77.0040,
    preferredTime: DateTime.utc(2026, 9, 20, 18, 8),
    isSmoker: false,
    hasPet: true,
    hasLargeLuggage: true,
  );

  final idealResult = service.calculateMatchScore(idealOffer, idealRequest);
  print('Test case 1: Ideal match');
  print('  score: ${idealResult.score}');
  print('  badge: ${idealResult.badgeLabel}');
  print('  detour: ${idealResult.detourKm} km');
  print('  time diff: ${idealResult.timeDifferenceMinutes} minutes');
  print('  eligible: ${idealResult.isEligible}');

  assert(idealResult.score >= 80.0);
  assert(idealResult.isEligible);

  final constrainedOffer = RideOffer(
    id: 'offer_02',
    driverName: 'Marcus',
    startLatitude: 40.7128,
    startLongitude: -74.0060,
    endLatitude: 40.7505,
    endLongitude: -73.9857,
    departureTime: DateTime.utc(2026, 9, 20, 8, 0),
    availableSeats: 1,
    allowsSmoking: true,
    acceptsPets: false,
    hasLargeTrunk: false,
  );

  final constrainedRequest = PassengerRequest(
    id: 'request_02',
    passengerName: 'Nina',
    pickupLatitude: 40.7300,
    pickupLongitude: -74.0100,
    dropoffLatitude: 40.7700,
    dropoffLongitude: -74.0000,
    preferredTime: DateTime.utc(2026, 9, 20, 9, 45),
    isSmoker: true,
    hasPet: true,
    hasLargeLuggage: true,
  );

  final constrainedResult =
      service.calculateMatchScore(constrainedOffer, constrainedRequest);

  print('\nTest case 2: Preference-excluded match');
  print('  score: ${constrainedResult.score}');
  print('  badge: ${constrainedResult.badgeLabel}');
  print('  detour: ${constrainedResult.detourKm} km');
  print('  time diff: ${constrainedResult.timeDifferenceMinutes} minutes');
  print('  eligible: ${constrainedResult.isEligible}');

  assert(constrainedResult.score < 80.0);
  assert(!constrainedResult.isEligible || constrainedResult.score <= 70.0);

  print('\nStandalone matching checks completed successfully.');
}
