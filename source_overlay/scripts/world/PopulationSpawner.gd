extends Node3D
class_name PopulationSpawner

const SIDEWALK_GRAPH_SCRIPT := preload("res://scripts/world/navigation/SidewalkGraph.gd")
const MAX_PEDESTRIANS := 36
const MAX_TRAFFIC := 12
const QUALITY_BUDGETS := {
    "LOW": {"pedestrians": 12, "traffic": 4},
    "MEDIUM": {"pedestrians": 24, "traffic": 8},
    "HIGH": {"pedestrians": 36, "traffic": 12},
    "AUTO": {"pedestrians": 24, "traffic": 8}
}
const PEDESTRIAN_VARIANTS := ["commuter", "casual", "shopper", "elder", "student"]

# The production Bourguiba hero reconstruction lives in this stable local frame.
# Reusing the existing population budget inside this corridor makes the real OSM
# slice read as inhabited without increasing mobile entity caps.
const HERO_ORIGIN := Vector3(-130.0, 0.0, 30.0)
const HERO_YAW := 0.119428926
const HERO_X_MIN := -96.0
const HERO_X_MAX := 98.0
const HERO_SIDEWALK_Z := 23.2
const HERO_MEDIAN_Z := 5.2
const HERO_TRAFFIC_Z := 14.7

@export var pedestrian_count := 24
@export var traffic_count := 10

var road_graph = null
var sidewalk_graph = null
var traffic_coordinator = null
var current_quality_tier := "AUTO"
var pedestrian_palette: Array[Color] = [
    Color("#2d3136"), Color("#6c4f3c"), Color("#6d6f62"),
    Color("#1f3951"), Color("#7a6147")
]

func _ready() -> void:
    add_to_group("population_spawner")

func configure_road_graph(graph) -> void:
    road_graph = graph
    sidewalk_graph = SIDEWALK_GRAPH_SCRIPT.new()
    sidewalk_graph.build_from_road_graph(graph)

func configure_traffic_coordinator(value) -> void:
    traffic_coordinator = value

func spawn_all() -> void:
    pedestrian_count = clampi(pedestrian_count, 0, MAX_PEDESTRIANS)
    traffic_count = clampi(traffic_count, 0, MAX_TRAFFIC)
    _spawn_pedestrians()
    _spawn_traffic()
    # The raw OSM graph spans a much wider capture than the 240 m hero slice.
    # Keep exactly the same population counts, but stage the already-created
    # agents on Bourguiba's visible sidewalks/lanes so gameplay cameras do not
    # see an empty city while agents wander outside the hero corridor.
    if road_graph != null:
        _focus_bourguiba_hero_corridor()
    apply_quality_tier(current_quality_tier)

func population_budget_for_tier(tier: String) -> Dictionary:
    var normalized := tier.to_upper()
    if not QUALITY_BUDGETS.has(normalized):
        normalized = "AUTO"
    return Dictionary(QUALITY_BUDGETS[normalized]).duplicate(true)

func apply_quality_tier(tier: String) -> Dictionary:
    var normalized := tier.to_upper()
    if not QUALITY_BUDGETS.has(normalized):
        normalized = "AUTO"
    current_quality_tier = normalized
    var budget := population_budget_for_tier(normalized)
    var pedestrian_budget := mini(int(budget.get("pedestrians", 0)), MAX_PEDESTRIANS)
    var traffic_budget := mini(int(budget.get("traffic", 0)), MAX_TRAFFIC)
    apply_population_budget(pedestrian_budget, traffic_budget)
    return {
        "tier": current_quality_tier,
        "pedestrians": pedestrian_budget,
        "traffic": traffic_budget
    }

