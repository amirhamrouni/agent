extends SceneTree

const PublicRealmPass = preload("res://scripts/world/art/TunisPublicRealmPass.gd")
const OsmLoader = preload("res://scripts/world/osm/OsmWorldLoader.gd")
const RoadGraphClass = preload("res://scripts/world/osm/RoadGraph.gd")
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

    var runtime_stats := _verify_real_map_runtime(reference)
    if runtime_stats.is_empty():
        quit(45)
        return

    var graph_stats := _verify_navigation_continuity(reference)
    if graph_stats.is_empty():
        quit(46)
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
    print("BOURGUIBA_OSM_RUNTIME_GATE_PASS buildings=%d roads=%d children=%d" % [
        int(runtime_stats["buildings"]), int(runtime_stats["roads"]), int(runtime_stats["children"])
    ])
    print("BOURGUIBA_NAVIGATION_GATE_PASS nodes=%d edges=%d largest_component=%d ratio=%.3f span_m=%.1f" % [
        int(graph_stats["nodes"]), int(graph_stats["edges"]), int(graph_stats["largest_component"]),
        float(graph_stats["largest_ratio"]), float(graph_stats["largest_span_m"])
    ])
    print("BOURGUIBA_BLOCKOUT_GATE_PASS generated=%d required_nodes=%d" % [scene.generated_count, required_nodes.size()])
    quit(0)

func _verify_real_map_runtime(reference: Dictionary) -> Dictionary:
    var snapshot: Dictionary = reference.get("snapshot", {})
    var processed_path := String(snapshot.get("processed_path", ""))
    var processed_counts: Dictionary = snapshot.get("processed_counts", {})
    var loader := OsmLoader.new()
    loader.processed_map_path = processed_path
    root.add_child(loader)
    if not loader.has_real_map():
        push_error("BOURGUIBA_OSM_RUNTIME_MAP_MISSING:%s" % processed_path)
        return {}
    if not loader.load_real_map() or not loader.loaded_real_map:
        push_error("BOURGUIBA_OSM_RUNTIME_LOAD_FAILED")
        return {}
    var expected_buildings := int(processed_counts.get("buildings", 0))
    var expected_roads := int(processed_counts.get("roads", 0))
    if loader.building_count != expected_buildings:
        push_error("BOURGUIBA_OSM_RUNTIME_BUILDING_COUNT_MISMATCH expected=%d actual=%d" % [expected_buildings, loader.building_count])
        return {}
    if loader.road_count != expected_roads:
        push_error("BOURGUIBA_OSM_RUNTIME_ROAD_COUNT_MISMATCH expected=%d actual=%d" % [expected_roads, loader.road_count])
        return {}
    var minimum_children := expected_buildings + expected_roads
    if loader.get_child_count() < minimum_children:
        push_error("BOURGUIBA_OSM_RUNTIME_GENERATED_CONTENT_INSUFFICIENT expected_min=%d actual=%d" % [minimum_children, loader.get_child_count()])
        return {}
    return {
        "buildings": loader.building_count,
        "roads": loader.road_count,
        "children": loader.get_child_count(),
    }

func _verify_navigation_continuity(reference: Dictionary) -> Dictionary:
    var snapshot: Dictionary = reference.get("snapshot", {})
    var processed_path := String(snapshot.get("processed_path", ""))
    var processed_counts: Dictionary = snapshot.get("processed_counts", {})
    var graph = RoadGraphClass.new()
    if not graph.load_from_processed_map(processed_path):
        push_error("BOURGUIBA_NAVIGATION_GRAPH_LOAD_FAILED")
        return {}
    var expected_nodes := int(processed_counts.get("graph_nodes", 0))
    var expected_edges := int(processed_counts.get("graph_edges", 0))
    if graph.nodes.size() != expected_nodes:
        push_error("BOURGUIBA_NAVIGATION_NODE_COUNT_MISMATCH expected=%d actual=%d" % [expected_nodes, graph.nodes.size()])
        return {}
    var edge_twice := 0
    for neighbors_variant in graph.adjacency.values():
        if not (neighbors_variant is Array):
            push_error("BOURGUIBA_NAVIGATION_ADJACENCY_INVALID")
            return {}
        edge_twice += (neighbors_variant as Array).size()
    var actual_edges := edge_twice / 2
    if actual_edges != expected_edges:
        push_error("BOURGUIBA_NAVIGATION_EDGE_COUNT_MISMATCH expected=%d actual=%d" % [expected_edges, actual_edges])
        return {}

    var visited := {}
    var largest: Array[int] = []
    for start in range(graph.nodes.size()):
        if visited.has(start):
            continue
        var component: Array[int] = []
        var queue: Array[int] = [start]
        visited[start] = true
        var cursor := 0
        while cursor < queue.size():
            var current := queue[cursor]
            cursor += 1
            component.append(current)
            var neighbors: Array = graph.adjacency.get(current, [])
            for next_variant in neighbors:
                var next_index := int(next_variant)
                if visited.has(next_index):
                    continue
                visited[next_index] = true
                queue.append(next_index)
        if component.size() > largest.size():
            largest = component

    if largest.is_empty():
        push_error("BOURGUIBA_NAVIGATION_NO_CONNECTED_COMPONENT")
        return {}
    var ratio := float(largest.size()) / float(graph.nodes.size())
    if ratio < 0.45:
        push_error("BOURGUIBA_NAVIGATION_FRAGMENTED largest=%d total=%d ratio=%.3f" % [largest.size(), graph.nodes.size(), ratio])
        return {}

    var min_x := INF
    var max_x := -INF
    var min_z := INF
    var max_z := -INF
    for index in largest:
        var pos: Vector3 = graph.nodes[index]
        min_x = minf(min_x, pos.x)
        max_x = maxf(max_x, pos.x)
        min_z = minf(min_z, pos.z)
        max_z = maxf(max_z, pos.z)
    var span := Vector2(max_x - min_x, max_z - min_z).length()
    if not is_finite(span) or span < 250.0:
        push_error("BOURGUIBA_NAVIGATION_SPAN_INSUFFICIENT:%.1f" % span)
        return {}

    var rng := RandomNumberGenerator.new()
    rng.seed = 20260914
    var route := graph.random_walk(largest[0], 24, rng)
    if route.size() < 8:
        push_error("BOURGUIBA_NAVIGATION_RANDOM_WALK_TOO_SHORT:%d" % route.size())
        return {}

    return {
        "nodes": graph.nodes.size(),
        "edges": actual_edges,
        "largest_component": largest.size(),
        "largest_ratio": ratio,
        "largest_span_m": span,
    }

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
