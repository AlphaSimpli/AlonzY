import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../maps/map_types.dart';

/// A place returned by the forward geocoding (autocomplete) search.
class PlaceSuggestion {
  final String displayName;
  final MapLocation location;

  const PlaceSuggestion({required this.displayName, required this.location});
}

/// Location helpers: device positioning, forward and reverse geocoding.
///
/// Forward and reverse geocoding are performed against the Nominatim
/// (OpenStreetMap) service, which is free and requires no API key.
class GeocodingService {
  static const String _userAgent = 'Alonzy-App/1.0';

  /// The device's current position, or `null` if permission was denied or the
  /// lookup failed.
  Future<Position?> getCurrentPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// A human-readable address for [location], or the raw coordinates as a
  /// fallback when the lookup fails.
  Future<String> addressFor(MapLocation location) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json&lat=${location.latitude}&lon=${location.longitude}',
      );

      final response = await http
          .get(url, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final address = json['address'] as Map<String, dynamic>? ?? {};
        final road = address['road']?.toString() ?? '';
        final city = (address['city'] ??
                address['town'] ??
                address['village'] ??
                address['suburb'])
            ?.toString() ??
            '';
        final state = address['state']?.toString() ?? '';

        if (road.isNotEmpty && city.isNotEmpty) {
          return state.isNotEmpty ? '$road, $city, $state' : '$road, $city';
        }
        if (city.isNotEmpty) return city;

        final displayName = json['display_name']?.toString();
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }

    return '${location.latitude.toStringAsFixed(4)}, '
        '${location.longitude.toStringAsFixed(4)}';
  }

  /// Forward geocoding (autocomplete) for a free-text [query].
  ///
  /// Returns up to [limit] place suggestions with display names and
  /// coordinates, or an empty list when the lookup fails.
  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    int limit = 6,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&limit=$limit&addressdetails=1&q='
        '${Uri.encodeQueryComponent(trimmed)}',
      );

      final response = await http
          .get(url, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return const [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return const [];

      final suggestions = <PlaceSuggestion>[];
      for (final raw in decoded) {
        final item = raw is Map ? raw : <String, dynamic>{};
        final lat = double.tryParse(item['lat']?.toString() ?? '');
        final lon = double.tryParse(item['lon']?.toString() ?? '');
        final displayName = item['display_name']?.toString() ?? '';

        if (lat == null || lon == null || displayName.isEmpty) continue;
        suggestions.add(
          PlaceSuggestion(
            displayName: displayName,
            location: MapLocation(lat, lon),
          ),
        );
      }
      return suggestions;
    } catch (e) {
      debugPrint('Error searching places: $e');
      return const [];
    }
  }
}
