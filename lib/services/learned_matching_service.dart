import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

/// Reads the exported logistic model without changing eligibility or ranking.
///
/// A model trained on synthetic data produces an experimental output, not a
/// calibrated probability of acceptance by real passengers.
class LearnedMatchingService {
  LearnedMatchingService._({
    required this.source,
    required double intercept,
    required Map<String, double> coefficients,
  }) : _intercept = intercept,
       _coefficients = Map<String, double>.unmodifiable(coefficients);

  static const modelAssetPath = 'ml/matching_model_coefficients.json';

  static const _expectedUnits = <String, String>{
    'detour_min': 'minutes',
    'time_gap_min': 'whole minutes',
    'pref_score': 'points from 0 to 15',
    'price': 'CAD',
  };

  final String source;
  final double _intercept;
  final Map<String, double> _coefficients;

  bool get isSynthetic => source == 'synthetic';

  factory LearnedMatchingService.fromJson(Map<String, dynamic> json) {
    final features = json['features'];
    if (features is! List ||
        features.length != _expectedUnits.length ||
        !_expectedUnits.keys.every(features.contains)) {
      throw const FormatException('Unsupported model features.');
    }

    final units = json['feature_units'];
    if (units is! Map ||
        !_expectedUnits.entries.every(
          (entry) => units[entry.key] == entry.value,
        )) {
      throw const FormatException('Unsupported model feature units.');
    }

    final rawCoefficients = json['coefficients'];
    if (rawCoefficients is! Map ||
        rawCoefficients.length != _expectedUnits.length) {
      throw const FormatException('Invalid model coefficients.');
    }
    final coefficients = <String, double>{};
    for (final feature in _expectedUnits.keys) {
      coefficients[feature] = _finiteNumber(
        rawCoefficients[feature],
        'coefficient $feature',
      );
    }

    final source = json['source'];
    if (source is! String || source.trim().isEmpty) {
      throw const FormatException('Missing model data source.');
    }

    return LearnedMatchingService._(
      source: source,
      intercept: _finiteNumber(json['intercept'], 'intercept'),
      coefficients: coefficients,
    );
  }

  static Future<LearnedMatchingService> load({AssetBundle? bundle}) async {
    final text = await (bundle ?? rootBundle).loadString(modelAssetPath);
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The model must be a JSON object.');
    }
    return LearnedMatchingService.fromJson(decoded);
  }

  /// Returns the logistic output in [0, 1], using the original feature units.
  ///
  /// The Python export already reverses standardization. Do not scale again.
  double predictProbability({
    required double detourMinutes,
    required int timeGapMinutes,
    required double preferenceScore,
    required double price,
  }) {
    final values = <String, double>{
      'detour_min': detourMinutes,
      'time_gap_min': timeGapMinutes.toDouble(),
      'pref_score': preferenceScore,
      'price': price,
    };
    for (final entry in values.entries) {
      if (!entry.value.isFinite || entry.value < 0) {
        throw ArgumentError.value(entry.value, entry.key);
      }
    }
    if (preferenceScore > 15) {
      throw ArgumentError.value(preferenceScore, 'pref_score');
    }

    var linear = _intercept;
    for (final feature in _expectedUnits.keys) {
      linear += _coefficients[feature]! * values[feature]!;
    }
    if (!linear.isFinite) {
      throw StateError('The model calculation is not finite.');
    }

    // Stable sigmoid: exp is only evaluated on non-positive values.
    if (linear >= 0) {
      return 1.0 / (1.0 + math.exp(-linear));
    }
    final exponential = math.exp(linear);
    return exponential / (1.0 + exponential);
  }

  static double _finiteNumber(dynamic value, String name) {
    if (value is! num || !value.toDouble().isFinite) {
      throw FormatException('Invalid $name.');
    }
    return value.toDouble();
  }
}
