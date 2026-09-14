extends Node3D
class_name TunisFacadePass

const SLICE_LENGTH := 168.0
const BUILDING_DEPTH := 10.0
const NORTH_Z := -19.0
const SOUTH_Z := 19.0

var generated_count := 0
var facade_count := 0
var shopfront_count := 0
var signage_count := 0
var balcony_count := 0
var material_usage := {"plaster": 0, "stone": 0, "glass": 0, "metal": 0, "wood": 0, "fabric": 0}
var medium_detail_nodes: Array[Node3D] = []
var high_detail_nodes: Array[Node3D] = []
var current_detail_level := 2

func build() -> void:
    add_to_group("quality_visual_detail")
    add_to_group("bourguiba_environment")
    _build_facade_row(NORTH_Z, 1.0)
    _build_facade_row(SOUTH_Z, -1.0)
    apply_visual_budget(current_detail_level)

func apply_visual_budget(detail_level: int) -> void:
    current_detail_level = clampi(detail_level, 0, 2)
    for node in medium_detail_nodes:
        if is_instance_valid(node):
            node.visible = current_detail_level >= 1
    for node in high_detail_nodes:
        if is_instance_valid(node):
            node.visible = current_detail_level >= 2

func _register_detail(node: Node3D, minimum_level: int) -> Node3D:
    if minimum_level >= 2:
        high_detail_nodes.append(node)
    elif minimum_level == 1:
        medium_detail_nodes.append(node)
    return node

func _material(color: Color, roughness := 0.86, metallic := 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    return material

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, roughness := 0.86, metallic := 0.0) -> MeshInstance3D:
    return _box_with_material(parent, pos, size, _material(color, roughness, metallic))

