#!/usr/bin/env python3
"""Train a deterministic logistic-regression baseline on synthetic ride matches."""

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

SEED = 42
FEATURES = ("detour_min", "time_gap_min", "pref_score", "price")
LABEL = "accepted"
RULE_SCORE = "rule_score"


def build_synthetic_dataset(
    seed: int = SEED,
) -> tuple[np.ndarray, np.ndarray, int, int]:
    rng = np.random.default_rng(seed)
    passenger_count = 200
    offer_count = 2000

    passenger_preferences = rng.uniform(0.0, 1.0, passenger_count)
    passenger_time_windows = rng.uniform(0.0, 90.0, passenger_count)
    passenger_ids = np.repeat(np.arange(passenger_count), offer_count // passenger_count)

    detour = rng.gamma(shape=2.2, scale=7.0, size=offer_count).clip(0, 120)
    departure_gap = np.abs(
        rng.normal(passenger_time_windows[passenger_ids], 35.0, offer_count)
    ).clip(0, 240)
    preference = np.clip(
        passenger_preferences[passenger_ids] + rng.normal(0.0, 0.25, offer_count),
        0,
        1,
    )
    price = rng.uniform(5.0, 100.0, offer_count)

    features = np.column_stack((detour, departure_gap, preference, price))
    latent_acceptance = (
        1.6
        - 0.045 * detour
        - 0.016 * departure_gap
        + 2.2 * preference
        - 0.018 * price
        + rng.normal(0.0, 0.8, offer_count)
    )
    probabilities = 1.0 / (1.0 + np.exp(-latent_acceptance))
    labels = rng.binomial(1, probabilities)
    return features, labels, passenger_count, offer_count


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


def _synthetic_rule_scores(features: np.ndarray) -> np.ndarray:
    detour, time_gap, preference, _price = features.T
    geographic = 50 * np.clip(1 - detour / 45, 0, 1)
    temporal = 35 * np.clip(1 - np.maximum(0, time_gap - 10) / 50, 0, 1)
    return np.clip(geographic + temporal + preference * 15, 0, 100)


def train_and_export(
    output_path: Path,
    feedback_data: Path | None = None,
) -> dict[str, object]:
    if feedback_data is None:
        features, labels, passenger_count, offer_count = build_synthetic_dataset()
        rule_scores = _synthetic_rule_scores(features)
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
        "training_rows": int(len(x_train)),
        "test_rows": int(len(x_test)),
        "features": list(FEATURES),
        "coefficients": {
            name: float(value)
            for name, value in zip(FEATURES, raw_coefficients)
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
