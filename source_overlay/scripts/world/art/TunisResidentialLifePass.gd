extends Node3D
class_name TunisResidentialLifePass

var generated_count := 0
var medium_detail_nodes: Array[Node3D] = []
var high_detail_nodes: Array[Node3D] = []
var current_detail_level := 2

func build() -> void:
    add_to_group("quality_visual_detail")
    _build_doorstep_clusters()
    _build_window_planters()
    _build_laundry_lines()
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

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.9
    return material

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new(); mesh.size = size
    node.mesh = mesh; node.position = pos; node.material_override = _material(color)
    parent.add_child(node); generated_count += 1
    return node

func _build_doorstep_clusters() -> void:
    var root := Node3D.new(); root.name = "ResidentialDoorsteps"; add_child(root)
    for pos in [Vector3(-42,0.18,-64.0), Vector3(23,0.18,-64.0), Vector3(73,0.18,-7.4)]:
        _register_detail(_box(root,pos,Vector3(2.2,0.24,0.9),Color("#b8a78e")),1)
        _register_detail(_box(root,pos+Vector3(0.72,0.42,0.05),Vector3(0.42,0.55,0.42),Color("#8b6f4d")),2)

func _build_window_planters() -> void:
    var root := Node3D.new(); root.name = "ResidentialWindowPlanters"; add_child(root)
    for pos in [Vector3(-46,3.0,-64.7),Vector3(-40,3.0,-64.7),Vector3(26,3.0,-64.7),Vector3(76,3.0,-8.1)]:
        _register_detail(_box(root,pos,Vector3(1.35,0.28,0.34),Color("#8d5d3f")),1)
        _register_detail(_box(root,pos+Vector3(0,0.28,0),Vector3(1.05,0.35,0.28),Color("#4f7346")),2)

func _build_laundry_lines() -> void:
    var root := Node3D.new(); root.name = "ResidentialLaundryLines"; add_child(root); _register_detail(root,2)
    var laundry_anchors: Array[Vector3] = [Vector3(-18,5.6,-63.8), Vector3(51,5.9,-63.8)]
    var cloth_colors: Array[Color] = [Color("#d8d0bf"), Color("#3d6e91"), Color("#a85c4e"), Color("#e0b95c")]
    for base: Vector3 in laundry_anchors:
        _box(root,base,Vector3(7.0,0.025,0.025),Color("#4a4a48"))
        for i in range(4):
            var cloth_pos: Vector3 = base + Vector3(-2.4 + float(i)*1.6,-0.55,0)
            _box(root,cloth_pos,Vector3(1.1,1.0,0.035),cloth_colors[i])
