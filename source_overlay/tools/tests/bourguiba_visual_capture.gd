extends SceneTree

const WIDTH := 1280
const HEIGHT := 720
const MIN_LUMA_SPREAD := 18.0
const MIN_NON_BACKGROUND_RATIO := 0.08

var _capture_dir := "res://visual-evidence"

func _initialize() -> void:
    call_deferred("_run")

func _material(color: Color, roughness := 0.9) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    return material

func _add_ground(scene: Node3D) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(210.0, 90.0)
    mesh_instance.mesh = mesh
    mesh_instance.material_override = _material(Color("#b8ad98"), 1.0)
    mesh_instance.position = Vector3(0.0, -0.03, 0.0)
    scene.add_child(mesh_instance)

func _configure_environment(scene: Node3D) -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#9fc8e6")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#d7e2e6")
    env.ambient_light_energy = 0.72
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.environment = env
    scene.add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
    sun.light_color = Color("#fff2d2")
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    scene.add_child(sun)

func _make_camera(scene: Node3D) -> Camera3D:
    var camera := Camera3D.new()
    camera.current = true
    camera.fov = 64.0
    scene.add_child(camera)
    return camera

func _capture(camera: Camera3D, position: Vector3, target: Vector3, filename: String) -> Dictionary:
    camera.position = position
    camera.look_at(target, Vector3.UP)
    await process_frame
    await process_frame
    await process_frame
    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        return {"ok": false, "reason": "EMPTY_IMAGE"}
    if image.get_width() != WIDTH or image.get_height() != HEIGHT:
        image.resize(WIDTH, HEIGHT, Image.INTERPOLATE_LANCZOS)

    var min_luma := 255.0
    var max_luma := 0.0
    var non_background := 0
    var sample_count := 0
    var background := Color("#9fc8e6")
    for y in range(0, HEIGHT, 12):
        for x in range(0, WIDTH, 12):
            var px := image.get_pixel(x, y)
            var luma := (0.2126 * px.r + 0.7152 * px.g + 0.0722 * px.b) * 255.0
            min_luma = min(min_luma, luma)
            max_luma = max(max_luma, luma)
            if Vector3(px.r, px.g, px.b).distance_to(Vector3(background.r, background.g, background.b)) > 0.08:
                non_background += 1
            sample_count += 1

    var spread := max_luma - min_luma
    var non_background_ratio := float(non_background) / float(maxi(sample_count, 1))
    if spread < MIN_LUMA_SPREAD:
        return {"ok": false, "reason": "LOW_LUMA_SPREAD", "spread": spread}
    if non_background_ratio < MIN_NON_BACKGROUND_RATIO:
        return {"ok": false, "reason": "LOW_SCENE_COVERAGE", "ratio": non_background_ratio}

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_dir))
    var path := _capture_dir.path_join(filename)
    var error := image.save_png(path)
    if error != OK:
        return {"ok": false, "reason": "SAVE_FAILED", "error": error}
    return {
        "ok": true,
        "path": path,
        "width": image.get_width(),
        "height": image.get_height(),
        "luma_spread": spread,
        "non_background_ratio": non_background_ratio,
    }

func _run() -> void:
    root.size = Vector2i(WIDTH, HEIGHT)

    var scene := Node3D.new()
    scene.name = "BourguibaVisualEvidence"
    root.add_child(scene)
    _add_ground(scene)
    _configure_environment(scene)

    var public_script = load("res://scripts/world/art/TunisPublicRealmPass.gd")
    var facade_script = load("res://scripts/world/art/TunisFacadePass.gd")
    if public_script == null or facade_script == null:
        push_error("BOURGUIBA_VISUAL_REQUIRED_MODULE_MISSING")
        quit(81)
        return

    var public_realm = public_script.new()
    public_realm.name = "PublicRealm"
    scene.add_child(public_realm)
    public_realm.build()

    var facades = facade_script.new()
    facades.name = "Facades"
    scene.add_child(facades)
    facades.build()

    var camera := _make_camera(scene)
    await process_frame
    await process_frame

    var avenue := await _capture(camera, Vector3(34.0, 17.0, 31.0), Vector3(5.0, 2.8, 0.0), "bourguiba-avenue.png")
    if not avenue.get("ok", false):
        push_error("BOURGUIBA_VISUAL_AVENUE_INVALID:%s" % JSON.stringify(avenue))
        quit(82)
        return

    var storefront := await _capture(camera, Vector3(-24.0, 7.0, 25.0), Vector3(-24.0, 3.2, 12.5), "bourguiba-storefront.png")
    if not storefront.get("ok", false):
        push_error("BOURGUIBA_VISUAL_STOREFRONT_INVALID:%s" % JSON.stringify(storefront))
        quit(83)
        return

    var evidence := {
        "schema_version": 1,
        "renderer": RenderingServer.get_current_rendering_method(),
        "viewport": {"width": WIDTH, "height": HEIGHT},
        "captures": [avenue, storefront],
        "minimum_luma_spread": MIN_LUMA_SPREAD,
        "minimum_non_background_ratio": MIN_NON_BACKGROUND_RATIO,
    }
    var file := FileAccess.open(_capture_dir.path_join("bourguiba-visual-evidence.json"), FileAccess.WRITE)
    if file == null:
        push_error("BOURGUIBA_VISUAL_EVIDENCE_WRITE_FAILED")
        quit(84)
        return
    file.store_string(JSON.stringify(evidence, "  ") + "\n")
    file.close()
    print("BOURGUIBA_VISUAL_GATE_PASS captures=2 renderer=%s" % evidence.renderer)
    quit(0)
