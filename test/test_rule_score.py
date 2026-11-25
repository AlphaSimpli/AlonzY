"""Tests du score a regles, sans dependance externe."""

import unittest

from ml.rule_score import calculate_rule_score


class RuleScoreTest(unittest.TestCase):
    def test_perfect_match_scores_100(self):
        self.assertEqual(
            calculate_rule_score(detour_km=0, time_gap_min=0, pref_score=15),
            100.0,
        )

    def test_distance_and_time_components(self):
        # Distance : 25 points ; horaire : 17,5 ; preferences : 15.
        self.assertEqual(
            calculate_rule_score(detour_km=7.5, time_gap_min=35, pref_score=15),
            57.5,
        )

    def test_preference_mismatch_penalty(self):
        self.assertEqual(
            calculate_rule_score(
                detour_km=7.5,
                time_gap_min=35,
                pref_score=10,
                has_preference_mismatch=True,
            ),
            32.5,
        )

    def test_score_cannot_be_negative(self):
        self.assertEqual(
            calculate_rule_score(
                detour_km=15,
                time_gap_min=60,
                pref_score=0,
                has_preference_mismatch=True,
            ),
            0.0,
        )

    def test_no_available_seat_scores_zero(self):
        self.assertEqual(
            calculate_rule_score(
                detour_km=0,
                time_gap_min=0,
                pref_score=15,
                available_seats=0,
            ),
            0.0,
        )

    def test_time_uses_whole_minutes(self):
        self.assertEqual(
            calculate_rule_score(detour_km=0, time_gap_min=10.9, pref_score=15),
            100.0,
        )

    def test_score_is_rounded_to_one_decimal(self):
        self.assertEqual(
            calculate_rule_score(detour_km=1, time_gap_min=11, pref_score=15),
            96.0,
        )

    def test_distance_filter_is_separate_from_score(self):
        # Le score Dart conserve les autres composantes au-dela de 15 km.
        # C'est rankRides qui exclut ces offres avant le classement.
        self.assertEqual(
            calculate_rule_score(detour_km=16, time_gap_min=0, pref_score=15),
            50.0,
        )

    def test_invalid_components_are_rejected(self):
        defaults = {"detour_km": 0, "time_gap_min": 0, "pref_score": 15}
        for field in defaults:
            for invalid in (-1, float("nan"), float("inf")):
                with (
                    self.subTest(field=field, value=invalid),
                    self.assertRaises(ValueError),
                ):
                    calculate_rule_score(**{**defaults, field: invalid})
        with self.assertRaises(ValueError):
            calculate_rule_score(detour_km=0, time_gap_min=0, pref_score=16)


if __name__ == "__main__":
    unittest.main()
