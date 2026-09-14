extends RefCounted
class_name SidewalkGraph

var nodes: Array[Vector3] = []
var adjacency: Dictionary = {}

var _node_lookup: Dictionary = {}
var _edge_seen: Dictionary = {}

func build_from_road_graph(road_graph, offset_m: float = 3.2) -> bool:
    nodes.clear()
    adjacency.clear()
    _node_lookup.clear()
    _edge_seen.clear()

    if road_graph == null:
        return false
    if road_graph.nodes.size() < 2:
        return false

    for a in range(road_graph.nodes.size()):
        for b_any in road_graph.adjacency.get(a, []):
            var b := int(b_any)
            if b <= a:
                continue

            var pa: Vector3 = road_graph.nodes[a]
            var pb: Vector3 = road_graph.nodes[b]
            var direction := pb - pa
            direction.y = 0.0

            if direction.length() < 0.5:
                continue

            direction = direction.normalized()
            var normal := Vector3(-direction.z, 0.0, direction.x) * offset_m

            var left_a := _get_or_add_node(pa + normal)
            var left_b := _get_or_add_node(pb + normal)
            var right_a := _get_or_add_node(pa - normal)
            var right_b := _get_or_add_node(pb - normal)

            _add_edge(left_a, left_b)
            _add_edge(right_a, right_b)

    for i in range(nodes.size()):
        for j in range(i + 1, nodes.size()):
            if nodes[i].distance_to(nodes[j]) <= offset_m * 2.25:
                _add_edge(i, j)

    return nodes.size() > 1

func _get_or_add_node(position: Vector3) -> int:
    var key := Vector2i(roundi(position.x * 10.0), roundi(position.z * 10.0))
    if _node_lookup.has(key):
        return int(_node_lookup[key])
    var index := nodes.size()
    _node_lookup[key] = index
    nodes.append(position)
    adjacency[index] = []
    return index

func _add_edge(a: int, b: int) -> void:
    if a == b:
        return
    var key := Vector2i(mini(a, b), maxi(a, b))
    if _edge_seen.has(key):
        return
    _edge_seen[key] = true
    adjacency[a].append(b)
    adjacency[b].append(a)

func closest_node(position: Vector3) -> int:
    if nodes.is_empty():
        return -1
    var best := 0
    var best_distance := INF
    for i in range(nodes.size()):
        var distance := position.distance_squared_to(nodes[i])
        if distance < best_distance:
            best_distance = distance
            best = i
    return best

func random_walk(start: int, steps: int, rng: RandomNumberGenerator) -> Array[Vector3]:
    var route: Array[Vector3] = []
    if start < 0 or not adjacency.has(start):
        return route
    var current := start
    var previous := -1
    route.append(nodes[current])
    for _step in range(maxi(1, steps)):
        var options: Array = adjacency.get(current, [])
        if options.is_empty():
            break
        var candidates: Array = options.duplicate()
        if previous >= 0 and candidates.size() > 1:
            candidates.erase(previous)
        var next_index := int(candidates[rng.randi_range(0, candidates.size() - 1)])
        previous = current
        current = next_index
        route.append(nodes[current])
    return route
