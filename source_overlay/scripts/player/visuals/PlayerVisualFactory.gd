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
    var shirt_dark := shirt.darkened(0.22)
    var denim := Color(str(style.get("trousers", "#252f3a")))
    var shoes := Color(str(style.get("shoes", "#17191c")))
    var sole := Color("#d7d2c6")
    var hair := Color("#191512")
    var leather := Color("#4a3326")

    # Human-scale third-person fallback. The earlier figure read as stacked blocks
    # in production captures. These proportions keep the same cheap primitives but
    # establish shoulders, ribcage, hips, bent arms, separated legs and footwear.
    _capsule(root, "Chest", Vector3(0, 1.33, 0), 0.245, 0.70, shirt)
    _box(root, "UpperBack", Vector3(0, 1.43, 0.105), Vector3(0.50, 0.34, 0.16), shirt_dark)
    _box(root, "Hip", Vector3(0, 0.95, 0), Vector3(0.43, 0.22, 0.27), denim)
    _box(root, "Belt", Vector3(0, 1.02, -0.055), Vector3(0.44, 0.055, 0.29), leather)
    _box(root, "BeltBuckle", Vector3(0, 1.02, -0.207), Vector3(0.075, 0.055, 0.025), Color("#81755f"))

    _cylinder(root, "Neck", Vector3(0, 1.72, 0), 0.092, 0.15, skin)
    _sphere(root, "Head", Vector3(0, 1.96, -0.012), Vector3(0.255, 0.315, 0.245), skin)
    _sphere(root, "HairTop", Vector3(0, 2.095, 0.006), Vector3(0.258, 0.145, 0.250), hair)
    _box(root, "HairBack", Vector3(0, 2.02, 0.205), Vector3(0.40, 0.24, 0.08), hair)
    _sphere(root, "EarL", Vector3(-0.255, 1.97, 0), Vector3(0.045, 0.064, 0.036), skin)
    _sphere(root, "EarR", Vector3(0.255, 1.97, 0), Vector3(0.045, 0.064, 0.036), skin)
    _box(root, "Nose", Vector3(0, 1.965, -0.238), Vector3(0.055, 0.085, 0.065), skin)
    _box(root, "BrowL", Vector3(-0.078, 2.035, -0.242), Vector3(0.09, 0.018, 0.018), hair)
    _box(root, "BrowR", Vector3(0.078, 2.035, -0.242), Vector3(0.09, 0.018, 0.018), hair)

    # Collar and placket stop the torso from reading as a single capsule.
    var collar_l := _box(root, "CollarL", Vector3(-0.07, 1.61, -0.225), Vector3(0.13, 0.13, 0.035), shirt_dark)
    collar_l.rotation_degrees.z = -18.0
    var collar_r := _box(root, "CollarR", Vector3(0.07, 1.61, -0.225), Vector3(0.13, 0.13, 0.035), shirt_dark)
    collar_r.rotation_degrees.z = 18.0
    _box(root, "ShirtPlacket", Vector3(0, 1.34, -0.247), Vector3(0.026, 0.46, 0.022), shirt_dark)

    var upper_arm_l := _capsule(root, "UpperArmL", Vector3(-0.335, 1.36, 0.0), 0.082, 0.42, shirt)
    upper_arm_l.rotation_degrees.z = -12.0
    upper_arm_l.rotation_degrees.x = 8.0
    var upper_arm_r := _capsule(root, "UpperArmR", Vector3(0.335, 1.36, 0.0), 0.082, 0.42, shirt)
    upper_arm_r.rotation_degrees.z = 12.0
    upper_arm_r.rotation_degrees.x = -7.0
    var forearm_l := _capsule(root, "ForearmL", Vector3(-0.375, 1.04, -0.025), 0.072, 0.36, skin)
    forearm_l.rotation_degrees.z = -5.0
    forearm_l.rotation_degrees.x = -10.0
    var forearm_r := _capsule(root, "ForearmR", Vector3(0.375, 1.04, 0.015), 0.072, 0.36, skin)
    forearm_r.rotation_degrees.z = 5.0
    forearm_r.rotation_degrees.x = 9.0
    _sphere(root, "HandL", Vector3(-0.39, 0.84, -0.03), Vector3(0.078, 0.095, 0.065), skin)
    _sphere(root, "HandR", Vector3(0.39, 0.84, 0.02), Vector3(0.078, 0.095, 0.065), skin)

    var thigh_l := _capsule(root, "ThighL", Vector3(-0.115, 0.72, 0.0), 0.105, 0.50, denim)
    thigh_l.rotation_degrees.z = -1.5
    var thigh_r := _capsule(root, "ThighR", Vector3(0.115, 0.72, 0.0), 0.105, 0.50, denim)
    thigh_r.rotation_degrees.z = 1.5
    var shin_l := _capsule(root, "ShinL", Vector3(-0.125, 0.34, 0.005), 0.088, 0.44, denim.darkened(0.06))
    shin_l.rotation_degrees.x = 1.5
    var shin_r := _capsule(root, "ShinR", Vector3(0.125, 0.34, -0.005), 0.088, 0.44, denim.darkened(0.06))
    shin_r.rotation_degrees.x = -1.5

    _box(root, "ShoeL", Vector3(-0.13, 0.105, -0.085), Vector3(0.205, 0.145, 0.34), shoes)
    _box(root, "ShoeR", Vector3(0.13, 0.105, -0.085), Vector3(0.205, 0.145, 0.34), shoes)
    _box(root, "SoleL", Vector3(-0.13, 0.045, -0.095), Vector3(0.215, 0.04, 0.35), sole)
    _box(root, "SoleR", Vector3(0.13, 0.045, -0.095), Vector3(0.215, 0.04, 0.35), sole)

    # Small cross-body satchel: common streetwear detail, breaks the symmetric toy silhouette.
    var strap := _box(root, "SatchelStrap", Vector3(0.03, 1.36, -0.252), Vector3(0.035, 0.78, 0.025), leather)
    strap.rotation_degrees.z = -25.0
    _box(root, "Satchel", Vector3(0.245, 1.00, -0.245), Vector3(0.28, 0.24, 0.10), leather.darkened(0.10))

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
    mesh.rings = 5
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
