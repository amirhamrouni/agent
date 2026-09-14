extends Node3D
class_name TunisPublicRealmPass

var generated_count := 0
var palm_count := 0
var kiosk_count := 0
var cafe_count := 0
var medium_detail_nodes: Array[Node3D] = []
var high_detail_nodes: Array[Node3D] = []
var current_detail_level := 2

func build() -> void:
    add_to_group("quality_visual_detail")
    _build_road_surface()
    _build_sidewalks()
    _build_lane_markings()
    _build_crosswalks()
    _build_bourguiba_curbs()
    _build_center_median()
    _build_tree_grates()
    _build_drainage_grates()
    _build_benches()
    _build_bollards()
    _build_planters()
    _build_street_lamps()
    _build_palms()
    _build_kiosks_and_cafes()
    apply_visual_budget(current_detail_level)

func apply_visual_budget(detail_level: int) -> void:
    current_detail_level = clampi(detail_level, 0, 2)
    for node in medium_detail_nodes:
        if is_instance_valid(node): node.visible = current_detail_level >= 1
    for node in high_detail_nodes:
        if is_instance_valid(node): node.visible = current_detail_level >= 2

func _register_detail(node: Node3D, minimum_level: int) -> Node3D:
    if minimum_level >= 2: high_detail_nodes.append(node)
    elif minimum_level == 1: medium_detail_nodes.append(node)
    return node

func _material(color: Color, roughness := 0.9, metallic := 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    return material

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, roughness := 0.9, metallic := 0.0) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    var mesh := BoxMesh.new(); mesh.size = size
    instance.mesh = mesh; instance.position = pos
    instance.material_override = _material(color, roughness, metallic)
    parent.add_child(instance); generated_count += 1
    return instance

func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, roughness := 0.9, metallic := 0.0) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius; mesh.height = height
    instance.mesh = mesh; instance.position = pos
    instance.material_override = _material(color, roughness, metallic)
    parent.add_child(instance); generated_count += 1
    return instance

func _build_road_surface() -> void:
    var root := Node3D.new(); root.name = "BourguibaRoadSurface"; add_child(root)
    _box(root, Vector3(0, 0.035, 0), Vector3(170.0, 0.07, 16.0), Color("#343638"), 0.98)
    for x in [-70.0, -35.0, 0.0, 35.0, 70.0]:
        _register_detail(_box(root, Vector3(x, 0.074, -4.2), Vector3(12.0, 0.012, 0.035), Color("#292b2c"), 1.0), 2)
        _register_detail(_box(root, Vector3(x + 7.0, 0.074, 4.3), Vector3(8.0, 0.012, 0.028), Color("#454749"), 1.0), 2)

func _build_sidewalks() -> void:
    var root := Node3D.new(); root.name = "BourguibaSidewalks"; add_child(root)
    for z in [-11.5, 11.5]:
        _box(root, Vector3(0, 0.105, z), Vector3(170.0, 0.18, 6.6), Color("#c6bca9"), 0.98)
        for x in range(-80, 81, 4):
            _register_detail(_box(root, Vector3(float(x), 0.202, z), Vector3(0.025, 0.008, 6.2), Color("#a9a08f"), 1.0), 2)
        for dz in [-2.0, 0.0, 2.0]:
            _register_detail(_box(root, Vector3(0, 0.203, z + dz), Vector3(166.0, 0.008, 0.025), Color("#aaa18f"), 1.0), 2)

func _build_lane_markings() -> void:
    var root := Node3D.new(); root.name = "BourguibaLaneMarkings"; add_child(root); _register_detail(root, 1)
    for z in [-4.4, 4.4]:
        for x in range(-78, 79, 8):
            _box(root, Vector3(float(x), 0.085, z), Vector3(4.2, 0.018, 0.13), Color("#eee9d9"), 0.78)
    for z in [-7.15, 7.15]:
        _box(root, Vector3(0, 0.086, z), Vector3(164.0, 0.018, 0.11), Color("#eee9d9"), 0.78)

