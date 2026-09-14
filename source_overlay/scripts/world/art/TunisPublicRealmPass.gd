extends Node3D
class_name TunisPublicRealmPass

var generated_count := 0
var medium_detail_nodes: Array[Node3D] = []
var high_detail_nodes: Array[Node3D] = []
var current_detail_level := 2

func build() -> void:
    add_to_group("quality_visual_detail")
    _build_bourguiba_curbs()
    _build_center_median()
    _build_tree_grates()
    _build_drainage_grates()
    _build_benches()
    _build_bollards()
    _build_planters()
    _build_street_lamps()
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
            var pos := Vector3(x, 0.13, z)
            _register_detail(_box(root, pos, Vector3(1.7, 0.035, 1.7), Color("#505554"), 0.8, 0.18), 1)

func _build_drainage_grates() -> void:
    var root := Node3D.new(); root.name = "BourguibaStreetDrainage"; add_child(root)
    for z in [-7.25, 7.25]:
        for x in [-68.0, -36.0, -4.0, 28.0, 60.0]:
            _register_detail(_box(root, Vector3(x, 0.115, z), Vector3(1.2, 0.025, 0.42), Color("#343a3b"), 0.76, 0.22), 1)

func _build_benches() -> void:
    var root := Node3D.new(); root.name = "BourguibaBenches"; add_child(root); _register_detail(root, 2)
    for z in [-11.8, 11.8]:
        for x in [-52.0, -4.0, 44.0]:
            _box(root, Vector3(x, 0.62, z), Vector3(2.4, 0.12, 0.55), Color("#6d5137"), 0.82)
            _box(root, Vector3(x, 1.02, z + (0.23 if z < 0.0 else -0.23)), Vector3(2.4, 0.75, 0.10), Color("#6d5137"), 0.82)
            _box(root, Vector3(x - 0.92, 0.31, z), Vector3(0.10, 0.62, 0.45), Color("#373b3d"), 0.52, 0.35)
            _box(root, Vector3(x + 0.92, 0.31, z), Vector3(0.10, 0.62, 0.45), Color("#373b3d"), 0.52, 0.35)

func _build_bollards() -> void:
    var root := Node3D.new(); root.name = "BourguibaBollards"; add_child(root); _register_detail(root, 1)
    for z in [-8.8, 8.8]:
        for x in [-72.0, -48.0, -24.0, 0.0, 24.0, 48.0, 72.0]:
            _cylinder(root, Vector3(x, 0.45, z), 0.10, 0.90, Color("#363a3c"), 0.55, 0.32)

func _build_planters() -> void:
    var root := Node3D.new(); root.name = "BourguibaPlanters"; add_child(root); _register_detail(root, 2)
    for x in [-60.0, -30.0, 0.0, 30.0, 60.0]:
        _box(root, Vector3(x, 0.48, 0.0), Vector3(2.4, 0.75, 1.5), Color("#b8aa91"), 0.96)
        _box(root, Vector3(x, 0.90, 0.0), Vector3(2.05, 0.20, 1.15), Color("#455f3b"), 1.0)

func _build_street_lamps() -> void:
    var root := Node3D.new(); root.name = "BourguibaStreetLamps"; add_child(root); _register_detail(root, 1)
    for z in [-11.0, 11.0]:
        for x in [-72.0, -48.0, -24.0, 0.0, 24.0, 48.0, 72.0]:
            _cylinder(root, Vector3(x, 2.7, z), 0.075, 5.4, Color("#33383a"), 0.48, 0.42)
            _box(root, Vector3(x, 5.35, z), Vector3(0.75, 0.16, 0.30), Color("#303638"), 0.45, 0.38)
            _box(root, Vector3(x, 5.22, z), Vector3(0.48, 0.07, 0.22), Color("#efe3bf"), 0.34)