func _box_with_material(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    instance.mesh = mesh
    instance.position = pos
    instance.material_override = material
    parent.add_child(instance)
    generated_count += 1
    return instance

func _track_material(kind: String, material: Material) -> Material:
    material_usage[kind] = int(material_usage.get(kind, 0)) + 1
    return material

func _build_facade_row(z: float, facing: float) -> void:
    var row := Node3D.new()
    row.name = "BourguibaNorthFacades" if z < 0.0 else "BourguibaSouthFacades"
    row.add_to_group("bourguiba_facade_row")
    add_child(row)

    var widths := [18.0, 16.0, 20.0, 14.0, 22.0, 16.0, 18.0, 20.0]
    var heights := [16.5, 19.0, 17.5, 21.0, 18.0, 16.0, 20.0, 17.0]
    var plaster := [
        Color("#d9c9ae"), Color("#e2d8c8"), Color("#cbbd9f"), Color("#eee4d2"),
        Color("#d6c5a6"), Color("#d8d0bf"), Color("#c9b99b"), Color("#e5d7bd")
    ]
    var signs_ar := ["مقهى تونس", "حلويات المدينة", "مكتبة العاصمة", "عطور قرطاج"]
    var signs_fr := ["CAFE CENTRAL", "LIBRAIRIE TUNIS", "PATISSERIE", "MAISON DU THE"]
    var awnings := [Color("#7f1f28"), Color("#1f5d50"), Color("#ad7c38"), Color("#364f6b")]

    var x := -SLICE_LENGTH * 0.5
    for i in range(widths.size()):
        var width: float = widths[i]
        var height: float = heights[i]
        var cx := x + width * 0.5
        var facade_root := Node3D.new()
        facade_root.name = "Facade_%02d" % i
        facade_root.set_meta("bourguiba_facade", true)
        facade_root.set_meta("height_m", height)
        row.add_child(facade_root)
        facade_count += 1

        _box_with_material(facade_root, Vector3(cx, height * 0.5, z + facing * BUILDING_DEPTH * 0.5), Vector3(width - 0.35, height, BUILDING_DEPTH), _track_material("plaster", TunisMaterialLibrary.plaster(plaster[i])))
        _box_with_material(facade_root, Vector3(cx, 0.55, z - facing * 0.18), Vector3(width - 0.75, 1.1, 0.24), _track_material("stone", TunisMaterialLibrary.stone(Color("#b7a58c"))))
        _build_ground_floor(facade_root, cx, z, facing, width, i, signs_ar, signs_fr, awnings)
        _build_windows_and_balconies(facade_root, cx, z, facing, width, height, i)
        _build_cornice(facade_root, cx, z, facing, width, height)
        x += width

func _build_ground_floor(root: Node3D, cx: float, z: float, facing: float, width: float, index: int, signs_ar: Array, signs_fr: Array, awnings: Array) -> void:
    var bay_count := maxi(2, int(floor(width / 5.0)))
    var bay_w := (width - 1.0) / float(bay_count)
    var start_x := cx - (float(bay_count - 1) * bay_w) * 0.5
    for bay in range(bay_count):
        var bx := start_x + float(bay) * bay_w
        var frame := Node3D.new()
        frame.name = "Shopfront_%02d" % bay
        frame.set_meta("bourguiba_shopfront", true)
        root.add_child(frame)
        shopfront_count += 1

        _box_with_material(frame, Vector3(bx, 2.15, z - facing * 0.12), Vector3(bay_w - 0.32, 3.7, 0.18), _track_material("metal", TunisMaterialLibrary.metal(Color("#252d31"))))
        _box_with_material(frame, Vector3(bx, 2.15, z - facing * 0.24), Vector3(bay_w - 0.58, 3.35, 0.08), _track_material("glass", TunisMaterialLibrary.glass_tinted()))
        var door_x := bx - (bay_w - 0.9) * 0.28
        _register_detail(_box_with_material(frame, Vector3(door_x, 1.65, z - facing * 0.31), Vector3(0.92, 3.0, 0.08), _track_material("wood", TunisMaterialLibrary.wood(Color("#654631")))), 1)
        var awning_color: Color = awnings[(index + bay) % awnings.size()]
        _register_detail(_box_with_material(frame, Vector3(bx, 4.25, z - facing * 0.75), Vector3(bay_w - 0.25, 0.18, 1.35), _track_material("fabric", TunisMaterialLibrary.fabric(awning_color))), 1)

        var sign := Label3D.new()
        sign.name = "ArabicSign" if bay % 2 == 0 else "FrenchSign"
        sign.text = signs_ar[(index + bay) % signs_ar.size()] if bay % 2 == 0 else signs_fr[(index + bay) % signs_fr.size()]
        sign.font_size = 34
        sign.outline_size = 6
        sign.modulate = Color("#f2ead8")
        sign.outline_modulate = Color("#302b27")
        sign.position = Vector3(bx, 4.8, z - facing * 0.33)
        sign.rotation_degrees.y = 180.0 if facing > 0.0 else 0.0
        sign.set_meta("bourguiba_signage", true)
        sign.set_meta("fictional_signage", true)
        frame.add_child(sign)
        signage_count += 1

func _build_windows_and_balconies(root: Node3D, cx: float, z: float, facing: float, width: float, height: float, index: int) -> void:
    var floor_y := 6.5
    var floor_index := 0
    while floor_y < height - 1.8:
        var window_count := maxi(2, int(floor(width / 4.0)))
        var spacing := (width - 2.0) / float(window_count)
        var start_x := cx - (float(window_count - 1) * spacing) * 0.5
        for w in range(window_count):
            var wx := start_x + float(w) * spacing
            _register_detail(_box_with_material(root, Vector3(wx, floor_y, z - facing * 0.14), Vector3(1.55, 2.15, 0.12), _track_material("glass", TunisMaterialLibrary.glass_tinted())), 1)
            _register_detail(_box_with_material(root, Vector3(wx, floor_y - 1.22, z - facing * 0.20), Vector3(1.85, 0.14, 0.30), _track_material("stone", TunisMaterialLibrary.stone(Color("#c8b697")))), 2)
        if floor_index % 2 == index % 2:
            var balcony := Node3D.new()
            balcony.name = "Balcony_%02d" % floor_index
            balcony.set_meta("bourguiba_balcony", true)
            root.add_child(balcony)
            balcony_count += 1
            _register_detail(_box_with_material(balcony, Vector3(cx, floor_y - 1.25, z - facing * 0.78), Vector3(width * 0.66, 0.16, 1.35), _track_material("stone", TunisMaterialLibrary.stone(Color("#c8b99e")))), 1)
            _register_detail(_box_with_material(balcony, Vector3(cx, floor_y - 0.35, z - facing * 1.40), Vector3(width * 0.64, 1.45, 0.07), _track_material("metal", TunisMaterialLibrary.metal(Color("#373b3d")))), 2)
        floor_y += 3.4
        floor_index += 1

func _build_cornice(root: Node3D, cx: float, z: float, facing: float, width: float, height: float) -> void:
    _register_detail(_box_with_material(root, Vector3(cx, height - 0.45, z - facing * 0.28), Vector3(width, 0.55, 0.55), _track_material("stone", TunisMaterialLibrary.stone(Color("#e4d8c1")))), 1)
    _register_detail(_box_with_material(root, Vector3(cx, height + 0.05, z - facing * 0.12), Vector3(width - 0.5, 0.35, 0.30), _track_material("stone", TunisMaterialLibrary.stone(Color("#bfae92")))), 2)

func get_runtime_summary() -> Dictionary:
    return {
        "generated_count": generated_count,
        "facade_count": facade_count,
        "shopfront_count": shopfront_count,
        "signage_count": signage_count,
        "balcony_count": balcony_count,
        "detail_level": current_detail_level,
        "material_usage": material_usage.duplicate(true),
        "mobile_material_contract": TunisMaterialLibrary.mobile_contract(),
    }
