#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "data/world/habib_bourguiba_osm.json"
PROVENANCE = ROOT / "data/world/habib_bourguiba_osm_provenance.json"
OUT = ROOT / "data/osm/tunis_bourguiba_processed.json"

EARTH_R = 6378137.0
ROAD_WIDTHS = {
    "motorway": 12.0,
    "trunk": 10.0,
    "primary": 9.0,
    "secondary": 8.0,
    "tertiary": 7.0,
    "residential": 6.0,
    "unclassified": 5.5,
    "service": 4.0,
    "living_street": 4.5,
    "pedestrian": 4.0,
}


def number(value, default=None):
    if value is None:
        return default
    text = str(value).strip().lower().replace("m", "")
    try:
        return float(text)
    except ValueError:
        return default


def project(lat: float, lon: float, lat0: float, lon0: float) -> list[float]:
    lat_r = math.radians(lat)
    lat0_r = math.radians(lat0)
    x = math.radians(lon - lon0) * EARTH_R * math.cos((lat_r + lat0_r) * 0.5)
    z = -math.radians(lat - lat0) * EARTH_R
    return [round(x, 3), round(z, 3)]


def road_width(tags: dict) -> float:
    explicit = number(tags.get("width"))
    if explicit and explicit > 0:
        return max(1.4, min(18.0, explicit))
    lanes = number(tags.get("lanes"))
    if lanes and lanes > 0:
        return max(2.8, min(18.0, lanes * 3.1))
    return ROAD_WIDTHS.get(tags.get("highway", ""), 4.0)


def building_height(tags: dict) -> float:
    explicit = number(tags.get("height"))
    if explicit and explicit > 0:
        return max(2.8, min(80.0, explicit))
    levels = number(tags.get("building:levels"))
    if levels and levels > 0:
        return max(2.8, min(80.0, levels * 3.1))
    return 9.0


def main() -> None:
    raw = RAW.read_bytes()
    source_sha = hashlib.sha256(raw).hexdigest()
    provenance = json.loads(PROVENANCE.read_text(encoding="utf-8"))
    if provenance.get("sha256") != source_sha:
        raise SystemExit("OSM_PROVENANCE_SHA_MISMATCH")

    doc = json.loads(raw)
    elements = doc.get("elements", [])
    nodes = {
        int(e["id"]): (float(e["lat"]), float(e["lon"]))
        for e in elements
        if e.get("type") == "node" and "lat" in e and "lon" in e
    }
    if len(nodes) < 20:
        raise SystemExit("OSM_NODE_SET_TOO_SMALL")

    bbox = provenance["bbox_wgs84"]
    lon0 = (float(bbox[0]) + float(bbox[2])) * 0.5
    lat0 = (float(bbox[1]) + float(bbox[3])) * 0.5

    buildings = []
    roads = []
    graph_node_ids: set[int] = set()
    graph_edges_ids: list[tuple[int, int]] = []

    for e in elements:
        if e.get("type") != "way":
            continue
        tags = e.get("tags", {}) or {}
        refs = [int(n) for n in e.get("nodes", []) if int(n) in nodes]
        if tags.get("building") and len(refs) >= 3:
            pts = [project(*nodes[n], lat0, lon0) for n in refs]
            buildings.append({
                "id": int(e["id"]),
                "points": pts,
                "height_m": round(building_height(tags), 2),
                "name": tags.get("name", ""),
                "source": "OpenStreetMap",
            })
        highway = tags.get("highway")
        if highway in ROAD_WIDTHS and len(refs) >= 2:
            pts = [project(*nodes[n], lat0, lon0) for n in refs]
            roads.append({
                "id": int(e["id"]),
                "points": pts,
                "width_m": round(road_width(tags), 2),
                "highway": highway,
                "name": tags.get("name", ""),
                "lanes": tags.get("lanes", ""),
                "source": "OpenStreetMap",
            })
            graph_node_ids.update(refs)
            for a, b in zip(refs, refs[1:]):
                if a != b:
                    graph_edges_ids.append((a, b))

    if len(buildings) < 10 or len(roads) < 5:
        raise SystemExit(f"OSM_PROCESSED_TOO_SMALL buildings={len(buildings)} roads={len(roads)}")

    ordered_ids = sorted(graph_node_ids)
    index = {node_id: i for i, node_id in enumerate(ordered_ids)}
    graph_nodes = [project(*nodes[node_id], lat0, lon0) for node_id in ordered_ids]
    graph_edges = [[index[a], index[b]] for a, b in graph_edges_ids if a in index and b in index]

    all_pts = [p for item in buildings for p in item["points"]] + [p for item in roads for p in item["points"]]
    min_x = min(p[0] for p in all_pts)
    max_x = max(p[0] for p in all_pts)
    min_z = min(p[1] for p in all_pts)
    max_z = max(p[1] for p in all_pts)

    processed = {
        "meta": {
            "schema_version": 2,
            "source": "OpenStreetMap",
            "license": "ODbL-1.0",
            "attribution": "© OpenStreetMap contributors",
            "projection": "local_equirectangular",
            "origin_wgs84": {"latitude": lat0, "longitude": lon0},
            "bbox_wgs84": bbox,
            "source_sha256": source_sha,
            "building_count": len(buildings),
            "road_count": len(roads),
            "graph_node_count": len(graph_nodes),
            "graph_edge_count": len(graph_edges),
            "content_bounds_m": {
                "min_x": round(min_x, 3), "max_x": round(max_x, 3),
                "min_z": round(min_z, 3), "max_z": round(max_z, 3),
            },
        },
        "buildings": buildings,
        "roads": roads,
        "road_graph": {"nodes": graph_nodes, "edges": graph_edges},
    }

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(processed, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")
    output_sha = hashlib.sha256(OUT.read_bytes()).hexdigest()
    print(
        f"OSM_PROCESS_PASS buildings={len(buildings)} roads={len(roads)} "
        f"graph_nodes={len(graph_nodes)} graph_edges={len(graph_edges)} sha256={output_sha}"
    )


if __name__ == "__main__":
    main()
