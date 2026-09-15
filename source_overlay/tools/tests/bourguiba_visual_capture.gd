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
    seed(20260915)
    var packed = load("res://main_production.tscn")
    var scene = packed.instantiate()
    root.add_child(scene)
    current_scene = scene
    for i in range(8):
        await process_frame
    scene.process_mode = Node.PROCESS_MODE_DISABLED
    for child in scene.get_children():
        if child is CanvasLayer:
            child.hide()
        elif child is Control:
            child.hide()
    var camera := _make_camera(scene)
    var views := [
        ["01_avenue_long_view", Vector3(-105, 3.0, -5), Vector3(45, 4, 0)],
        ["02_sidewalk_view", Vector3(-72, 2.0, 21.5), Vector3(42, 2.8, 27.4)],
        ["03_facade_close_view", Vector3(-30, 3.0, 13), Vector3(-30, 8, 35)],
        ["04_intersection_view", Vector3(108, 3.8, -12.5), Vector3(58, 2.1, 2)],
        ["05_player_street_view", Vector3(70, 2.35, 16.5), Vector3(63, 1.35, 24)],
        ["06_taxi_view", Vector3(84, 2.25, 10.5), Vector3(78, 1.05, 14.7)]
    ]
    var transform := Transform3D(Basis(Vector3.UP, atan(0.12)), Vector3(-130, 0, 30))
    var captures: Array = []
    for view in views:
        var result := await _capture(camera, transform * view[1], transform * view[2], str(view[0]) + ".png")
        result["camera_position"] = [camera.position.x, camera.position.y, camera.position.z]
        result["draw_calls"] = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
        result["objects"] = Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
        result["primitives"] = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
        result["texture_memory_bytes"] = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
        captures.append(result)
        if not result.get("ok", false):
            push_error("PRODUCTION_CAPTURE_FAILED:" + JSON.stringify(result))
            quit(82)
            return
    var evidence := {"schema_version": 2, "scene": "res://main_production.tscn", "renderer": RenderingServer.get_current_rendering_method(), "captures": captures, "visual_acceptance": "PENDING_HUMAN_REVIEW", "physical_device_verified": false}
    var file := FileAccess.open(_capture_dir.path_join("bourguiba-visual-evidence.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(evidence, "  ") + "\n")
    file.close()
    print("BOURGUIBA_VISUAL_GATE_PASS captures=6 capture_only=true visual_acceptance=PENDING_HUMAN_REVIEW")
    quit(0)
