#!/usr/bin/env python3
"""Train on simulated matches or feedback and compare with application rules."""

from __future__ import annotations

import argparse
import csv
import json
import math
from pathlib import Path
from typing import Any

import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import log_loss, roc_auc_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

if __package__:
    from .rule_score import calculate_rule_score
else:
    from rule_score import calculate_rule_score

SEED = 42
FEATURES = ("detour_min", "time_gap_min", "pref_score", "price")
LABEL = "accepted"
RULE_SCORE = "rule_score"


def build_synthetic_dataset(
    seed: int = SEED,
) -> tuple[np.ndarray, np.ndarray, int, int]:
    """Keep the existing public interface used by the training tests."""
    features, labels, _rules, passengers, offers = _build_synthetic_evaluation(seed)
    return features, labels, passengers, offers


def _build_synthetic_evaluation(
    seed: int = SEED,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, int, int]:
    """Simulate distances and preferences; these are not real OSRM observations."""
    rng = np.random.default_rng(seed)
    passenger_count = 200
    offer_count = 2000

    passenger_smoker = rng.random(passenger_count) < 0.20
    passenger_pet = rng.random(passenger_count) < 0.25
    passenger_luggage = rng.random(passenger_count) < 0.30
    passenger_time_windows = rng.uniform(0.0, 90.0, passenger_count)
    passenger_ids = np.repeat(
        np.arange(passenger_count), offer_count // passenger_count
    )

    # Distances are generated explicitly, never inferred from existing minutes.
    # Speeds and extra delay are assumptions for this simulation, not road data.
    detour_km = rng.uniform(0.0, 15.0, offer_count)
    simulated_speed_kmh = rng.uniform(20.0, 70.0, offer_count)
    detour = detour_km / simulated_speed_kmh * 60.0
    detour += rng.uniform(0.0, 5.0, offer_count)
    departure_gap = np.floor(
        np.abs(
            rng.normal(passenger_time_windows[passenger_ids], 35.0, offer_count)
        ).clip(0, 240)
    )

    # Match _rideOffer's current no-smoking default and simulate other options.
    allows_smoking = np.zeros(offer_count, dtype=bool)
    accepts_pets = rng.random(offer_count) < 0.65
    has_large_trunk = rng.random(offer_count) < 0.50
    smoker_compatible = ~passenger_smoker[passenger_ids] | allows_smoking
    pet_compatible = ~passenger_pet[passenger_ids] | accepts_pets
    luggage_compatible = ~passenger_luggage[passenger_ids] | has_large_trunk
    preference = 5.0 * (
        smoker_compatible.astype(int)
        + pet_compatible.astype(int)
        + luggage_compatible.astype(int)
    )
    preference_mismatch = ~pet_compatible | ~luggage_compatible
    price = rng.uniform(5.0, 100.0, offer_count)

    features = np.column_stack((detour, departure_gap, preference, price))
    latent_acceptance = (
        1.6
        - 0.045 * detour
        - 0.016 * departure_gap
        + 2.2 * (preference / 15.0)
        - 0.018 * price
        - 0.8 * preference_mismatch
        + rng.normal(0.0, 0.8, offer_count)
    )
    probabilities = 1.0 / (1.0 + np.exp(-latent_acceptance))
    labels = rng.binomial(1, probabilities)
    rule_scores = _synthetic_rule_scores(
        features,
        detour_km=detour_km,
        preference_mismatch=preference_mismatch,
    )
    return features, labels, rule_scores, passenger_count, offer_count


def _read_feedback_rows(path: Path) -> list[dict[str, Any]]:
    if not path.is_file():
        raise FileNotFoundError(f"Feedback export not found: {path}")
    if path.suffix.lower() == ".csv":
        with path.open(newline="", encoding="utf-8-sig") as file:
            return list(csv.DictReader(file))
    if path.suffix.lower() == ".json":
        with path.open(encoding="utf-8") as file:
            payload = json.load(file)
        if isinstance(payload, list):
            rows = payload
        elif isinstance(payload, dict):
            rows = payload.get("data", payload.get("rows"))
        else:
            rows = None
        if not isinstance(rows, list) or not all(isinstance(row, dict) for row in rows):
            raise ValueError(
                "JSON feedback must be a list of records or an object with a "
                "'data' or 'rows' list."
            )
        return rows
    raise ValueError("Feedback export must be a .csv or .json file.")


