"""Score a regles equivalent au calcul de MatchingService."""

import math
from decimal import Decimal, ROUND_HALF_UP


def calculate_rule_score(
    *,
    detour_km: float,
    time_gap_min: float,
    pref_score: float,
    has_preference_mismatch: bool = False,
    available_seats: int = 1,
) -> float:
    """pref_score vaut de 0 a 15; le detour est en kilometres."""
    if available_seats < 1:
        return 0.0

    for name, value in (
        ("detour_km", detour_km),
        ("time_gap_min", time_gap_min),
        ("pref_score", pref_score),
    ):
        if not math.isfinite(value) or value < 0:
            raise ValueError(f"{name} doit etre fini et positif ou nul.")
    if pref_score > 15:
        raise ValueError("pref_score doit etre compris entre 0 et 15.")

    geographic = (
        50.0 * (1.0 - detour_km / 15.0) if detour_km <= 15.0 else 0.0
    )
    minutes = int(time_gap_min)
    if minutes <= 10:
        temporal = 35.0
    elif minutes >= 60:
        temporal = 0.0
    else:
        temporal = 35.0 * (1.0 - (minutes - 10) / 50.0)

    total = geographic + temporal + pref_score
    if has_preference_mismatch:
        total -= 20.0
    total = max(0.0, min(100.0, total))

    # Comme toStringAsFixed(1), arrondir a une decimale.
    return float(
        Decimal.from_float(total).quantize(
            Decimal("0.1"), rounding=ROUND_HALF_UP
        )
    )