func _build_crosswalks() -> void:
    var root := Node3D.new(); root.name = "BourguibaCrosswalks"; add_child(root)
    for crossing_x: float in [-54.0, 0.0, 54.0]:
        for stripe in range(9):
            var stripe_x: float = crossing_x - 3.2 + float(stripe) * 0.8
            _box(root, Vector3(stripe_x, 0.091, -4.6), Vector3(0.42, 0.02, 5.4), Color("#e8e5da"), 0.82)
            _box(root, Vector3(stripe_x, 0.091, 4.6), Vector3(0.42, 0.02, 5.4), Color("#e8e5da"), 0.82)
        for z: float in [-7.7, 7.7]:
            _register_detail(_box(root, Vector3(crossing_x, 0.235, z), Vector3(7.4, 0.08, 1.15), Color("#b9b09f"), 0.96), 1)

func _build_bourguiba_curbs() -> void:
    var root := Node3D.new(); root.name = "BourguibaRedWhiteCurbs"; add_child(root)
    for z in [-8.0, 8.0]:
        for i in range(32):
            var x := -78.0 + float(i) * 5.0
            var color := Color("#f1eee7") if i % 2 == 0 else Color("#c62f34")
            _box(root, Vector3(x, 0.20, z), Vector3(4.8, 0.30, 0.34), color, 0.96)

func _build_center_median() -> void:
    var root := Node3D.new(); root.name = "BourguibaCenterMedian"; add_child(root); _register_detail(root, 1)
    _box(root, Vector3(0, 0.12, 0), Vector3(156.0, 0.18, 2.6), Color("#b7b0a0"), 0.98)
    for i in range(26):
        var x := -75.0 + float(i) * 6.0
        var color := Color("#f2efe8") if i % 2 == 0 else Color("#c62f34")
        _box(root, Vector3(x, 0.25, -1.28), Vector3(5.8, 0.24, 0.22), color, 0.96)
        _box(root, Vector3(x, 0.25, 1.28), Vector3(5.8, 0.24, 0.22), color, 0.96)

func _build_tree_grates() -> void:
    var root := Node3D.new(); root.name = "BourguibaTreeGrates"; add_child(root)
    for z in [-10.4, 10.4]:
        for x in [-66.0, -42.0, -18.0, 6.0, 30.0, 54.0, 78.0]:
            _register_detail(_box(root, Vector3(x, 0.22, z), Vector3(1.7, 0.035, 1.7), Color("#505554"), 0.8, 0.18), 1)

func _build_drainage_grates() -> void:
    var root := Node3D.new(); root.name = "BourguibaStreetDrainage"; add_child(root)
    for z in [-7.25, 7.25]:
        for x in [-68.0, -36.0, -4.0, 28.0, 60.0]:
            _register_detail(_box(root, Vector3(x, 0.115, z), Vector3(1.2, 0.025, 0.42), Color("#343a3b"), 0.76, 0.22), 1)

func _build_benches() -> void:
    var root := Node3D.new(); root.name = "BourguibaBenches"; add_child(root); _register_detail(root, 2)
    for z in [-11.8, 11.8]:
        for x in [-52.0, -4.0, 44.0]:
            _box(root, Vector3(x, 0.72, z), Vector3(2.4, 0.12, 0.55), Color("#6d5137"), 0.82)
            _box(root, Vector3(x, 1.12, z + (0.23 if z < 0.0 else -0.23)), Vector3(2.4, 0.75, 0.10), Color("#6d5137"), 0.82)
            _box(root, Vector3(x - 0.92, 0.41, z), Vector3(0.10, 0.62, 0.45), Color("#373b3d"), 0.52, 0.35)
            _box(root, Vector3(x + 0.92, 0.41, z), Vector3(0.10, 0.62, 0.45), Color("#373b3d"), 0.52, 0.35)

func _build_bollards() -> void:
    var root := Node3D.new(); root.name = "BourguibaBollards"; add_child(root); _register_detail(root, 1)
    for z in [-8.8, 8.8]:
        for x in [-72.0, -48.0, -24.0, 0.0, 24.0, 48.0, 72.0]:
            _cylinder(root, Vector3(x, 0.55, z), 0.10, 0.90, Color("#363a3c"), 0.55, 0.32)

