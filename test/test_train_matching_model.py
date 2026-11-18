import tempfile
import unittest
import math
import csv
import json
from pathlib import Path

from ml.train_matching_model import build_synthetic_dataset, train_and_export


class MatchingModelTrainingTest(unittest.TestCase):
    def test_synthetic_dataset_has_requested_dimensions_and_is_repeatable(self):
        first = build_synthetic_dataset()
        second = build_synthetic_dataset()
        self.assertEqual(first[0].shape, (2000, 4))
        self.assertEqual(first[1].shape, (2000,))
        self.assertEqual(first[2:], (200, 2000))
        self.assertTrue((first[0] == second[0]).all())
        self.assertTrue((first[1] == second[1]).all())

    def test_training_exports_metrics_and_coefficients(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "model.json"
            artifact = train_and_export(output)
            self.assertEqual(artifact["training_rows"], 1400)
            self.assertEqual(artifact["test_rows"], 600)
            self.assertEqual(
                set(artifact["coefficients"]),
                {"detour_min", "time_gap_min", "pref_score", "price"},
            )
            self.assertIn("roc_auc", artifact["metrics"])
            self.assertIn("log_loss", artifact["metrics"])
            self.assertIn("logistic_regression", artifact["metrics"])
            self.assertIn("rule_score", artifact["metrics"])
            self.assertGreaterEqual(artifact["metrics"]["roc_auc"], 0.5)
            self.assertLessEqual(artifact["metrics"]["roc_auc"], 1.0)
            self.assertTrue(math.isfinite(artifact["metrics"]["log_loss"]))
            self.assertGreater(artifact["metrics"]["log_loss"], 0)
            self.assertTrue(output.exists())

    def test_json_feedback_ignores_unlabeled_rows_and_compares_models(self):
        with tempfile.TemporaryDirectory() as directory:
            feedback = Path(directory) / "feedback.json"
            rows = [
                {
                    "detour_min": index + 1,
                    "time_gap_min": index * 2,
                    "pref_score": 15 if index % 2 else 5,
                    "price": 20 + index,
                    "rule_score": 80 if index % 2 else 20,
                    "accepted": bool(index % 2),
                }
                for index in range(40)
            ]
            rows.append(
                {
                    "detour_min": None,
                    "time_gap_min": None,
                    "pref_score": None,
                    "price": None,
                    "rule_score": None,
                    "accepted": None,
                }
            )
            feedback.write_text(json.dumps({"data": rows}), encoding="utf-8")
            artifact = train_and_export(Path(directory) / "model.json", feedback)

            self.assertEqual(artifact["source"], str(feedback))
            self.assertEqual(artifact["labeled_rows"], 40)
            self.assertEqual(artifact["unlabeled_rows_ignored"], 1)
            self.assertEqual(artifact["training_rows"], 28)
            self.assertEqual(artifact["test_rows"], 12)
            for model_metrics in (
                artifact["metrics"]["logistic_regression"],
                artifact["metrics"]["rule_score"],
            ):
                self.assertIn("roc_auc", model_metrics)
                self.assertTrue(math.isfinite(model_metrics["log_loss"]))

    def test_csv_feedback_is_supported(self):
        with tempfile.TemporaryDirectory() as directory:
            feedback = Path(directory) / "feedback.csv"
            fields = [
                "detour_min",
                "time_gap_min",
                "pref_score",
                "price",
                "rule_score",
                "accepted",
            ]
            with feedback.open("w", newline="", encoding="utf-8") as file:
                writer = csv.DictWriter(file, fieldnames=fields)
                writer.writeheader()
                for index in range(20):
                    writer.writerow(
                        {
                            "detour_min": index + 1,
                            "time_gap_min": index * 3,
                            "pref_score": index % 16,
                            "price": index + 10,
                            "rule_score": 75 if index % 2 else 25,
                            "accepted": "true" if index % 2 else "false",
                        }
                    )

            artifact = train_and_export(Path(directory) / "model.json", feedback)

            self.assertEqual(artifact["labeled_rows"], 20)
            self.assertEqual(artifact["metrics"]["rule_score"]["roc_auc"], 1.0)

    def test_feedback_requires_both_acceptance_labels(self):
        with tempfile.TemporaryDirectory() as directory:
            feedback = Path(directory) / "feedback.json"
            rows = [
                {
                    "detour_min": 1,
                    "time_gap_min": 2,
                    "pref_score": 3,
                    "price": 4,
                    "rule_score": 50,
                    "accepted": True,
                }
            ]
            feedback.write_text(json.dumps(rows), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "both accepted=true"):
                train_and_export(Path(directory) / "model.json", feedback)


if __name__ == "__main__":
    unittest.main()
