import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supabase_flutter_app/maps/map_types.dart';
import 'package:supabase_flutter_app/theme/app_theme.dart';
import 'package:supabase_flutter_app/widgets/auth_layout.dart';

void main() {
  group('MapLocation', () {
    test('stores coordinates', () {
      const location = MapLocation(40.7128, -74.0060);
      expect(location.latitude, 40.7128);
      expect(location.longitude, -74.0060);
    });

    test('value equality works', () {
      const a = MapLocation(1.0, 2.0);
      const b = MapLocation(1.0, 2.0);
      const c = MapLocation(1.0, 3.0);
      expect(a, b);
      expect(a == c, isFalse);
    });

    test('serializes to json', () {
      const location = MapLocation(37.7749, -122.4194);
      expect(location.toJson(), {
        'latitude': 37.7749,
        'longitude': -122.4194,
      });
    });
  });

  group('MapViewConfig', () {
    test('uses sensible defaults', () {
      const config = MapViewConfig();
      expect(config.initialCenter.latitude, 37.7749);
      expect(config.initialZoom, 13);
      expect(config.showUserLocation, isTrue);
      expect(config.trackCameraPosition, isFalse);
    });

    test('copyWith overrides only provided fields', () {
      const config = MapViewConfig(initialZoom: 10);
      final updated = config.copyWith(initialZoom: 15, trackCameraPosition: true);
      expect(updated.initialZoom, 15);
      expect(updated.trackCameraPosition, isTrue);
      expect(updated.initialCenter, config.initialCenter);
    });
  });

  group('AppTheme', () {
    test('is Material 3 with the brand primary colour', () {
      final theme = AppTheme.light;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primary);
    });
  });

  testWidgets('AuthLayout renders title, subtitle and children',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AuthLayout(
          title: 'Welcome back',
          subtitle: 'Sign in to continue.',
          showBackButton: false,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to continue.'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });
}