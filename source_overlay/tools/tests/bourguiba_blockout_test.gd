extends SceneTree

const PublicRealmPass = preload("res://scripts/world/art/TunisPublicRealmPass.gd")
const REFERENCE_PATH := "res://data/world/habib_bourguiba_reference.json"

func _initialize() -> void:
    var reference := _load_reference_manifest()
    if reference.is_empty():
        quit(40)
        return

    var scene := PublicRealmPass.new()
    root.add_child(scene)
    scene.build()

    var required_nodes := [
        "BourguibaRoadSurface",
        "BourguibaSidewalks",
        "BourguibaLaneMarkings",
        "BourguibaCrosswalks",
        "BourguibaRedWhiteCurbs",
        "BourguibaCenterMedian",
        "BourguibaTreeGrates",
        "BourguibaStreetDrainage",
        "BourguibaBenches",
        "BourguibaBollards",
        "BourguibaPlanters",
        "BourguibaStreetLamps",
    ]

    for node_name in required_nodes:
        if scene.get_node_or_null(NodePath(node_name)) == null:
            push_error("BOURGUIBA_BLOCKOUT_MISSING_NODE:%s" % node_name)
            quit(41)
            return

    if scene.generated_count < 250:
        push_error("BOURGUIBA_BLOCKOUT_INSUFFICIENT_GEOMETRY:%d" % scene.generated_count)
        quit(42)
        return

    var road := scene.get_node("BourguibaRoadSurface") as Node3D
    var sidewalks := scene.get_node("BourguibaSidewalks") as Node3D
    var crossings := scene.get_node("BourguibaCrosswalks") as Node3D
    if road.get_child_count() < 1 or sidewalks.get_child_count() < 2 or crossings.get_child_count() < 20:
        push_error("BOURGUIBA_BLOCKOUT_GEOMETRY_CONTRACT_FAILED")
        quit(43)
        return

    var snapshot: Dictionary = reference.get("snapshot", {})
    var processed_counts: Dictionary = snapshot.get("processed_counts", {})
    print("BOURGUIBA_REFERENCE_GATE_PASS controls=%d scope=%s schema=%d buildings=%d roads=%d graph_nodes=%d graph_edges=%d" % [
        reference["control_points"].size(),
        reference["scope_id"],
        int(reference["schema_version"]),
        int(processed_counts.get("buildings", 0)),
        int(processed_counts.get("roads", 0)),
        int(processed_counts.get("graph_nodes", 0)),
        int(processed_counts.get("graph_edges", 0)),
    ])
    print("BOURGUIBA_BLOCKOUT_GATE_PASS generated=%d required_nodes=%d" % [scene.generated_count, required_nodes.size()])
    quit(0)

func _load_reference_manifest() -> Dictionary:
    if not FileAccess.file_exists(REFERENCE_PATH):
        push_error("BOURGUIBA_REFERENCE_MISSING:%s" % REFERENCE_PATH)
        return {}
    var file := FileAccess.open(REFERENCE_PATH, FileAccess.READ)
    if file == null:
        push_error("BOURGUIBA_REFERENCE_OPEN_FAILED")
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        push_error("BOURGUIBA_REFERENCE_INVALID_JSON")
        return {}
    var reference: Dictionary = parsed
    var schema_version := int(reference.get("schema_version", 0))
    if schema_version != 2:
        push_error("BOURGUIBA_REFERENCE_SCHEMA_INVALID:%d" % schema_version)
        return {}
    if String(reference.get("status", "")) != "bounded_osm_snapshot_installed":
        push_error("BOURGUIBA_REFERENCE_STATUS_INVALID")
        return {}
    if String(reference.get("coordinate_system", "")) != "WGS84":
        push_error("BOURGUIBA_REFERENCE_COORDINATE_SYSTEM_INVALID")
        return {}
    var license: Dictionary = reference.get("license", {})
    if String(license.get("osm_data", "")) != "ODbL-1.0" or String(license.get("attribution", "")) == "":
        push_error("BOURGUIBA_REFERENCE_LICENSE_INVALID")
        return {}

    var snapshot: Dictionary = reference.get("snapshot", {})
    if snapshot.is_empty():
        push_error("BOURGUIBA_REFERENCE_SNAPSHOT_MISSING")
        return {}
    if String(snapshot.get("projection", "")) != "local_equirectangular":
        push_error("BOURGUIBA_REFERENCE_PROJECTION_INVALID")
        return {}
    var raw_path := String(snapshot.get("raw_path", ""))
    var processed_path := String(snapshot.get("processed_path", ""))
    if raw_path == "" or not FileAccess.file_exists(raw_path):
        push_error("BOURGUIBA_REFERENCE_RAW_SNAPSHOT_MISSING:%s" % raw_path)
        return {}
    if processed_path == "" or not FileAccess.file_exists(processed_path):
        push_error("BOURGUIBA_REFERENCE_PROCESSED_SNAPSHOT_MISSING:%s" % processed_path)
        return {}
    if String(snapshot.get("raw_sha256", "")).length() != 64 or String(snapshot.get("processed_sha256", "")).length() != 64:
        push_error("BOURGUIBA_REFERENCE_SHA_INVALID")
        return {}
    var processed_counts: Dictionary = snapshot.get("processed_counts", {})
    if int(processed_counts.get("buildings", 0)) < 100 or int(processed_counts.get("roads", 0)) < 100:
        push_error("BOURGUIBA_REFERENCE_PROCESSED_COUNTS_INVALID")
        return {}
    if int(processed_counts.get("graph_nodes", 0)) < 500 or int(processed_counts.get("graph_edges", 0)) < 500:
        push_error("BOURGUIBA_REFERENCE_GRAPH_COUNTS_INVALID")
        return {}

    var controls: Array = reference.get("control_points", [])
    if controls.size() < 3:
        push_error("BOURGUIBA_REFERENCE_CONTROL_POINTS_INSUFFICIENT:%d" % controls.size())
        return {}
    var expected := {
        "cathedral_st_vincent_de_paul": ["way", 100080986],
        "theatre_municipal": ["way", 95130030],
        "clock_tower": ["node", 5533914655],
    }
    for control_variant in controls:
        if not (control_variant is Dictionary):
            push_error("BOURGUIBA_REFERENCE_CONTROL_INVALID")
            return {}
        var control: Dictionary = control_variant
        var control_id := String(control.get("id", ""))
        if not expected.has(control_id):
            continue
        var contract: Array = expected[control_id]
        if String(control.get("osm_type", "")) != String(contract[0]) or int(control.get("osm_id", 0)) != int(contract[1]):
            push_error("BOURGUIBA_REFERENCE_OSM_ID_MISMATCH:%s" % control_id)
            return {}
        var lat := float(control.get("latitude", 0.0))
        var lon := float(control.get("longitude", 0.0))
        if lat < 36.79 or lat > 36.81 or lon < 10.17 or lon > 10.20:
            push_error("BOURGUIBA_REFERENCE_OUT_OF_SCOPE:%s" % control_id)
            return {}
        if String(control.get("canonical_osm_url", "")) == "" or String(control.get("evidence_url", "")) == "":
            push_error("BOURGUIBA_REFERENCE_PROVENANCE_MISSING:%s" % control_id)
            return {}
    return reference