def _parse_label(value: Any, row_number: int) -> int | None:
    if value is None or str(value).strip().lower() in {"", "null", "none"}:
        return None
    normalized = str(value).strip().lower()
    if normalized in {"true", "1", "yes", "y"}:
        return 1
    if normalized in {"false", "0", "no", "n"}:
        return 0
    raise ValueError(
        f"Feedback row {row_number} has invalid '{LABEL}' value: {value!r}."
    )


def _read_feedback_dataset(
    path: Path,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, int]:
    features: list[list[float]] = []
    labels: list[int] = []
    rule_scores: list[float] = []
    unlabeled_rows = 0

    for row_number, row in enumerate(_read_feedback_rows(path), start=2):
        label = _parse_label(row.get(LABEL), row_number)
        if label is None:
            unlabeled_rows += 1
            continue
        try:
            values = [float(row[name]) for name in FEATURES]
            rule_score = float(row[RULE_SCORE])
        except (KeyError, TypeError, ValueError) as error:
            raise ValueError(
                f"Feedback row {row_number} has a missing or invalid numeric "
                f"feature ({error})."
            ) from error
        if not all(math.isfinite(value) for value in (*values, rule_score)):
            raise ValueError(f"Feedback row {row_number} contains a non-finite value.")
        if values[0] < 0 or values[1] < 0 or values[2] < 0 or values[3] < 0:
            raise ValueError(f"Feedback row {row_number} contains a negative feature.")
        if not 0 <= rule_score <= 100:
            raise ValueError(
                f"Feedback row {row_number} has rule_score outside [0, 100]."
            )
        features.append(values)
        labels.append(label)
        rule_scores.append(rule_score)

    if not features:
        raise ValueError("Feedback export contains no rows with an accepted label.")
    return (
        np.asarray(features, dtype=float),
        np.asarray(labels, dtype=int),
        np.asarray(rule_scores, dtype=float),
        unlabeled_rows,
    )


def _synthetic_rule_scores(
    features: np.ndarray,
    *,
    detour_km: np.ndarray,
    preference_mismatch: np.ndarray,
) -> np.ndarray:
    """Use the tested rule calculation, with explicit distance and penalty."""
    if (
        features.ndim != 2
        or features.shape[1] != len(FEATURES)
        or detour_km.shape != (len(features),)
        or preference_mismatch.shape != (len(features),)
    ):
        raise ValueError("Features, distances and preference flags must align.")
    return np.asarray(
        [
            calculate_rule_score(
                detour_km=float(distance),
                time_gap_min=float(row[1]),
                pref_score=float(row[2]),
                has_preference_mismatch=bool(mismatch),
            )
            for row, distance, mismatch in zip(features, detour_km, preference_mismatch)
        ],
        dtype=float,
    )


