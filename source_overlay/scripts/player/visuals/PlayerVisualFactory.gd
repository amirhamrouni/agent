extends RefCounted
class_name PlayerVisualFactory

static var _normalizer := PlayerModelNormalizer.new()

static func build() -> Node3D:
    var path := PlayerVisualCatalog.resolve_scene_path()
    if not path.is_empty():
        var resource = load(path)
        var node: Node3D = null
        if resource is PackedScene:
            var instance = resource.instantiate()
            if instance is Node3D:
                node = instance as Node3D
        elif resource is Mesh:
            var mesh_root := Node3D.new()
            var mesh_instance := MeshInstance3D.new()
            mesh_instance.mesh = resource
            mesh_root.add_child(mesh_instance)
            node = mesh_root
        if node != null:
            var cfg := PlayerVisualCatalog.config()
            var raw_target = cfg.get("target_size", [0.72, 1.78, 0.5])
            var target := Vector3(0.72, 1.78, 0.5)
            if raw_target is Array and raw_target.size() == 3:
                target = Vector3(float(raw_target[0]), float(raw_target[1]), float(raw_target[2]))
            var normalized := _normalizer.normalize_to_target(node, target)
            if bool(normalized.get("ok", false)):
                node.name = "LicensedPlayerVisual"
                node.set_meta("visual_source_path", path)
                node.set_meta("visual_normalization", normalized)
                return node
            node.free()
    return _fallback()

static func _fallback() -> Node3D:
    var cfg := PlayerVisualCatalog.config()
    var style: Dictionary = cfg.get("fallback", {})
    var root := Node3D.new()
    root.name = "FallbackPlayerVisual"
    var skin := Color(str(style.get("skin", "#b98560")))
    var shirt := Color(str(style.get("shirt", "#2f4d64")))
    var trousers := Color(str(style.get("trousers", "#2a2d31")))
    var shoes := Color(str(style.get("shoes", "#1d1d1f")))
    _cylinder(root, "Torso", Vector3(0, 1.23, 0), 0.28, 0.72, shirt)
    _sphere(root, "Head", Vector3(0, 1.86, 0), Vector3(0.30, 0.34, 0.30), skin)
    _limb(root, "ArmL", Vector3(-0.38, 1.30, 0), Vector3(0.14, 0.66, 0.14), shirt)
    _limb(root, "ArmR", Vector3(0.38, 1.30, 0), Vector3(0.14, 0.66, 0.14), shirt)
    _limb(root, "LegL", Vector3(-0.15, 0.58, 0), Vector3(0.18, 0.90, 0.20), trousers)
    _limb(root, "LegR", Vector3(0.15, 0.58, 0), Vector3(0.18, 0.90, 0.20), trousers)
    _box(root, "ShoeL", Vector3(-0.15, 0.12, -0.06), Vector3(0.22, 0.16, 0.38), shoes)
    _box(root, "ShoeR", Vector3(0.15, 0.12, -0.06), Vector3(0.22, 0.16, 0.38), shoes)
    var cap := _cylinder(root, "Cap", Vector3(0, 2.18, 0), 0.28, 0.10, Color("#202428"))
    cap.scale.z = 1.08
    return root

static func _mat(color: Color, roughness := 0.82) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    return mat

static func _box(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    mi.mesh = mesh
    mi.position = pos
    mi.material_override = _mat(color)
    parent.add_child(mi)
    return mi

static func _limb(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    return _box(parent, name, pos, size, color)

static func _cylinder(parent: Node3D, name: String, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.name = name
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mi.mesh = mesh
    mi.position = pos
    mi.material_override = _mat(color)
    parent.add_child(mi)
    return mi

static func _sphere(parent: Node3D, name: String, pos: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.name = name
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    mi.mesh = mesh
    mi.position = pos
    mi.scale = scale_value
    mi.material_override = _mat(color)
    parent.add_child(mi)
    return mi