func _spawn_pedestrians() -> void:
    for i in range(pedestrian_count):
        var p := PedestrianAgent.new()
        p.name = "Pedestrian_%02d" % i
        p.walk_speed = 1.65 + float(i % 5) * 0.18
        p.add_to_group("hayat_pedestrian")
        p.position = Vector3(-80 + (i%9)*20, 1.0, -88 + (i/9)*176)
        p.set_meta("streetlife_variant", PEDESTRIAN_VARIANTS[i % PEDESTRIAN_VARIANTS.size()])
        p.set_meta("streetlife_variant_index", i % PEDESTRIAN_VARIANTS.size())
        add_child(p)
        if sidewalk_graph != null and not sidewalk_graph.nodes.is_empty():
            var start = sidewalk_graph.closest_node(p.position)
            var route = sidewalk_graph.random_walk(start, 8 + (i % 7), p.rng)
            if route.size() > 1:
                p.position = route[0] + Vector3(0, 1.0, 0)
                p.set_route(route)
        elif road_graph != null and not road_graph.nodes.is_empty():
            var road_start = road_graph.closest_node(p.position)
            var fallback_route = road_graph.random_walk(road_start, 8 + (i % 7), p.rng)
            if fallback_route.size() > 1:
                p.position = fallback_route[0] + Vector3(0, 1.0, 0)
                p.set_route(fallback_route)
        var col := CollisionShape3D.new()
        var cap := CapsuleShape3D.new()
        cap.radius = 0.32
        cap.height = 1.5
        col.shape = cap
        col.position.y = 0.75
        p.add_child(col)
        var body := PlayerVisualFactory.build()
        body.name = "CitizenVisual"
        body.scale = Vector3(0.94, 0.94, 0.94)
        p.add_child(body)
        _decorate_pedestrian_variant(p, i % PEDESTRIAN_VARIANTS.size())
        if traffic_coordinator != null:
            p.configure_traffic_coordinator(traffic_coordinator)

func _decorate_pedestrian_variant(parent: Node3D, variant_index: int) -> void:
    var accent: Color = pedestrian_palette[variant_index % pedestrian_palette.size()]
    match variant_index:
        0:
            _variant_box(parent, "WorkBag", Vector3(0.42, 1.02, 0.05), Vector3(0.28, 0.34, 0.16), accent)
        1:
            _variant_box(parent, "CapBrim", Vector3(0.0, 2.04, -0.16), Vector3(0.42, 0.08, 0.26), accent)
        2:
            _variant_box(parent, "ShoppingBag", Vector3(-0.42, 0.88, 0.04), Vector3(0.30, 0.40, 0.18), accent)
        3:
            var cane := _variant_box(parent, "WalkingCane", Vector3(0.43, 0.62, 0.02), Vector3(0.055, 1.05, 0.055), Color("#725438"))
            cane.rotation.z = 0.08
        4:
            _variant_box(parent, "Backpack", Vector3(0.0, 1.25, 0.27), Vector3(0.48, 0.55, 0.22), accent)

func _variant_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = pos
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.84
    mesh_instance.material_override = material
    parent.add_child(mesh_instance)
    return mesh_instance

func _spawn_traffic() -> void:
    var routes := [
        [Vector3(-95,0.7,-55),Vector3(95,0.7,-55),Vector3(95,0.7,-45),Vector3(-95,0.7,-45)],
        [Vector3(95,0.7,55),Vector3(-95,0.7,55),Vector3(-95,0.7,45),Vector3(95,0.7,45)],
        [Vector3(-55,0.7,-95),Vector3(-55,0.7,95),Vector3(-45,0.7,95),Vector3(-45,0.7,-95)],
        [Vector3(55,0.7,95),Vector3(55,0.7,-95),Vector3(45,0.7,-95),Vector3(45,0.7,95)]
    ]
    for i in range(traffic_count):
        var car := TrafficVehicle.new()
        car.name = "Traffic_%02d" % i
        car.acceleration = 6.5 + float(i % 4) * 0.75
        car.add_to_group("hayat_traffic")
        var route: Array[Vector3] = []
        for point in routes[i % routes.size()]:
            route.append(Vector3(point))
        if road_graph != null and not road_graph.nodes.is_empty():
            var start = road_graph.closest_node(route[0])
            var graph_route = road_graph.random_walk(start, 12 + (i % 9), RandomNumberGenerator.new())
            if graph_route.size() > 2:
                route.clear()
                for point in graph_route:
                    route.append(Vector3(point))
        car.lane_points = route
        car.position = route[i % route.size()]
        car.cruise_speed = 7.0 + (i % 3) * 1.4
        add_child(car)
        if traffic_coordinator != null:
            car.configure_coordinator(traffic_coordinator)
        var col := CollisionShape3D.new()
        var sh := BoxShape3D.new()
        sh.size = Vector3(1.8,1.2,4.1)
        col.shape = sh
        col.position.y = 0.6
        car.add_child(col)
        var vehicle_ids := ["taxi_01", "louage_01", "pickup_01", "pickup_404"]
        var vehicle_id: String = vehicle_ids[i % vehicle_ids.size()]
        car.set_meta("traffic_visual_id", vehicle_id)
        var body := VehicleVisualFactory.build(vehicle_id)
        body.name = "TrafficVisual"
        body.scale = Vector3(0.96, 0.96, 0.96)
        car.add_child(body)