def train_and_export(
    output_path: Path,
    feedback_data: Path | None = None,
) -> dict[str, object]:
    if feedback_data is None:
        (
            features,
            labels,
            rule_scores,
            passenger_count,
            offer_count,
        ) = _build_synthetic_evaluation()
        source = "synthetic"
        unlabeled_rows = 0
    else:
        features, labels, rule_scores, unlabeled_rows = _read_feedback_dataset(
            feedback_data
        )
        passenger_count = None
        offer_count = len(labels)
        source = str(feedback_data)

    if np.unique(labels).size != 2:
        raise ValueError(
            "Training and ROC AUC evaluation require both accepted=true and "
            "accepted=false labeled rows."
        )
    if np.bincount(labels, minlength=2).min() < 2:
        raise ValueError(
            "At least two labeled rows for each accepted value are required "
            "for a stratified train/test split."
        )
    train_indices, test_indices = train_test_split(
        np.arange(len(labels)),
        test_size=0.30,
        random_state=SEED,
        stratify=labels,
    )
    x_train, x_test = features[train_indices], features[test_indices]
    y_train, y_test = labels[train_indices], labels[test_indices]
    rule_test = rule_scores[test_indices]
    scaler = StandardScaler()
    x_train_scaled = scaler.fit_transform(x_train)
    x_test_scaled = scaler.transform(x_test)
    model = LogisticRegression(
        random_state=SEED,
        max_iter=1000,
        solver="liblinear",
    )
    model.fit(x_train_scaled, y_train)
    decision_values = (
        np.sum(x_test_scaled * model.coef_[0], axis=1) + model.intercept_[0]
    )
    probabilities = np.empty_like(decision_values)
    positive = decision_values >= 0
    probabilities[positive] = 1 / (1 + np.exp(-decision_values[positive]))
    negative_scores = np.exp(decision_values[~positive])
    probabilities[~positive] = negative_scores / (1 + negative_scores)
    rule_probabilities = np.clip(rule_test / 100, 1e-6, 1 - 1e-6)
    logistic_metrics = {
        "roc_auc": float(roc_auc_score(y_test, probabilities)),
        "log_loss": float(log_loss(y_test, probabilities)),
    }
    rule_metrics = {
        "roc_auc": float(roc_auc_score(y_test, rule_test)),
        "log_loss": float(log_loss(y_test, rule_probabilities)),
    }
    raw_coefficients = model.coef_[0] / scaler.scale_
    raw_intercept = model.intercept_[0] - np.dot(raw_coefficients, scaler.mean_)
    artifact: dict[str, object] = {
        "source": source,
        "seed": SEED,
        "passengers": passenger_count,
        "offers": offer_count,
        "labeled_rows": len(labels),
        "unlabeled_rows_ignored": unlabeled_rows,
        "training_rows": len(x_train),
        "test_rows": len(x_test),
        "features": list(FEATURES),
        "feature_units": {
            "detour_min": "minutes",
            "time_gap_min": "whole minutes",
            "pref_score": "points from 0 to 15",
            "price": "CAD",
        },
        "rule_score_definition": (
            "Application score components, 20-point preference penalty, "
            "clamping and one-decimal rounding; excludes search filtering "
            "and ranking tie-breakers. Feedback mode uses recorded rule_score."
        ),
        "evaluation_notes": {
            "split": "Stratified 70/30 row split, not a passenger-held-out split.",
            "rule_log_loss": (
                "Uses rule_score/100 as an uncalibrated probability proxy."
            ),
            "synthetic": (
                "Simulated distances [0,15) km; simulated speeds [20,70) km/h "
                "plus [0,5) minutes delay; available seats assumed. "
                "Includes zero-score examples. Labels are simulated from a "
                "logistic formula, not real passenger decisions. "
                "Synthetic metrics do not establish real-world superiority."
                if feedback_data is None
                else None
            ),
        },
        "coefficients": {
            name: float(value) for name, value in zip(FEATURES, raw_coefficients)
        },
        "intercept": float(raw_intercept),
        "metrics": {
            "logistic_regression": logistic_metrics,
            "rule_score": rule_metrics,
            # Keep the original synthetic artifact fields for compatibility.
            "roc_auc": logistic_metrics["roc_auc"],
            "log_loss": logistic_metrics["log_loss"],
        },
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(artifact, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return artifact


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).with_name("matching_model_coefficients.json"),
        help="Path for the learned coefficients and validation metrics.",
    )
    parser.add_argument(
        "--feedback-data",
        type=Path,
        help="Optional match_feedback CSV/JSON export; rows without accepted labels are skipped.",
    )
    args = parser.parse_args()
    artifact = train_and_export(args.output, feedback_data=args.feedback_data)
    metrics = artifact["metrics"]
    logistic = metrics["logistic_regression"]
    rules = metrics["rule_score"]
    print(
        "Evaluation on the same test split:\n"
        f"  Logistic regression  AUC={logistic['roc_auc']:.4f}  "
        f"log-loss={logistic['log_loss']:.4f}\n"
        f"  Rule score           AUC={rules['roc_auc']:.4f}  "
        f"log-loss={rules['log_loss']:.4f}\n"
        f"Coefficients and metrics: {args.output}"
    )


if __name__ == "__main__":
    main()
