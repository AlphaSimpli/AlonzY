import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter_app/services/learned_matching_service.dart';

Map<String, dynamic> modelFixture() => {
  'source': 'synthetic',
  'features': ['detour_min', 'time_gap_min', 'pref_score', 'price'],
  'feature_units': {
    'detour_min': 'minutes',
    'time_gap_min': 'whole minutes',
    'pref_score': 'points from 0 to 15',
    'price': 'CAD',
  },
  'coefficients': <String, dynamic>{
    'detour_min': -0.04805053066637545,
    'pref_score': 0.18764209248118835,
    'price': -0.013943310092670459,
    'time_gap_min': -0.013011450737802556,
  },
  'intercept': 0.5147514125519183,
};

class MemoryModelBundle extends CachingAssetBundle {
  MemoryModelBundle(this.contents);

  final String contents;
  String? requestedPath;

  @override
  Future<ByteData> load(String key) async {
    requestedPath = key;
    final bytes = Uint8List.fromList(utf8.encode(contents));
    return ByteData.sublistView(bytes);
  }
}

class FailingModelBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw StateError('Asset unavailable: $key');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the model bundled with the actual application', () async {
    final model = await LearnedMatchingService.load();
    expect(model.source, isNotEmpty);
    final output = model.predictProbability(
      detourMinutes: 12,
      timeGapMinutes: 35,
      preferenceScore: 10,
      price: 25,
    );
    expect(output.isFinite, isTrue);
    expect(output, inInclusiveRange(0.0, 1.0));
  });

  test(
    'loads JSON from an injected bundle using the expected asset path',
    () async {
      final bundle = MemoryModelBundle(jsonEncode(modelFixture()));
      final model = await LearnedMatchingService.load(bundle: bundle);
      expect(bundle.requestedPath, LearnedMatchingService.modelAssetPath);
      expect(model.isSynthetic, isTrue);
    },
  );

  test('distinguishes a feedback model from a synthetic model', () {
    final json = modelFixture()..['source'] = 'feedback.csv';
    expect(LearnedMatchingService.fromJson(json).isSynthetic, isFalse);
  });

  test('matches Python inference on three fixed numerical examples', () {
    final model = LearnedMatchingService.fromJson(modelFixture());
    // Expected outputs were calculated in Python from this same fixture.
    final examples = [
      (0.0, 0, 15.0, 10.0, 0.9604543099633832),
      (12.0, 35, 10.0, 25.0, 0.733134118453642),
      (45.0, 90, 5.0, 60.0, 0.06198106634906272),
    ];
    for (final row in examples) {
      expect(
        model.predictProbability(
          detourMinutes: row.$1,
          timeGapMinutes: row.$2,
          preferenceScore: row.$3,
          price: row.$4,
        ),
        closeTo(row.$5, 1e-12),
      );
    }
  });

  test('uses feature names rather than their order in JSON', () {
    final json = modelFixture();
    json['features'] = ['price', 'pref_score', 'time_gap_min', 'detour_min'];
    final model = LearnedMatchingService.fromJson(json);
    expect(
      model.predictProbability(
        detourMinutes: 12,
        timeGapMinutes: 35,
        preferenceScore: 10,
        price: 25,
      ),
      closeTo(0.733134118453642, 1e-12),
    );
  });

  test(
    'keeps the sigmoid finite for very large positive and negative logits',
    () {
      for (final intercept in [1000.0, -1000.0]) {
        final json = modelFixture();
        json['intercept'] = intercept;
        json['coefficients'] = {
          'detour_min': 0,
          'time_gap_min': 0,
          'pref_score': 0,
          'price': 0,
        };
        final model = LearnedMatchingService.fromJson(json);
        final output = model.predictProbability(
          detourMinutes: 0,
          timeGapMinutes: 0,
          preferenceScore: 0,
          price: 0,
        );
        expect(output, intercept > 0 ? 1.0 : 0.0);
      }
    },
  );

  test('rejects missing or unsupported features', () {
    for (final features in [
      null,
      ['detour_min', 'time_gap_min', 'pref_score', 'unknown'],
      ['detour_min', 'time_gap_min', 'pref_score', 'pref_score'],
    ]) {
      final json = modelFixture()..['features'] = features;
      expect(
        () => LearnedMatchingService.fromJson(json),
        throwsFormatException,
      );
    }
  });

  test('rejects the old preference scale or missing unit metadata', () {
    final json = modelFixture();
    (json['feature_units'] as Map)['pref_score'] = 'fraction from 0 to 1';
    expect(() => LearnedMatchingService.fromJson(json), throwsFormatException);
    json.remove('feature_units');
    expect(() => LearnedMatchingService.fromJson(json), throwsFormatException);
  });

  test('rejects missing, textual or non-finite coefficients', () {
    for (final invalid in [null, '0.2', double.nan, double.infinity]) {
      final json = modelFixture();
      (json['coefficients'] as Map)['price'] = invalid;
      expect(
        () => LearnedMatchingService.fromJson(json),
        throwsFormatException,
      );
    }
  });

  test('rejects missing or non-finite intercepts', () {
    for (final invalid in [null, double.nan, double.infinity]) {
      final json = modelFixture()..['intercept'] = invalid;
      expect(
        () => LearnedMatchingService.fromJson(json),
        throwsFormatException,
      );
    }
  });

  test('rejects a missing data source', () {
    final json = modelFixture()..remove('source');
    expect(() => LearnedMatchingService.fromJson(json), throwsFormatException);
  });

  test('rejects invalid inference inputs', () {
    final model = LearnedMatchingService.fromJson(modelFixture());
    for (final invalid in [-1.0, double.nan, double.infinity]) {
      expect(
        () => model.predictProbability(
          detourMinutes: invalid,
          timeGapMinutes: 0,
          preferenceScore: 15,
          price: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => model.predictProbability(
          detourMinutes: 0,
          timeGapMinutes: 0,
          preferenceScore: invalid,
          price: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => model.predictProbability(
          detourMinutes: 0,
          timeGapMinutes: 0,
          preferenceScore: 15,
          price: invalid,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => model.predictProbability(
        detourMinutes: 0,
        timeGapMinutes: -1,
        preferenceScore: 15,
        price: 10,
      ),
      throwsArgumentError,
    );
    expect(
      () => model.predictProbability(
        detourMinutes: 0,
        timeGapMinutes: 0,
        preferenceScore: 16,
        price: 10,
      ),
      throwsArgumentError,
    );
  });

  test('rejects invalid JSON or a JSON array', () async {
    for (final text in ['invalid JSON', '[]']) {
      await expectLater(
        LearnedMatchingService.load(bundle: MemoryModelBundle(text)),
        throwsFormatException,
      );
    }
  });

  test('propagates asset loading errors', () async {
    await expectLater(
      LearnedMatchingService.load(bundle: FailingModelBundle()),
      throwsStateError,
    );
  });
}
