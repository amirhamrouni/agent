extends RefCounted
class_name RoadGraph

var nodes: Array[Vector3] = []
var adjacency: Dictionary = {}

func load_from_processed_map(path: String) -> bool:
    nodes.clear()
    adjacency.clear()
    if not FileAccess.file_exists(path):
        return false
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return false
    var doc = JSON.parse_string(f.get_as_text())
    if typeof(doc) != TYPE_DICTIONARY:
        return false
    var meta = doc.get("meta", {})
    if typeof(meta) != TYPE_DICTIONARY or int(meta.get("schema_version", 0)) < 2:
        return false
    if str(meta.get("source", "")) != "OpenStreetMap" or str(meta.get("license", "")) != "ODbL-1.0":
        return false
    var graph = doc.get("road_graph", {})
    if typeof(graph) != TYPE_DICTIONARY:
        return false
    var raw_nodes = graph.get("nodes", [])
    var raw_edges = graph.get("edges", [])
    if typeof(raw_nodes) != TYPE_ARRAY or typeof(raw_edges) != TYPE_ARRAY:
        return false
    if int(meta.get("graph_node_count", -1)) != raw_nodes.size() or int(meta.get("graph_edge_count", -1)) != raw_edges.size():
        return false
    for p in raw_nodes:
        if typeof(p) != TYPE_ARRAY or p.size() < 2:
            return false
        var x := float(p[0])
        var z := float(p[1])
        if not is_finite(x) or not is_finite(z) or maxf(absf(x), absf(z)) > 2500.0:
            return false
        nodes.append(Vector3(x, 0.0, z))
    for i in range(nodes.size()):
        adjacency[i] = []
    for e in raw_edges:
        if e.size() < 2:
            continue
        var a := int(e[0])
        var b := int(e[1])
        if a == b or not adjacency.has(a) or not adjacency.has(b):
            nodes.clear()
            adjacency.clear()
            return false
        adjacency[a].append(b)
        adjacency[b].append(a)
    return nodes.size() > 1 and not raw_edges.is_empty()

func closest_node(pos: Vector3) -> int:
    if nodes.is_empty():
        return -1
    var best := 0
    var best_d := INF
    for i in range(nodes.size()):
        var d := pos.distance_squared_to(nodes[i])
        if d < best_d:
            best_d = d
            best = i
    return best

func random_walk(start: int, steps: int, rng: RandomNumberGenerator) -> Array[Vector3]:
    var route: Array[Vector3] = []
    if start < 0 or not adjacency.has(start):
        return route
    var current := start
    route.append(nodes[current])
    var previous := -1
    for _step in range(maxi(1, steps)):
        var options: Array = adjacency.get(current, [])
        if options.is_empty():
            break
        var candidates := options.duplicate()
        if previous >= 0 and candidates.size() > 1:
            candidates.erase(previous)
        var next_index := int(candidates[rng.randi_range(0, candidates.size()-1)])
        previous = current
        current = next_index
        route.append(nodes[current])
    return route
