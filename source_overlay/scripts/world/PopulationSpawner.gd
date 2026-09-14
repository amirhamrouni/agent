extends Node3D
class_name PopulationSpawner

const SIDEWALK_GRAPH_SCRIPT := preload("res://scripts/world/navigation/SidewalkGraph.gd")

@export var pedestrian_count := 24
@export var traffic_count := 10

var road_graph = null
var sidewalk_graph = null
var traffic_coordinator = null
var pedestrian_palette := [
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
    _spawn_pedestrians()
    _spawn_traffic()

func _spawn_pedestrians() -> void:
    for i in range(pedestrian_count):
        var p := PedestrianAgent.new()
        p.name = "Pedestrian_%02d" % i
        p.walk_speed = 1.65 + float(i % 5) * 0.18
        p.add_to_group("hayat_pedestrian")
        p.position = Vector3(-80 + (i%9)*20, 1.0, -88 + (i/9)*176)
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
        body.scale = Vector3(0.88, 0.88, 0.88)
        p.add_child(body)
        if traffic_coordinator != null:
            p.configure_traffic_coordinator(traffic_coordinator)

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
        var body := VehicleVisualFactory.build(vehicle_ids[i % vehicle_ids.size()])
        body.name = "TrafficVisual"
        body.scale = Vector3(0.92, 0.92, 0.92)
        car.add_child(body)

func apply_population_budget(pedestrian_budget: int, traffic_budget: int) -> void:
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