func _build_planters() -> void:
    var root := Node3D.new(); root.name = "BourguibaPlanters"; add_child(root); _register_detail(root, 2)
    for x in [-60.0, -30.0, 0.0, 30.0, 60.0]:
        _box(root, Vector3(x, 0.58, 0.0), Vector3(2.4, 0.75, 1.5), Color("#b8aa91"), 0.96)
        _box(root, Vector3(x, 1.0, 0.0), Vector3(2.05, 0.20, 1.15), Color("#455f3b"), 1.0)

func _build_street_lamps() -> void:
    var root := Node3D.new(); root.name = "BourguibaStreetLamps"; add_child(root); _register_detail(root, 1)
    for z in [-11.0, 11.0]:
        for x in [-72.0, -48.0, -24.0, 0.0, 24.0, 48.0, 72.0]:
            _cylinder(root, Vector3(x, 2.8, z), 0.075, 5.4, Color("#33383a"), 0.48, 0.42)
            _box(root, Vector3(x, 5.45, z), Vector3(0.75, 0.16, 0.30), Color("#303638"), 0.45, 0.38)
            _box(root, Vector3(x, 5.32, z), Vector3(0.48, 0.07, 0.22), Color("#efe3bf"), 0.34)

func _build_palms() -> void:
    var root := Node3D.new(); root.name = "BourguibaPalms"; add_child(root); _register_detail(root, 1)
    for z: float in [-10.4, 10.4]:
        for x: float in [-66.0, -42.0, -18.0, 6.0, 30.0, 54.0, 78.0]:
            _cylinder(root, Vector3(x, 3.25, z), 0.24, 6.1, Color("#796247"), 0.98)
            _cylinder(root, Vector3(x, 6.32, z), 0.48, 0.42, Color("#4f6c38"), 1.0)
            for angle_index in range(6):
                var angle := TAU * float(angle_index) / 6.0
                var leaf := _box(root, Vector3(x + cos(angle) * 1.05, 6.38, z + sin(angle) * 1.05), Vector3(2.2, 0.12, 0.42), Color("#54783e"), 1.0)
                leaf.rotation.y = -angle
                _register_detail(leaf, 2)
            palm_count += 1

func _build_kiosks_and_cafes() -> void:
    var root := Node3D.new(); root.name = "BourguibaCafeKiosks"; add_child(root); _register_detail(root, 1)
    var kiosk_positions := [Vector3(-34.0, 1.35, -13.0), Vector3(40.0, 1.35, 13.0)]
    for position in kiosk_positions:
        _box(root, position, Vector3(4.2, 2.7, 2.5), Color("#d7c7a9"), 0.92)
        _box(root, position + Vector3(0, 1.62, 0), Vector3(4.8, 0.22, 3.0), Color("#8b3230"), 0.88)
        _box(root, position + Vector3(0, 0.22, -1.27 if position.z > 0.0 else 1.27), Vector3(2.8, 1.0, 0.08), Color("#5a7276"), 0.26, 0.08)
        kiosk_count += 1
    var cafe_centers := [Vector3(-58.0, 0.5, -13.4), Vector3(18.0, 0.5, 13.4), Vector3(62.0, 0.5, -13.4)]
    for center in cafe_centers:
        for table_index in range(3):
            var table_x := center.x + float(table_index - 1) * 2.0
            _cylinder(root, Vector3(table_x, 0.73, center.z), 0.42, 0.08, Color("#6c5843"), 0.84)
            _cylinder(root, Vector3(table_x, 0.42, center.z), 0.07, 0.62, Color("#383b3b"), 0.55, 0.26)
            for chair_side in [-1.0, 1.0]:
                _box(root, Vector3(table_x, 0.46, center.z + chair_side * 0.9), Vector3(0.55, 0.08, 0.55), Color("#7b6047"), 0.86)
        _cylinder(root, Vector3(center.x, 2.12, center.z), 1.55, 0.10, Color("#d8c49d"), 0.94)
        _cylinder(root, Vector3(center.x, 1.35, center.z), 0.06, 1.55, Color("#4b4f4f"), 0.58, 0.22)
        cafe_count += 1
