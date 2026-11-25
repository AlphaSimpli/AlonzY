#!/usr/bin/env python3
"""Measure OSRM table latency and compare detours in Gatineau–Ottawa.

The measured interval includes batching, HTTP, JSON parsing, and detour
calculation; it does not include Supabase candidate search or Flutter rendering.
"""

from __future__ import annotations

import concurrent.futures
import json
import math
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

PICKUP = (45.4242, -75.6950)
DROPOFF = (45.4765, -75.7013)
MAX_CANDIDATES = 100
MAX_COORDINATES = 50
CANDIDATES_PER_BATCH = (MAX_COORDINATES - 2) // 2
TARGET_MS = 1500
TIMEOUT_SECONDS = 12

# (label, origin latitude, origin longitude, destination latitude, longitude)
SAMPLES = (
    ("Centre Ottawa–Hull", 45.4215, -75.6972, 45.4765, -75.7013),
    ("Kanata–Hull", 45.3125, -75.9217, 45.4765, -75.7013),
    ("Orléans–Aylmer", 45.4800, -75.5140, 45.3970, -75.8430),
    ("Nepean–Gatineau", 45.3310, -75.7610, 45.4765, -75.7013),
    ("Barrhaven–Hull", 45.2710, -75.7400, 45.4765, -75.7013),
    ("Hull–Ottawa Est", 45.4765, -75.7013, 45.4320, -75.6200),
    ("Aylmer–Centre Ottawa", 45.3970, -75.8430, 45.4215, -75.6972),
    ("Chelsea–Ottawa Ouest", 45.5020, -75.7820, 45.3630, -75.7580),
    ("Gatineau Est–Ottawa", 45.4820, -75.6300, 45.4215, -75.6972),
    ("Ottawa Sud–Gatineau", 45.3500, -75.6650, 45.4765, -75.7013),
)


def haversine_km(start: tuple[float, float], end: tuple[float, float]) -> float:
    radius_km = 6371.0088
    lat1, lng1 = map(math.radians, start)
    lat2, lng2 = map(math.radians, end)
    dlat = lat2 - lat1
    dlng = lng2 - lng1
    hav = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1) * math.cos(lat2) * math.sin(dlng / 2) ** 2
    )
    return radius_km * 2 * math.atan2(math.sqrt(hav), math.sqrt(1 - hav))


def haversine_detour_km(sample: tuple) -> float:
    _, origin_lat, origin_lng, destination_lat, destination_lng = sample
    origin = (origin_lat, origin_lng)
    destination = (destination_lat, destination_lng)
    shared = (
        haversine_km(origin, PICKUP)
        + haversine_km(PICKUP, DROPOFF)
        + haversine_km(DROPOFF, destination)
    )
    return max(0.0, shared - haversine_km(origin, destination))


def query_batch(base_url: str, candidates: list[tuple]) -> list[dict]:
    count = len(candidates)
    points = (
        [(ride[1], ride[2]) for ride in candidates]
        + [PICKUP, DROPOFF]
        + [(ride[3], ride[4]) for ride in candidates]
    )
    coordinates = ";".join(f"{lng},{lat}" for lat, lng in points)
    sources = ";".join(str(index) for index in range(count + 2))
    destinations = ";".join(
        str(index) for index in (count, count + 1, *range(count + 2, 2 * count + 2))
    )
    query = (
        f"annotations=duration,distance&sources={sources}&destinations={destinations}"
    )
    url = f"{base_url.rstrip('/')}/table/v1/driving/{coordinates}?{query}"
    try:
        response = subprocess.run(
            [
                "curl",
                "--fail",
                "--silent",
                "--show-error",
                "--max-time",
                str(TIMEOUT_SECONDS),
                "--header",
                "Accept: application/json",
                "--user-agent",
                "AlonzY-OSRM-benchmark/1.0",
                url,
            ],
            capture_output=True,
            check=True,
            text=True,
        )
    except subprocess.CalledProcessError as error:
        raise RuntimeError(error.stderr.strip() or "curl request failed") from error
    payload = json.loads(response.stdout)
    if payload.get("code") != "Ok":
        raise RuntimeError(f"OSRM returned {payload.get('code', 'invalid response')}")

    durations = payload.get("durations")
    distances = payload.get("distances")
    expected_size = count + 2
    if (
        not isinstance(durations, list)
        or not isinstance(distances, list)
        or len(durations) != expected_size
        or len(distances) != expected_size
        or any(len(row) != expected_size for row in durations + distances)
    ):
        raise RuntimeError("OSRM returned an invalid matrix shape")

    results = []
    for index, ride in enumerate(candidates):
        destination_index = index + 2
        cells = (
            durations[index][destination_index],
            durations[index][0],
            durations[count][1],
            durations[count + 1][destination_index],
            distances[index][destination_index],
            distances[index][0],
            distances[count][1],
            distances[count + 1][destination_index],
        )
        if any(value is None for value in cells):
            continue
        (
            direct_seconds,
            origin_to_pickup_seconds,
            pickup_to_dropoff_seconds,
            dropoff_to_destination_seconds,
            direct_meters,
            origin_to_pickup_meters,
            pickup_to_dropoff_meters,
            dropoff_to_destination_meters,
        ) = cells
        results.append(
            {
                "sample": ride[0],
                "extra_duration_min": max(
                    0.0,
                    (
                        origin_to_pickup_seconds
                        + pickup_to_dropoff_seconds
                        + dropoff_to_destination_seconds
                        - direct_seconds
                    )
                    / 60,
                ),
                "extra_distance_km": max(
                    0.0,
                    (
                        origin_to_pickup_meters
                        + pickup_to_dropoff_meters
                        + dropoff_to_destination_meters
                        - direct_meters
                    )
                    / 1000,
                ),
            }
        )
    return results