func _hero_transform() -> Transform3D:
    return Transform3D(Basis(Vector3.UP, HERO_YAW), HERO_ORIGIN)

func _hero_point(local_point: Vector3) -> Vector3:
    return _hero_transform() * local_point

func _focus_bourguiba_hero_corridor() -> void:
    var peds := get_tree().get_nodes_in_group("hayat_pedestrian")
    var pedestrian_lanes := [HERO_SIDEWALK_Z, -HERO_SIDEWALK_Z, HERO_MEDIAN_Z, -HERO_MEDIAN_Z]
    for i in range(peds.size()):
        var ped = peds[i]
        if not (ped is Node3D):
            continue
        var lane_index := i % pedestrian_lanes.size()
        var direction := 1.0 if lane_index == 0 or lane_index == 2 else -1.0
        var span := HERO_X_MAX - HERO_X_MIN
        var start_x := HERO_X_MIN + fmod(float(i * 19 + lane_index * 7), span)
        var end_x := clampf(start_x + direction * (42.0 + float(i % 4) * 6.0), HERO_X_MIN, HERO_X_MAX)
        if abs(end_x - start_x) < 16.0:
            end_x = clampf(start_x - direction * 52.0, HERO_X_MIN, HERO_X_MAX)
        var local_z: float = pedestrian_lanes[lane_index]
        var route: Array[Vector3] = []
        for step in range(6):
            var t := float(step) / 5.0
            var lx := lerpf(start_x, end_x, t)
            route.append(_hero_point(Vector3(lx, 0.0, local_z)))
        (ped as Node3D).position = route[0] + Vector3(0.0, 1.0, 0.0)
        if ped.has_method("set_route"):
            ped.set_route(route)
        (ped as Node3D).rotation.y = HERO_YAW + (PI * 0.5 if direction > 0.0 else -PI * 0.5)
        ped.set_meta("hero_corridor_focused", true)

    var cars := get_tree().get_nodes_in_group("hayat_traffic")
    for i in range(cars.size()):
        var car = cars[i]
        if not (car is Node3D):
            continue
        var side := -1.0 if i % 2 == 0 else 1.0
        var direction := 1.0 if side < 0.0 else -1.0
        var lane_z := side * HERO_TRAFFIC_Z
        var start_x := -88.0 + fmod(float(i * 27), 176.0)
        if direction < 0.0:
            start_x = -start_x
        var lane_route: Array[Vector3] = [
            _hero_point(Vector3(HERO_X_MIN, 0.70, lane_z)),
            _hero_point(Vector3(HERO_X_MAX, 0.70, lane_z)),
            _hero_point(Vector3(HERO_X_MAX, 0.70, lane_z + side * 3.2)),
            _hero_point(Vector3(HERO_X_MIN, 0.70, lane_z + side * 3.2))
        ]
        if direction < 0.0:
            lane_route.reverse()
        if "lane_points" in car:
            car.lane_points = lane_route
        (car as Node3D).position = _hero_point(Vector3(start_x, 0.70, lane_z))
        (car as Node3D).rotation.y = HERO_YAW + (PI * 0.5 if direction > 0.0 else -PI * 0.5)
        car.set_meta("hero_corridor_focused", true)

func apply_population_budget(pedestrian_budget: int, traffic_budget: int) -> void:
    pedestrian_budget = clampi(pedestrian_budget, 0, MAX_PEDESTRIANS)
    traffic_budget = clampi(traffic_budget, 0, MAX_TRAFFIC)
    var peds := get_tree().get_nodes_in_group("hayat_pedestrian")
    for i in range(peds.size()):
        var node: Node = peds[i]
        var active := i < pedestrian_budget
        node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
        if node is Node3D:
            (node as Node3D).visible = active

    var cars := get_tree().get_nodes_in_group("hayat_traffic")
    for i in range(cars.size()):
        var node: Node = cars[i]
        var active := i < traffic_budget
        node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
        if node is Node3D:
            (node as Node3D).visible = active
