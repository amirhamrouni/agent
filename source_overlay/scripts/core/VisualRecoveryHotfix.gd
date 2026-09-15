extends Node

# Device-first visual correction layer. This runs after the production scene has
# finished constructing its procedural world and fixes the exact failures seen
# on the physical Android capture: blown highlights, unreadable HUD, the giant
# OSM placeholder billboard, and washed-out OSM surfaces.

func _ready() -> void:
    call_deferred("_apply_after_scene_ready")

func _apply_after_scene_ready() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    var root := get_tree().current_scene
    if root == null:
        return
    _patch_environment(root)
    _patch_osm_surface_contrast(root)
    _remove_osm_placeholder_billboard(root)
    _patch_hud(root)

func _walk(node: Node, out: Array[Node]) -> void:
    out.append(node)
    for child in node.get_children():
        _walk(child, out)

func _patch_environment(root: Node) -> void:
    var nodes: Array[Node] = []
    _walk(root, nodes)
    for node in nodes:
        if node is WorldEnvironment:
            var world_env := node as WorldEnvironment
            var env := world_env.environment
            if env == null:
                continue
            env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
            env.ambient_light_color = Color("#9eabb0")
            env.ambient_light_energy = minf(env.ambient_light_energy, 0.28)
            env.fog_enabled = false
            env.tonemap_mode = Environment.TONE_MAPPER_ACES
            if env.sky != null and env.sky.sky_material is ProceduralSkyMaterial:
                var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
                sky_mat.sky_top_color = Color("#4f7fa8")
                sky_mat.sky_horizon_color = Color("#9bb5c2")
                sky_mat.ground_bottom_color = Color("#4a4e50")
                sky_mat.ground_horizon_color = Color("#8fa1a7")
        elif node is DirectionalLight3D:
            var light := node as DirectionalLight3D
            light.light_energy = minf(light.light_energy, 0.72)
            light.light_color = Color("#f2d5a5")

func _patch_osm_surface_contrast(root: Node) -> void:
    # The real-map support slab was physically correct but its old light beige
    # material clipped into white on Android. Give it a mid-tone stone value.
    for child in root.get_children():
        if child is MeshInstance3D:
            var mi := child as MeshInstance3D
            if mi.mesh is BoxMesh:
                var size := (mi.mesh as BoxMesh).size
                if size.x > 1000.0 and size.z > 1000.0:
                    mi.material_override = _standard(Color("#817565"), 0.96)

    var osm := root.get_node_or_null("OSMWorld")
    if osm == null:
        return
    var palette := [
        Color("#b49a78"),
        Color("#a98e6d"),
        Color("#b8aa91"),
        Color("#91836f"),
        Color("#b59b76"),
    ]
    var building_index := 0
    for child in osm.get_children():
        if not (child is MeshInstance3D):
            continue
        var mi := child as MeshInstance3D
        if mi.mesh is ArrayMesh:
            mi.material_override = _standard(palette[building_index % palette.size()], 0.90)
            building_index += 1
        elif mi.mesh is BoxMesh:
            var box := mi.mesh as BoxMesh
            if box.size.y <= 0.12:
                mi.material_override = _standard(Color("#282b2d"), 0.96)

func _remove_osm_placeholder_billboard(root: Node) -> void:
    # ProductionWorld used a giant black 10 m placeholder sign at this exact
    # coordinate. It is diagnostic metadata, not city art, so it must never be
    # visible in gameplay.
    for child in root.get_children():
        if child is MeshInstance3D:
            var mi := child as MeshInstance3D
            if mi.mesh is BoxMesh and mi.position.distance_to(Vector3(0, 5, -10)) < 0.75:
                var size := (mi.mesh as BoxMesh).size
                if size.x >= 8.0 and size.y >= 2.0:
                    mi.visible = false
        elif child is Label3D:
            var label3d := child as Label3D
            if "OpenStreetMap" in label3d.text:
                label3d.visible = false

func _patch_hud(root: Node) -> void:
    var nodes: Array[Node] = []
    _walk(root, nodes)
    for node in nodes:
        if node is Label:
            var label := node as Label
            if label.text == "حياة تونس":
                label.text = "Tounsi 3ayach"
            label.add_theme_color_override("font_color", Color("#f7f7f2"))
            label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.07, 0.92))
            label.add_theme_constant_override("outline_size", 4)
        elif node is Button:
            var button := node as Button
            button.add_theme_color_override("font_color", Color("#f7f7f2"))
            button.add_theme_color_override("font_hover_color", Color.WHITE)
            button.add_theme_color_override("font_pressed_color", Color.WHITE)
            button.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.03, 0.92))
            button.add_theme_constant_override("outline_size", 3)

func _standard(color: Color, roughness: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    mat.metallic = 0.0
    return mat