def benchmark(base_url: str, candidate_count: int) -> tuple[dict, list[dict]]:
    candidates = [SAMPLES[index % len(SAMPLES)] for index in range(candidate_count)]
    batches = [
        candidates[index : index + CANDIDATES_PER_BATCH]
        for index in range(0, candidate_count, CANDIDATES_PER_BATCH)
    ]
    started = time.perf_counter()
    routes: list[dict] = []
    error = None
    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            futures = [
                executor.submit(query_batch, base_url, batch) for batch in batches
            ]
            for future in futures:
                routes.extend(future.result())
    except (OSError, TimeoutError, ValueError, RuntimeError) as exception:
        error = str(exception)
    elapsed_ms = round((time.perf_counter() - started) * 1000, 2)
    scenario = {
        "candidate_count": candidate_count,
        "elapsed_ms": elapsed_ms,
        "osrm_requests": len(batches),
        "returned_routes": len(routes),
        "target_ms": TARGET_MS,
        "meets_target": error is None and elapsed_ms < TARGET_MS,
        "status": "ok" if error is None else "error",
    }
    if error is not None:
        scenario["error"] = error
    return scenario, routes


def main() -> int:
    base_url = os.environ.get(
        "OSRM_BASE_URL", "https://router.project-osrm.org"
    ).rstrip("/")
    output_path = Path(
        os.environ.get("OSRM_BENCHMARK_OUTPUT", "docs/benchmarks_osrm.json")
    )
    scenarios = []
    ten_offer_routes = []
    for count in (10, 50, 100):
        scenario, routes = benchmark(base_url, count)
        scenarios.append(scenario)
        if count == 10:
            ten_offer_routes = routes
        print(
            f"{count} offers: {scenario['elapsed_ms']} ms "
            f"({scenario['osrm_requests']} OSRM requests, {scenario['status']})"
        )

    comparisons = []
    samples_by_name = {sample[0]: sample for sample in SAMPLES}
    for route in ten_offer_routes:
        sample = samples_by_name[route["sample"]]
        haversine_km = haversine_detour_km(sample)
        osrm_km = route["extra_distance_km"]
        comparisons.append(
            {
                "route": sample[0],
                "haversine_detour_km": round(haversine_km, 3),
                "osrm_detour_km": round(osrm_km, 3),
                "absolute_difference_km": round(abs(osrm_km - haversine_km), 3),
                "osrm_extra_duration_min": round(route["extra_duration_min"], 2),
            }
        )

    complete = (
        len(scenarios) == 3
        and all(scenario["status"] == "ok" for scenario in scenarios)
        and len(comparisons) == len(SAMPLES)
    )
    report = {
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "osrm_base_url": base_url,
        "measurement_scope": (
            "OSRM matrix request, batching, response parsing, and detour calculation; "
            "excludes Supabase candidate search and Flutter rendering"
        ),
        "sample_kind": "fixed synthetic candidate routes in the Gatineau–Ottawa area",
        "passenger_pickup": {"lat": PICKUP[0], "lng": PICKUP[1]},
        "passenger_dropoff": {"lat": DROPOFF[0], "lng": DROPOFF[1]},
        "batch_coordinate_limit": MAX_COORDINATES,
        "candidates_per_batch": CANDIDATES_PER_BATCH,
        "target_ms": TARGET_MS,
        "scenarios": scenarios,
        "detour_comparison": comparisons,
        "status": "complete" if complete else "incomplete",
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"{len(comparisons)} route detours compared; results: {output_path}")
    return 0 if complete else 1


if __name__ == "__main__":
    sys.exit(main())
