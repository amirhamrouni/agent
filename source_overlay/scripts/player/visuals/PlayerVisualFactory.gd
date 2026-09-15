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
    var shirt := Color(str(style.get("shirt", "#284c63")))
    var shirt_dark := shirt.darkened(0.18)
    var trousers := Color(str(style.get("trousers", "#252a30")))
    var shoes := Color(str(style.get("shoes", "#17191c")))
    var hair := Color("#1b1715")

    # Human-shaped authored fallback. It stays inexpensive enough for mobile crowds,
    # while avoiding the old stick/block silhouette when no external character asset exists.
    _capsule(root, "Torso", Vector3(0, 1.26, 0), 0.29, 0.78, shirt)
    _box(root, "Waist", Vector3(0, 0.91, 0), Vector3(0.48, 0.22, 0.30), shirt_dark)
    _cylinder(root, "Neck", Vector3(0, 1.72, 0), 0.105, 0.18, skin)
    _sphere(root, "Head", Vector3(0, 1.98, 0), Vector3(0.29, 0.34, 0.29), skin)
    var hair_cap := _sphere(root, "Hair", Vector3(0, 2.12, 0.02), Vector3(0.295, 0.17, 0.295), hair)
    hair_cap.position.z = 0.035
    _sphere(root, "EarL", Vector3(-0.295, 1.99, 0), Vector3(0.055, 0.075, 0.045), skin)
    _sphere(root, "EarR", Vector3(0.295, 1.99, 0), Vector3(0.055, 0.075, 0.045), skin)
    _box(root, "Nose", Vector3(0, 1.99, -0.275), Vector3(0.075, 0.11, 0.08), skin)

    var arm_l := _capsule(root, "ArmL", Vector3(-0.40, 1.28, 0), 0.095, 0.66, shirt)
    arm_l.rotation_degrees.z = -6.0
    var arm_r := _capsule(root, "ArmR", Vector3(0.40, 1.28, 0), 0.095, 0.66, shirt)
    arm_r.rotation_degrees.z = 6.0
    _sphere(root, "HandL", Vector3(-0.43, 0.92, 0), Vector3(0.10, 0.11, 0.085), skin)
    _sphere(root, "HandR", Vector3(0.43, 0.92, 0), Vector3(0.10, 0.11, 0.085), skin)

    var leg_l := _capsule(root, "LegL", Vector3(-0.15, 0.53, 0), 0.115, 0.86, trousers)
    leg_l.rotation_degrees.z = -1.5
    var leg_r := _capsule(root, "LegR", Vector3(0.15, 0.53, 0), 0.115, 0.86, trousers)
    leg_r.rotation_degrees.z = 1.5
    _box(root, "ShoeL", Vector3(-0.15, 0.10, -0.085), Vector3(0.24, 0.17, 0.40), shoes)
    _box(root, "ShoeR", Vector3(0.15, 0.10, -0.085), Vector3(0.24, 0.17, 0.40), shoes)

    # Small Tunis streetwear details improve silhouette/readability in third person.
    _box(root, "ShirtPlacket", Vector3(0, 1.33, -0.285), Vector3(0.035, 0.48, 0.025), shirt_dark)
    _box(root, "Belt", Vector3(0, 0.89, -0.04), Vector3(0.48, 0.065, 0.32), Color("#332b26"))
    _box(root, "BeltBuckle", Vector3(0, 0.89, -0.208), Vector3(0.10, 0.07, 0.025), Color("#8c8171"))
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

static func _cylinder(parent: Node3D, name: String, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.name = name
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 12
    mi.mesh = mesh
    mi.position = pos
    mi.material_override = _mat(color)
    parent.add_child(mi)
    return mi

static func _capsule(parent: Node3D, name: String, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.name = name
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    mesh.radial_segments = 12
    mesh.rings = 4
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
    mesh.radial_segments = 12
    mesh.rings = 6
    mi.mesh = mesh
    mi.position = pos
    mi.scale = scale_value
    mi.material_override = _mat(color)
    parent.add_child(mi)
    return mi
