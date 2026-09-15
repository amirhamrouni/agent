extends Node3D
class_name ProductionWorld

const CITY_SIZE = 220.0
const ROAD_W = 15.0
const AUTOSAVE_INTERVAL_SECONDS = 60.0

var street_lights: Array[OmniLight3D] = []
var player: PlayerController
var mission_manager: MissionManager
var blackout_manager: BlackoutManager
var hud: GameHUD
var sun: DirectionalLight3D
var population: PopulationSpawner
var quality: QualityManager
var osm_world: OsmWorldLoader
var using_real_osm = false
var road_graph: RoadGraph
var traffic_coordinator: TrafficCoordinator
var adaptive_quality: AdaptiveQualityManager
var world_environment_node: WorldEnvironment
var economy: EconomyManager
var dynamic_objectives: DynamicObjectiveManager
var phone_jobs_panel: PhoneJobsPanel
var rest_system: RestSystem
var mobile_action_bar: MobileActionBar
var refuel_popup: RefuelPopup
var virtual_joystick
var touch_camera_surface: TouchCameraSurface
var mobile_ui_layout: MobileUILayout
var mobile_input_router: MobileInputRouter
var fuel_purchase_system: FuelPurchaseSystem
var job_system: JobSystem
var world_events: WorldEventScheduler
var day_night: DayNightManager
var world_clock: WorldClock
var tunis_art_pass: TunisStreetArtPass
var tunis_facade_pass: TunisFacadePass
var visual_readiness: VisualReadinessGate
var tunis_street_detail_pass: TunisStreetDetailPass
var tunis_street_life_pass: TunisStreetLifePass
var tunis_commerce_pass: TunisCommercePass
var tunis_transit_pass: TunisTransitPass
var tunis_urban_utilities_pass: TunisUrbanUtilitiesPass
var tunis_public_realm_pass: TunisPublicRealmPass
var tunis_residential_life_pass: TunisResidentialLifePass
var tunis_road_safety_pass: TunisRoadSafetyPass
var tunis_school_zone_pass: TunisSchoolZonePass
var tunis_neighborhood_identity_pass: TunisNeighborhoodIdentityPass
var tunis_night_life_pass: TunisNightLifePass
var tunis_daily_rhythm_pass: TunisDailyRhythmPass
var tunis_street_shade_pass: TunisStreetShadePass
var tunis_street_sanitation_pass: TunisStreetSanitationPass
var tunis_pedestrian_accessibility_pass: TunisPedestrianAccessibilityPass
var tunis_intersection_signal_pass: TunisIntersectionSignalPass
var autosave_elapsed = 0.0
var player_safety: PlayerSafetySystem
var pause_controller: PauseController
var vertical_slice: VerticalSliceDirector
var vertical_slice_checkpoint: VerticalSliceCheckpoint
var taxi_fare: TaxiFareDirector
var taxi_fare_passenger: Node3D
var taxi_fare_pickup: Node3D
var taxi_fare_dropoff: Node3D

func _ready() -> void:
    _build_environment()
    _build_world_geometry()
    _build_port_shell()
    _build_tunis_art_pass()
    _build_tunis_facade_pass()
    _build_tunis_street_detail_pass()
    _build_tunis_street_life_pass()
    _build_tunis_commerce_pass()
    _build_tunis_transit_pass()
    _build_tunis_urban_utilities_pass()
    _build_tunis_public_realm_pass()
    _build_tunis_residential_life_pass()
    _build_tunis_road_safety_pass()
    _build_tunis_school_zone_pass()
    _build_tunis_neighborhood_identity_pass()
    _build_tunis_night_life_pass()
    _build_tunis_daily_rhythm_pass()
    _build_tunis_street_shade_pass()
    _build_tunis_street_sanitation_pass()
    _build_tunis_pedestrian_accessibility_pass()
    _build_tunis_intersection_signal_pass()
    _build_hero_area()
    _build_runtime()
    _build_world_systems()
    _build_mobile_input_router()
    _build_mobile_layout_manager()
    _build_player()
    _build_player_safety()
    _build_vehicles()
    _build_visual_readiness_gate()
    _build_interactions()
    _build_first_shift_landmarks()
    _build_vertical_slice()
    _build_taxi_fare_landmarks()
    _build_taxi_fare()
    _build_rest_points()
    _build_population()
    _build_adaptive_quality()
    _build_hud()
    _build_pause_controller()
    _build_phone_jobs_panel()
    _build_refuel_popup()
    _build_touch_camera_surface()
    _build_mobile_action_bar()
    _bind_runtime()
    var viewport = get_viewport()
    if viewport and not viewport.size_changed.is_connected(_apply_mobile_layout):
        viewport.size_changed.connect(_apply_mobile_layout)
    _apply_mobile_layout()
    var loaded_extra = SaveService.load_game()
    if typeof(loaded_extra) == TYPE_DICTIONARY:
        var world_state = loaded_extra.get("world_state", {})
        if typeof(world_state) == TYPE_DICTIONARY:
            restore_world_snapshot(world_state)
    RuntimeDiagnostics.record_event("save_loaded", {"source": SaveService.last_load_source, "error": SaveService.last_error, "migration": SaveService.last_migration_source})
    RuntimeDiagnostics.note_world_ready(using_real_osm, _runtime_vehicle_count())

func _process(delta: float) -> void:
    GameState.set_stat("water", GameState.water - delta * 0.13)
    GameState.set_stat("energy", GameState.energy - delta * 0.055)
    _apply_power_state()
    autosave_elapsed += delta
    if autosave_elapsed >= AUTOSAVE_INTERVAL_SECONDS:
        autosave_elapsed = 0.0
        if not save_runtime_state():
            push_warning("AUTOSAVE_FAILED: %s" % SaveService.last_error)

func _mat(color: Color, rough = 0.85, metallic = 0.0) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = rough
    m.metallic = metallic
    return m

func _box(parent: Node, pos: Vector3, size: Vector3, color: Color, collider = true) -> MeshInstance3D:
    var mi = MeshInstance3D.new()
    var mesh = BoxMesh.new()
    mesh.size = size
    mi.mesh = mesh
    mi.position = pos
    mi.material_override = _mat(color)
    parent.add_child(mi)
    if collider:
        var body = StaticBody3D.new()
        var shape = CollisionShape3D.new()
        var box = BoxShape3D.new()
        box.size = size
        shape.shape = box
        body.position = pos
        body.add_child(shape)
        parent.add_child(body)
    return mi

func _cylinder(parent: Node, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
    var mi = MeshInstance3D.new()
    var mesh = CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mi.mesh = mesh
    mi.position = pos
    mi.material_override = _mat(color)
    parent.add_child(mi)
    return mi

func _label3d(parent: Node, text: String, pos: Vector3, size = 0.55) -> Label3D:
    var l = Label3D.new()
    l.text = text
    l.position = pos
    l.font_size = 48
    l.pixel_size = 0.01 * size
    l.outline_size = 8
    l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    parent.add_child(l)
    return l

func _build_environment() -> void:
    var world_env = WorldEnvironment.new()
    world_environment_node = world_env
    var env = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#91b7cf")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#fff0d5")
    env.ambient_light_energy = 0.72
    env.fog_enabled = true
    env.fog_density = 0.0017
    env.fog_light_color = Color("#c9d2d1")
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.environment = env
    add_child(world_env)

    sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -35, 0)
    sun.light_color = Color("#fff0ca")
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 120.0
    add_child(sun)

func _build_world_geometry() -> void:
    osm_world = OsmWorldLoader.new()
    osm_world.name = "OSMWorld"
    add_child(osm_world)
    using_real_osm = osm_world.load_real_map()
    if using_real_osm:
        _build_real_map_support_layer()
    else:
        _build_city_shell()

func _build_real_map_support_layer() -> void:
    _box(self, Vector3(0,-0.6,0), Vector3(1800,1,1800), Color("#c8b99e"), true)
    _make_sign(Vector3(0,5,-10), "وسط تونس — OpenStreetMap")

func _build_city_shell() -> void:
    _box(self, Vector3(0,-0.6,0), Vector3(CITY_SIZE,1,CITY_SIZE), Color("#c8b99e"), true)
    var asphalt = Color("#343536")
    for z in [-60.0, 0.0, 60.0]:
        var road_z = _box(self, Vector3(0,0.03,z), Vector3(CITY_SIZE,0.12,ROAD_W), asphalt, false)
        road_z.material_override = TunisMaterialLibrary.asphalt()
    for xp in [-60.0, 0.0, 60.0]:
        var road_x = _box(self, Vector3(xp,0.04,0), Vector3(ROAD_W,0.13,CITY_SIZE), asphalt, false)
        road_x.material_override = TunisMaterialLibrary.asphalt()

    var blocks = [
        Vector3(-85,0,-85),Vector3(-30,0,-85),Vector3(30,0,-85),Vector3(85,0,-85),
        Vector3(-85,0,-30),Vector3(-30,0,-30),Vector3(30,0,-30),Vector3(85,0,-30),
        Vector3(-85,0,30),Vector3(-30,0,30),Vector3(30,0,30),Vector3(85,0,30),
        Vector3(-85,0,85),Vector3(-30,0,85),Vector3(30,0,85),Vector3(85,0,85)]
    for i in range(blocks.size()):
        _make_building(blocks[i], i)

    for i in range(-5,6):
        _make_palm(Vector3(i*18.0,0,-8.8))
        _make_palm(Vector3(i*18.0,0,8.8))
    for i in range(-5,6,2):
        _make_street_light(Vector3(i*18.0,0,-10.5))
        _make_street_light(Vector3(i*18.0,0,10.5))

    _make_sign(Vector3(-48,4,-68), "قهوة الحومة")
    _make_sign(Vector3(29,4,-68), "ماء معدني")
    _make_sign(Vector3(76,4,-8), "محطة بنزين")
    _make_sign(Vector3(-29,4,52), "مكتب تشغيل")
    _make_sign(Vector3(80,4,52), "طريق حلق الوادي")

func _make_building(center: Vector3, idx: int) -> void:
    var h = 8.0 + float((idx*7)%13)
    var w = 18.0 + float((idx*3)%7)
    var d = 18.0 + float((idx*5)%7)
    var palette = [Color("#d9c5a6"),Color("#c9b08d"),Color("#dfd6c5"),Color("#b7a78c"),Color("#e2cfae")]
    var col: Color = palette[idx % palette.size()]
    var building_body = _box(self, center + Vector3(0,h/2,0), Vector3(w,h,d), col, true)
    building_body.material_override = TunisMaterialLibrary.plaster(col)
    var roof_trim = _box(self, center + Vector3(0,h+0.45,0), Vector3(w+0.5,0.7,d+0.5), col.darkened(0.12), false)
    roof_trim.material_override = TunisMaterialLibrary.plaster(col.darkened(0.12))
    var front_z = center.z - d/2 - 0.03
    for y in range(3, int(h)-1, 3):
        for xo in [-6.0,0.0,6.0]:
            if abs(xo) < w/2-1:
                _box(self, Vector3(center.x+xo,y,front_z), Vector3(2.2,1.5,0.08), Color("#355463"), false)

func _make_palm(pos: Vector3) -> void:
    _cylinder(self, pos+Vector3(0,3.2,0), 0.35, 6.4, Color("#775c3c"))
    for a in range(0,360,45):
        var leaf = _box(self, pos+Vector3(0,6.6,0), Vector3(0.32,0.12,4.5), Color("#315e36"), false)
        leaf.rotation_degrees.y = a
        leaf.rotation_degrees.x = -14

func _make_street_light(pos: Vector3) -> void:
    _cylinder(self,pos+Vector3(0,2.8,0),0.12,5.6,Color("#303234"))
    var light = OmniLight3D.new()
    light.position = pos+Vector3(0,5.3,0)
    light.omni_range = 10
    light.light_energy = 2.2
    light.light_color = Color("#ffd995")
    add_child(light)
    street_lights.append(light)

func _make_sign(pos: Vector3, text: String) -> void:
    _box(self,pos,Vector3(10,2.4,0.35),Color("#272727"),false)
    _label3d(self,text,pos+Vector3(0,0,0.22),0.5)

func _build_tunis_street_detail_pass() -> void:
    if using_real_osm:
        return
    tunis_street_detail_pass = TunisStreetDetailPass.new()
    tunis_street_detail_pass.name = "TunisStreetDetailPass"
    add_child(tunis_street_detail_pass)
    tunis_street_detail_pass.build()

func _build_tunis_street_life_pass() -> void:
    if using_real_osm:
        return
    tunis_street_life_pass = TunisStreetLifePass.new()
    tunis_street_life_pass.name = "TunisStreetLifePass"
    add_child(tunis_street_life_pass)
    tunis_street_life_pass.build()

func _build_tunis_commerce_pass() -> void:
    if using_real_osm:
        return
    tunis_commerce_pass = TunisCommercePass.new()
    tunis_commerce_pass.name = "TunisCommercePass"
    add_child(tunis_commerce_pass)
    tunis_commerce_pass.build()

func _build_tunis_transit_pass() -> void:
    if using_real_osm:
        return
    tunis_transit_pass = TunisTransitPass.new()
    tunis_transit_pass.name = "TunisTransitPass"
    add_child(tunis_transit_pass)
    tunis_transit_pass.build()

func _build_tunis_urban_utilities_pass() -> void:
    if using_real_osm:
        return
    tunis_urban_utilities_pass = TunisUrbanUtilitiesPass.new()
    tunis_urban_utilities_pass.name = "TunisUrbanUtilitiesPass"
    add_child(tunis_urban_utilities_pass)
    tunis_urban_utilities_pass.build()

func _build_tunis_public_realm_pass() -> void:
    if using_real_osm:
        return
    tunis_public_realm_pass = TunisPublicRealmPass.new()
    tunis_public_realm_pass.name = "TunisPublicRealmPass"
    add_child(tunis_public_realm_pass)
    tunis_public_realm_pass.build()

func _build_tunis_residential_life_pass() -> void:
    if using_real_osm:
        return
    tunis_residential_life_pass = TunisResidentialLifePass.new()
    tunis_residential_life_pass.name = "TunisResidentialLifePass"
    add_child(tunis_residential_life_pass)
    tunis_residential_life_pass.build()

func _build_tunis_road_safety_pass() -> void:
    if using_real_osm:
        return
    tunis_road_safety_pass = TunisRoadSafetyPass.new()
    tunis_road_safety_pass.name = "TunisRoadSafetyPass"
    add_child(tunis_road_safety_pass)
    tunis_road_safety_pass.build()

func _build_tunis_school_zone_pass() -> void:
    if using_real_osm:
        return
    tunis_school_zone_pass = TunisSchoolZonePass.new()
    tunis_school_zone_pass.name = "TunisSchoolZonePass"
    add_child(tunis_school_zone_pass)
    tunis_school_zone_pass.build()

func _build_tunis_neighborhood_identity_pass() -> void:
    if using_real_osm:
        return
    tunis_neighborhood_identity_pass = TunisNeighborhoodIdentityPass.new()
    tunis_neighborhood_identity_pass.name = "TunisNeighborhoodIdentityPass"
    add_child(tunis_neighborhood_identity_pass)
    tunis_neighborhood_identity_pass.build()

func _build_tunis_night_life_pass() -> void:
    if using_real_osm:
        return
    tunis_night_life_pass = TunisNightLifePass.new()
    tunis_night_life_pass.name = "TunisNightLifePass"
    add_child(tunis_night_life_pass)
    tunis_night_life_pass.build()

func _build_tunis_daily_rhythm_pass() -> void:
    if using_real_osm:
        return
    tunis_daily_rhythm_pass = TunisDailyRhythmPass.new()
    tunis_daily_rhythm_pass.name = "TunisDailyRhythmPass"
    add_child(tunis_daily_rhythm_pass)
    tunis_daily_rhythm_pass.build()

func _build_tunis_street_shade_pass() -> void:
    if using_real_osm:
        return
    tunis_street_shade_pass = TunisStreetShadePass.new()
    tunis_street_shade_pass.name = "TunisStreetShadePass"
    add_child(tunis_street_shade_pass)
    tunis_street_shade_pass.build()

func _build_tunis_street_sanitation_pass() -> void:
    if using_real_osm:
        return
    tunis_street_sanitation_pass = TunisStreetSanitationPass.new()
    tunis_street_sanitation_pass.name = "TunisStreetSanitationPass"
    add_child(tunis_street_sanitation_pass)
    tunis_street_sanitation_pass.build()

func _build_tunis_pedestrian_accessibility_pass() -> void:
    if using_real_osm:
        return
    tunis_pedestrian_accessibility_pass = TunisPedestrianAccessibilityPass.new()
    tunis_pedestrian_accessibility_pass.name = "TunisPedestrianAccessibilityPass"
    add_child(tunis_pedestrian_accessibility_pass)
    tunis_pedestrian_accessibility_pass.build()


func _build_tunis_intersection_signal_pass() -> void:
    if using_real_osm:
        return
    tunis_intersection_signal_pass = TunisIntersectionSignalPass.new()
    tunis_intersection_signal_pass.name = "TunisIntersectionSignalPass"
    add_child(tunis_intersection_signal_pass)
    tunis_intersection_signal_pass.build()

func _build_tunis_facade_pass() -> void:
    if using_real_osm:
        return
    tunis_facade_pass = TunisFacadePass.new()
    tunis_facade_pass.name = "TunisFacadePass"
    add_child(tunis_facade_pass)
    tunis_facade_pass.build()

func _build_visual_readiness_gate() -> void:
    visual_readiness = VisualReadinessGate.new()
    visual_readiness.name = "VisualReadinessGate"
    add_child(visual_readiness)
    var report = visual_readiness.evaluate(using_real_osm)
    print("VISUAL_READINESS ", report)

func _build_tunis_art_pass() -> void:
    tunis_art_pass = TunisStreetArtPass.new()
    tunis_art_pass.name = "TunisStreetArtPass"
    add_child(tunis_art_pass)
    tunis_art_pass.build(using_real_osm)

func _build_port_shell() -> void:
    _box(self,Vector3(210,-0.45,0),Vector3(180,0.7,220),Color("#2e718f"),false)
    _box(self,Vector3(126,0.25,0),Vector3(16,1.5,220),Color("#8b8277"),true)
    _make_sign(Vector3(123,5,-20),"ميناء حلق الوادي")

func _build_runtime() -> void:
    mission_manager = MissionManager.new()
    mission_manager.name = "MissionManager"
    mission_manager.add_to_group("mission_manager")
    add_child(mission_manager)
    blackout_manager = BlackoutManager.new()
    blackout_manager.name = "BlackoutManager"
    add_child(blackout_manager)

func _build_world_systems() -> void:
    world_clock = WorldClock.new()
    world_clock.name = "WorldClock"
    add_child(world_clock)

    day_night = DayNightManager.new()
    day_night.name = "DayNightManager"
    add_child(day_night)
    day_night.configure(world_clock, sun, world_environment_node)
    if tunis_night_life_pass != null:
        tunis_night_life_pass.configure(world_clock)
    if tunis_daily_rhythm_pass != null:
        tunis_daily_rhythm_pass.configure(world_clock)

    world_events = WorldEventScheduler.new()
    world_events.name = "WorldEventScheduler"
    add_child(world_events)
    world_events.configure(world_clock)
    world_events.event_started.connect(_on_world_event_started)
    world_events.event_ended.connect(_on_world_event_ended)

    economy = EconomyManager.new()
    economy.name = "EconomyManager"
    add_child(economy)
    economy.configure(world_clock)

    job_system = JobSystem.new()
    job_system.name = "JobSystem"
    add_child(job_system)
    job_system.configure(world_clock, economy)

    dynamic_objectives = DynamicObjectiveManager.new()
    dynamic_objectives.name = "DynamicObjectiveManager"
    add_child(dynamic_objectives)
    dynamic_objectives.configure(world_events, job_system)

    rest_system = RestSystem.new()
    rest_system.name = "RestSystem"
    add_child(rest_system)
    rest_system.configure(world_clock)

    fuel_purchase_system = FuelPurchaseSystem.new()
    fuel_purchase_system.name = "FuelPurchaseSystem"
    add_child(fuel_purchase_system)
    dynamic_objectives.bind_rest_system(rest_system)

func _on_world_event_started(id: String, _label_ar: String) -> void:
    match id:
        "blackout":
            GameState.set_blackout(true)
        "fuel_shortage":
            GameState.fuel_shortage = true
        "water_shortage":
            GameState.water_shortage = true

func _on_world_event_ended(id: String) -> void:
    match id:
        "blackout":
            GameState.set_blackout(false)
        "fuel_shortage":
            GameState.fuel_shortage = false
        "water_shortage":
            GameState.water_shortage = false

func _build_mobile_input_router() -> void:
    mobile_input_router = MobileInputRouter.new()
    mobile_input_router.name = "MobileInputRouter"
    add_child(mobile_input_router)

func _build_player() -> void:
    player = PlayerController.new()
    player.name = "Player"
    player.position = Vector3(-52,1.2,18)

    var cs = CollisionShape3D.new()
    var cap = CapsuleShape3D.new()
    cap.radius = 0.45
    cap.height = 1.8
    cs.shape = cap
    cs.position.y = 0.9
    player.add_child(cs)

    var player_visual = PlayerVisualFactory.build()
    player_visual.name = "PlayerVisual"
    player.add_child(player_visual)

    var pivot = Node3D.new()
    pivot.name = "CameraPivot"
    pivot.position = Vector3(0,1.25,0)
    player.add_child(pivot)
    var camera = Camera3D.new()
    camera.name = "Camera3D"
    camera.position = Vector3(0,1.35,4.8)
    camera.rotation_degrees.x = -14
    camera.fov = 62
    pivot.add_child(camera)

    add_child(player)
    player.configure_mobile_input(mobile_input_router)

func _build_player_safety() -> void:
    player_safety = PlayerSafetySystem.new()
    player_safety.name = "PlayerSafetySystem"
    add_child(player_safety)
    player_safety.configure(player)

func _build_vehicles() -> void:
    _make_vehicle(Vector3(-20,1,2),"pickup_01","D-MAX inspired",Color("#e6e4dd"),Vector3(2.2,1.2,5.2))
    _make_vehicle(Vector3(24,1,-57),"pickup_404","404 bâchée inspired",Color("#789278"),Vector3(2.0,1.15,4.8))
    _make_vehicle(Vector3(58,1,24),"louage_01","لواج",Color("#f2f2ec"),Vector3(2.05,1.2,4.5))
    _make_vehicle(Vector3(-58,1,61),"taxi_01","تاكسي تونس",Color("#e6c319"),Vector3(2.0,1.15,4.4))

func _make_vehicle(pos: Vector3, id: String, label: String, body_color: Color, size: Vector3) -> void:
    var v = ArcadeVehicle.new()
    v.name = id
    v.vehicle_id = id
    v.display_name = label
    v.position = pos
    _configure_vehicle_handling(v, id)

    var definition = VehicleVisualCatalog.definition(id)
    var collision_size: Vector3 = definition.get("fallback_size", size)
    var visual = VehicleVisualFactory.build(id)
    visual.name = "VehicleVisual"
    v.add_child(visual)

    var cs = CollisionShape3D.new()
    var sh = BoxShape3D.new()
    sh.size = collision_size
    cs.shape = sh
    cs.position.y = collision_size.y * 0.5
    v.add_child(cs)

    var seat = Marker3D.new()
    seat.name = "DriverSeat"
    seat.position = definition.get("seat_offset", Vector3(-0.45,1.2,-0.2))
    v.add_child(seat)
    var exit_point = Marker3D.new()
    exit_point.name = "ExitPoint"
    exit_point.position = definition.get("exit_offset", Vector3(collision_size.x*0.8,0.7,0))
    v.add_child(exit_point)

    var ia = VehicleInteractable.new()
    ia.name = "Interactable"
    ia.vehicle = v
    ia.prompt_ar = "اركب " + label
    v.add_child(ia)
    ia.add_to_group("interactable")

    add_child(v)
    v.add_to_group("runtime_vehicle")


func _configure_vehicle_handling(vehicle: ArcadeVehicle, id: String) -> void:
    match id:
        "taxi_01":
            vehicle.max_speed = 19.5
            vehicle.max_reverse_speed = 6.0
            vehicle.acceleration = 7.4
            vehicle.braking = 17.0
            vehicle.steering_speed = 1.72
        "louage_01":
            vehicle.max_speed = 18.0
            vehicle.acceleration = 6.3
            vehicle.braking = 15.5
            vehicle.steering_speed = 1.48
        "pickup_404":
            vehicle.max_speed = 17.0
            vehicle.acceleration = 5.8
            vehicle.braking = 14.5
            vehicle.steering_speed = 1.42
        "pickup_01":
            vehicle.max_speed = 20.0
            vehicle.acceleration = 6.8
            vehicle.braking = 16.0
            vehicle.steering_speed = 1.50

func _build_interactions() -> void:
    var water = WaterVendor.new()
    water.position = Vector3(29,0.4,-56)
    water.name = "WaterVendor"
    add_child(water)
    _marker(water,"ماء معدني — 2 د.ت")

    var fuel = FuelStation.new()
    fuel.position = Vector3(76,0.4,-3)
    fuel.name = "FuelStation"
    add_child(fuel)
    fuel.configure(fuel_purchase_system)
    fuel.refuel_requested.connect(_on_refuel_requested)
    _marker(fuel,"الإيصنص — 5 د.ت")

    var job = JobBoard.new()
    job.position = Vector3(-29,0.4,58)
    job.name = "JobBoard"
    add_child(job)
    job.configure(job_system)
    _marker(job,"خدمة")

    var port = PortGate.new()
    port.position = Vector3(109,0.4,0)
    port.name = "PortGate"
    add_child(port)
    _marker(port,"الميناء")


func _build_first_shift_landmarks() -> void:
    # Local vertical-slice landmarks make each objective readable without external assets.
    var slice_root = Node3D.new()
    slice_root.name = "FirstShiftLandmarks"
    add_child(slice_root)

    # Water kiosk around the existing vendor.
    _box(slice_root, Vector3(29, 1.25, -59), Vector3(7.5, 2.5, 3.0), Color("#e9e1cb"), false)
    _box(slice_root, Vector3(29, 2.65, -59), Vector3(8.2, 0.25, 3.6), Color("#1f6b8a"), false)
    _label3d(slice_root, "ماء · EAU", Vector3(29, 2.0, -57.42), 0.46)

    # Taxi stand: curb, yellow/black bollards and a readable TAXI sign.
    _box(slice_root, Vector3(-58, 0.16, 64.5), Vector3(10.0, 0.3, 2.2), Color("#d7d1bf"), false)
    _box(slice_root, Vector3(-58, 2.45, 66.0), Vector3(5.8, 1.2, 0.28), Color("#e5c315"), false)
    _label3d(slice_root, "TAXI · تاكسي", Vector3(-58, 2.45, 65.82), 0.5)
    for x in [-62.0, -60.0, -56.0, -54.0]:
        _cylinder(slice_root, Vector3(x, 0.55, 63.3), 0.13, 1.1, Color("#202124"))

    # Job office frontage.
    _box(slice_root, Vector3(-29, 2.0, 61.5), Vector3(9.0, 4.0, 3.0), Color("#c7b08b"), false)
    _box(slice_root, Vector3(-29, 2.8, 59.94), Vector3(7.2, 1.0, 0.18), Color("#2f5d62"), false)
    _label3d(slice_root, "مكتب التشغيل · EMPLOI", Vector3(-29, 2.8, 59.82), 0.38)

    # Port delivery gate with two pylons and overhead header.
    for x in [96.0, 106.0]:
        _box(slice_root, Vector3(x, 2.4, 34), Vector3(1.0, 4.8, 1.0), Color("#b7b8b2"), false)
    _box(slice_root, Vector3(101, 5.0, 34), Vector3(11.0, 0.8, 1.0), Color("#294b57"), false)
    _label3d(slice_root, "PORT DE TUNIS · ميناء تونس", Vector3(101, 5.0, 33.45), 0.4)
    _box(slice_root, Vector3(101, 0.06, 34), Vector3(13.0, 0.12, 8.0), Color("#c6a83d"), false)

func _build_vertical_slice() -> void:
    vertical_slice_checkpoint = VerticalSliceCheckpoint.new()
    vertical_slice_checkpoint.name = "FirstShiftPortDropoff"
    vertical_slice_checkpoint.checkpoint_id = "first_shift_port_dropoff"
    vertical_slice_checkpoint.prompt_ar = "سلّم المشوار في الميناء"
    vertical_slice_checkpoint.position = Vector3(101, 0.4, 34)
    add_child(vertical_slice_checkpoint)
    _marker(vertical_slice_checkpoint, "تسليم المشوار · FIRST SHIFT")

    vertical_slice = VerticalSliceDirector.new()
    vertical_slice.name = "VerticalSliceDirector"
    add_child(vertical_slice)
    var water = get_node_or_null("WaterVendor") as WaterVendor
    var taxi = get_node_or_null("taxi_01") as ArcadeVehicle
    var job = get_node_or_null("JobBoard") as JobBoard
    vertical_slice.configure(water, taxi, job, vertical_slice_checkpoint, player)

func _build_taxi_fare_landmarks() -> void:
    var root = Node3D.new()
    root.name = "TaxiFareLandmarks"
    add_child(root)
    _box(root, Vector3(65, 0.14, 21), Vector3(9.0, 0.28, 2.0), Color("#d0c7b2"), false)
    _box(root, Vector3(65, 2.45, 23.0), Vector3(6.6, 0.85, 0.24), Color("#2d665b"), false)
    _label3d(root, "BAB ALIOUA · باب عليوة", Vector3(65, 2.45, 22.84), 0.38)
    for x in [-10.0, -2.0]:
        _box(root, Vector3(x, 2.5, 10), Vector3(1.2, 5.0, 1.2), Color("#d8c7a3"), false)
    _box(root, Vector3(-6, 4.65, 10), Vector3(9.2, 0.9, 1.2), Color("#c6b48c"), false)
    _label3d(root, "BAB BHAR · باب البحر", Vector3(-6, 5.35, 9.36), 0.42)
    _box(root, Vector3(28, 1.55, 12), Vector3(7.0, 3.1, 3.0), Color("#b98b58"), false)
    _label3d(root, "سوق · MARCHÉ", Vector3(28, 2.45, 10.44), 0.38)
    _box(root, Vector3(46, 1.8, 30), Vector3(5.8, 3.6, 2.2), Color("#456a72"), false)
    _label3d(root, "محطة · ARRÊT", Vector3(46, 2.5, 28.84), 0.38)
    taxi_fare_pickup = Node3D.new()
    taxi_fare_pickup.name = "TaxiFarePickup"
    taxi_fare_pickup.position = Vector3(65, 0.4, 20)
    add_child(taxi_fare_pickup)
    _marker(taxi_fare_pickup, "راكب · PASSAGER")
    taxi_fare_dropoff = Node3D.new()
    taxi_fare_dropoff.name = "TaxiFareDropoff"
    taxi_fare_dropoff.position = Vector3(-6, 0.4, 8)
    add_child(taxi_fare_dropoff)
    _marker(taxi_fare_dropoff, "توصيل · BAB BHAR")
    taxi_fare_passenger = Node3D.new()
    taxi_fare_passenger.name = "TaxiFarePassenger"
    taxi_fare_passenger.position = taxi_fare_pickup.position + Vector3(0, 0, 1.5)
    taxi_fare_passenger.add_child(PlayerVisualFactory.build())
    taxi_fare_passenger.visible = false
    add_child(taxi_fare_passenger)

func _build_taxi_fare() -> void:
    var taxi = get_node_or_null("taxi_01") as ArcadeVehicle
    taxi_fare = TaxiFareDirector.new()
    taxi_fare.name = "TaxiFareDirector"
    add_child(taxi_fare)
    var fuel_station = get_node_or_null("FuelStation") as Node3D
    taxi_fare.configure(taxi, taxi_fare_passenger, taxi_fare_pickup, taxi_fare_dropoff, player, fuel_purchase_system, fuel_station)
    taxi_fare.objective_changed.connect(_on_taxi_fare_objective)
    if vertical_slice != null:
        vertical_slice.slice_completed.connect(_on_first_shift_completed)
        if vertical_slice.is_completed():
            taxi_fare.activate()

func _on_first_shift_completed() -> void:
    if taxi_fare != null:
        taxi_fare.activate()

func _on_taxi_fare_objective(text: String) -> void:
    if text.is_empty() or hud == null:
        return
    var label = hud.get_node_or_null("SliceObjective") as Label
    if label:
        label.text = text

func _marker(parent: Node3D, text: String) -> void:
    var ring = MeshInstance3D.new()
    var tm = TorusMesh.new()
    tm.inner_radius = 1.0
    tm.outer_radius = 1.28
    ring.mesh = tm
    ring.rotation_degrees.x = 90
    ring.material_override = _mat(Color("#e9b949"),0.35,0.1)
    parent.add_child(ring)
    _label3d(parent,text,Vector3(0,2.4,0),0.4)


func _build_rest_points() -> void:
    var bench = RestBench.new()
    bench.name = "RestBench"
    bench.position = Vector3(-8, 0.4, 18)
    add_child(bench)
    bench.configure(rest_system)
    _marker(bench, "استراحة")

    var sleep_spot = SleepSpot.new()
    sleep_spot.name = "SleepSpot"
    sleep_spot.position = Vector3(-72, 0.4, 78)
    add_child(sleep_spot)
    sleep_spot.configure(rest_system)
    _marker(sleep_spot, "رقاد")

func _build_population() -> void:
    quality = QualityManager.new()
    quality.name = "QualityManager"
    add_child(quality)
    traffic_coordinator = TrafficCoordinator.new()
    traffic_coordinator.name = "TrafficCoordinator"
    add_child(traffic_coordinator)

    population = PopulationSpawner.new()
    population.name = "Population"
    population.pedestrian_count = 24
    population.traffic_count = 10
    add_child(population)
    if using_real_osm:
        road_graph = RoadGraph.new()
        if road_graph.load_from_processed_map("res://data/osm/tunis_bourguiba_processed.json"):
            population.configure_road_graph(road_graph)
            traffic_coordinator.configure_from_road_graph(road_graph)
    population.configure_traffic_coordinator(traffic_coordinator)
    population.spawn_all()

func _build_adaptive_quality() -> void:
    adaptive_quality = AdaptiveQualityManager.new()
    adaptive_quality.name = "AdaptiveQualityManager"
    add_child(adaptive_quality)

func _build_hud() -> void:
    hud = GameHUD.new()
    hud.name = "HUD"

    var margin = MarginContainer.new()
    margin.name = "Margin"
    margin.offset_left = 24
    margin.offset_top = 18
    margin.offset_right = 360
    margin.offset_bottom = 160
    hud.add_child(margin)
    var vb = VBoxContainer.new()
    vb.name = "VBox"
    margin.add_child(vb)
    var title = Label.new()
    title.text = "حياة تونس"
    title.add_theme_font_size_override("font_size",28)
    vb.add_child(title)
    var stats = Label.new()
    stats.name = "Stats"
    stats.add_theme_font_size_override("font_size",16)
    vb.add_child(stats)

    var objective = Label.new()
    objective.name = "Objective"
    objective.position = Vector2(790,24)
    objective.size = Vector2(450,50)
    objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    objective.add_theme_font_size_override("font_size",18)
    hud.add_child(objective)

    var slice_objective = Label.new()
    slice_objective.name = "SliceObjective"
    slice_objective.position = Vector2(710,72)
    slice_objective.size = Vector2(530,42)
    slice_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    slice_objective.add_theme_font_size_override("font_size",16)
    slice_objective.text = vertical_slice.current_objective() if vertical_slice else ""
    hud.add_child(slice_objective)
    if vertical_slice and not vertical_slice.objective_changed.is_connected(_on_vertical_slice_objective):
        vertical_slice.objective_changed.connect(_on_vertical_slice_objective)

    var prompt = Label.new()
    prompt.name = "Prompt"
    prompt.position = Vector2(430,610)
    prompt.size = Vector2(420,45)
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.add_theme_font_size_override("font_size",20)
    hud.add_child(prompt)

    var blackout = ColorRect.new()
    blackout.name = "Blackout"
    blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    blackout.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(blackout)

    # Add the completed HUD tree only after all @onready targets exist.
    # This prevents GameHUD._ready() from caching null labels when the HUD is built procedurally.
    add_child(hud)


func _on_vertical_slice_objective(text: String) -> void:
    if hud == null:
        return
    var label = hud.get_node_or_null("SliceObjective") as Label
    if label:
        label.text = text

func _build_pause_controller() -> void:
    pause_controller = PauseController.new()
    pause_controller.name = "PauseController"
    hud.add_child(pause_controller)
    pause_controller.save_requested.connect(_on_pause_save_requested)
    pause_controller.unstuck_requested.connect(_on_pause_unstuck_requested)
    pause_controller.pause_changed.connect(_on_pause_changed)

func _on_pause_save_requested() -> void:
    var ok = save_runtime_state()
    if pause_controller:
        pause_controller.set_status("تم الحفظ" if ok else "فشل الحفظ: %s" % SaveService.last_error)

func _on_pause_unstuck_requested() -> void:
    var ok = false
    if player_safety:
        ok = player_safety.force_unstuck()
    if pause_controller:
        pause_controller.set_status("تمت الإعادة لمكان آمن" if ok else "تعذر العثور على موقع آمن")

func _on_pause_changed(paused: bool, reason: String) -> void:
    RuntimeDiagnostics.record_event("game_paused" if paused else "game_resumed", {"reason": reason})
    RuntimeDiagnostics.write_health_snapshot("game_paused" if paused else "game_resumed")

func _build_phone_jobs_panel() -> void:
    phone_jobs_panel = PhoneJobsPanel.new()
    phone_jobs_panel.name = "PhoneJobsPanel"
    phone_jobs_panel.visible = false

    var panel = Panel.new()
    panel.name = "Panel"
    panel.position = Vector2(760, 95)
    panel.size = Vector2(390, 500)
    phone_jobs_panel.add_child(panel)

    var margin = MarginContainer.new()
    margin.name = "Margin"
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_bottom", 20)
    panel.add_child(margin)

    var vbox = VBoxContainer.new()
    vbox.name = "VBox"
    margin.add_child(vbox)

    var title = Label.new()
    title.name = "Title"
    title.text = "الهاتف — فرص الخدمة"
    title.add_theme_font_size_override("font_size", 22)
    vbox.add_child(title)

    var offers = VBoxContainer.new()
    offers.name = "Offers"
    vbox.add_child(offers)

    var status = Label.new()
    status.name = "Status"
    status.text = ""
    status.add_theme_font_size_override("font_size", 16)
    vbox.add_child(status)

    hud.add_child(phone_jobs_panel)
    phone_jobs_panel.configure(job_system)

func _build_mobile_layout_manager() -> void:
    mobile_ui_layout = MobileUILayout.new()
    mobile_ui_layout.name = "MobileUILayout"
    add_child(mobile_ui_layout)

func _build_touch_camera_surface() -> void:
    touch_camera_surface = TouchCameraSurface.new()
    touch_camera_surface.name = "TouchCameraSurface"
    touch_camera_surface.position = Vector2(260, 120)
    touch_camera_surface.size = Vector2(690, 410)
    hud.add_child(touch_camera_surface)
    touch_camera_surface.camera_drag.connect(player.apply_mobile_camera_drag)
    player.set_mobile_camera_sensitivity(SettingsService.camera_sensitivity())
    if not SettingsService.camera_sensitivity_changed.is_connected(player.set_mobile_camera_sensitivity):
        SettingsService.camera_sensitivity_changed.connect(player.set_mobile_camera_sensitivity)

func _build_refuel_popup() -> void:
    refuel_popup = RefuelPopup.new()
    refuel_popup.name = "RefuelPopup"
    refuel_popup.visible = false

    var panel = Panel.new()
    panel.name = "Panel"
    panel.position = Vector2(410, 120)
    panel.size = Vector2(460, 470)
    refuel_popup.add_child(panel)

    var margin = MarginContainer.new()
    margin.name = "Margin"
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.add_child(margin)

    var vbox = VBoxContainer.new()
    vbox.name = "VBox"
    margin.add_child(vbox)

    var title = Label.new()
    title.name = "Title"
    title.text = "تعبئة الإيصنص"
    vbox.add_child(title)

    var status = Label.new()
    status.name = "Status"
    vbox.add_child(status)

    var buttons = VBoxContainer.new()
    buttons.name = "Buttons"
    vbox.add_child(buttons)

    hud.add_child(refuel_popup)
    refuel_popup.configure(fuel_purchase_system)

func _on_refuel_requested() -> void:
    if refuel_popup:
        refuel_popup.open_popup()

func _build_mobile_action_bar() -> void:
    mobile_action_bar = MobileActionBar.new()
    mobile_action_bar.name = "MobileActionBar"

    var phone_button = Button.new()
    phone_button.name = "PhoneButton"
    phone_button.text = "هاتف"
    phone_button.position = Vector2(28, 560)
    phone_button.size = Vector2(150, 58)
    mobile_action_bar.add_child(phone_button)

    var interact_button = Button.new()
    interact_button.name = "InteractButton"
    interact_button.text = "تفاعل"
    interact_button.position = Vector2(990, 560)
    interact_button.size = Vector2(150, 58)
    mobile_action_bar.add_child(interact_button)

    var pause_button = Button.new()
    pause_button.name = "PauseButton"
    pause_button.text = "توقف"
    pause_button.position = Vector2(1148, 24)
    pause_button.size = Vector2(100, 52)
    mobile_action_bar.add_child(pause_button)

    hud.add_child(mobile_action_bar)
    mobile_action_bar.phone_pressed.connect(_on_mobile_phone_pressed)
    mobile_action_bar.interact_pressed.connect(_on_mobile_interact_pressed)
    mobile_action_bar.pause_pressed.connect(_on_mobile_pause_pressed)


    var joystick_script = load("res://scripts/ui/mobile/VirtualJoystick.gd")
    if joystick_script == null:
        push_error("MOBILE_INPUT: failed to load VirtualJoystick.gd")
        return
    virtual_joystick = joystick_script.new()
    if virtual_joystick == null:
        push_error("MOBILE_INPUT: failed to instantiate VirtualJoystick.gd")
        return
    virtual_joystick.name = "VirtualJoystick"
    virtual_joystick.position = Vector2(35, 400)
    virtual_joystick.size = Vector2(180, 180)

    # Build required children before entering the SceneTree. VirtualJoystick resolves
    # its Knob in @onready, so adding the joystick first would permanently cache null.
    var joystick_knob = Control.new()
    joystick_knob.name = "Knob"
    joystick_knob.size = Vector2(54, 54)
    virtual_joystick.add_child(joystick_knob)
    hud.add_child(virtual_joystick)

    virtual_joystick.vector_changed.connect(mobile_input_router.set_move_vector)

    var sprint_button = Button.new()
    sprint_button.name = "SprintButton"
    sprint_button.text = "اجري"
    sprint_button.position = Vector2(820, 560)
    sprint_button.size = Vector2(150, 58)
    hud.add_child(sprint_button)
    sprint_button.button_down.connect(func(): mobile_input_router.set_sprint_pressed(true))
    sprint_button.button_up.connect(func(): mobile_input_router.set_sprint_pressed(false))

func _on_mobile_phone_pressed() -> void:
    if phone_jobs_panel:
        phone_jobs_panel.toggle_phone()

func _on_mobile_interact_pressed() -> void:
    if player:
        player.request_interact()

func _on_mobile_pause_pressed() -> void:
    if pause_controller:
        pause_controller.toggle_pause()

func _bind_runtime() -> void:
    if tunis_intersection_signal_pass != null and traffic_coordinator != null:
        tunis_intersection_signal_pass.configure(traffic_coordinator)
    hud.bind_clock(world_clock)
    hud.bind_player(player)
    hud.bind_missions(mission_manager)
    hud.bind_dynamic_objectives(dynamic_objectives)

func _apply_power_state() -> void:
    for l in street_lights:
        l.visible = not GameState.blackout_active
    if sun:
        sun.light_energy = 0.45 if GameState.blackout_active else 1.25


func build_world_snapshot() -> Dictionary:
    var vehicle_states = {}
    for child in get_children():
        if child is ArcadeVehicle:
            var vehicle = child as ArcadeVehicle
            vehicle_states[vehicle.vehicle_id] = vehicle.serialize_runtime()
    return {
        "clock": world_clock.serialize() if world_clock else {},
        "events": world_events.serialize() if world_events else {},
        "jobs": job_system.serialize() if job_system else {},
        "player": player.serialize_runtime() if player else {},
        "vehicles": vehicle_states,
        "active_vehicle_id": GameState.current_vehicle_id,
        "vertical_slice": vertical_slice.serialize_runtime() if vertical_slice else {},
        "taxi_fare": taxi_fare.serialize_runtime() if taxi_fare else {}
    }

func restore_world_snapshot(data: Dictionary) -> void:
    if world_clock and typeof(data.get("clock", {})) == TYPE_DICTIONARY:
        world_clock.restore(data.get("clock", {}))
    if world_events and typeof(data.get("events", {})) == TYPE_DICTIONARY:
        world_events.restore(data.get("events", {}))
    if job_system and typeof(data.get("jobs", {})) == TYPE_DICTIONARY:
        job_system.restore(data.get("jobs", {}))

    var vehicle_states = data.get("vehicles", {})
    if typeof(vehicle_states) == TYPE_DICTIONARY:
        for child in get_children():
            if child is ArcadeVehicle:
                var vehicle = child as ArcadeVehicle
                var vehicle_state = vehicle_states.get(vehicle.vehicle_id, {})
                if typeof(vehicle_state) == TYPE_DICTIONARY:
                    vehicle.restore_runtime(vehicle_state)

    var player_state = data.get("player", {})
    if player and typeof(player_state) == TYPE_DICTIONARY:
        player.restore_runtime(player_state)

    var slice_state = data.get("vertical_slice", {})
    if vertical_slice and typeof(slice_state) == TYPE_DICTIONARY:
        vertical_slice.restore_runtime(slice_state)
    var fare_state = data.get("taxi_fare", {})
    if taxi_fare and typeof(fare_state) == TYPE_DICTIONARY and not fare_state.is_empty():
        taxi_fare.restore_runtime(fare_state)
    elif taxi_fare and vertical_slice and vertical_slice.is_completed():
        taxi_fare.activate()
    _restore_active_vehicle(str(data.get("active_vehicle_id", GameState.current_vehicle_id)))

func _restore_active_vehicle(vehicle_id: String) -> void:
    if player == null:
        return
    if vehicle_id.is_empty():
        GameState.current_vehicle_id = ""
        player.visible = true
        player.set_control_enabled(true)
        return

    for child in get_children():
        if child is ArcadeVehicle:
            var vehicle = child as ArcadeVehicle
            if vehicle.vehicle_id == vehicle_id:
                if vehicle.driver == null:
                    vehicle.enter_vehicle(player)
                player.global_position = vehicle.seat.global_position
                player.global_rotation.y = vehicle.global_rotation.y
                return

    # The saved vehicle may have been removed in a later content version.
    # Fail safe to on-foot control instead of leaving a stale vehicle id.
    GameState.current_vehicle_id = ""
    player.visible = true
    player.set_control_enabled(true)

func save_runtime_state() -> bool:
    var ok = SaveService.save_game({"world_state": build_world_snapshot()})
    RuntimeDiagnostics.note_save_result(ok, "ok" if ok else SaveService.last_error)
    return ok

func _runtime_vehicle_count() -> int:
    var count = 0
    for child in get_children():
        if child is ArcadeVehicle:
            count += 1
    return count


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("phone_jobs"):
        if phone_jobs_panel:
            phone_jobs_panel.toggle_phone()


func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED:
        save_runtime_state()
        if pause_controller and not pause_controller.is_game_paused():
            pause_controller.pause_game("application_background")
    elif what == NOTIFICATION_APPLICATION_RESUMED:
        if pause_controller and pause_controller.is_game_paused():
            pause_controller.set_status("رجع التطبيق — اضغط واصل اللعب")
    elif what == NOTIFICATION_WM_CLOSE_REQUEST:
        save_runtime_state()

func _apply_mobile_layout() -> void:
    if mobile_ui_layout == null:
        return
    if mobile_action_bar:
        mobile_ui_layout.layout_root(mobile_action_bar)
    if virtual_joystick:
        mobile_ui_layout.layout_root(virtual_joystick)
    if touch_camera_surface:
        var safe = mobile_ui_layout.safe_rect(get_viewport())
        touch_camera_surface.position = Vector2(
            safe.position.x + safe.size.x * 0.20,
            safe.position.y + safe.size.y * 0.12
        )
        touch_camera_surface.size = Vector2(
            safe.size.x * 0.58,
            safe.size.y * 0.58
        )

func _build_hero_area() -> void:
    # Historical passes remain available to their contract tests, but their
    # overlapping art is retired from the production scene.
    for child in get_children():
        if child is Node3D and child.name.begins_with("Tunis"):
            child.visible = false
    var hero := BourguibaHeroArea.new()
    add_child(hero)
    hero.build()
    if osm_world != null:
        for child in osm_world.get_children():
            if child is MeshInstance3D:
                var bounds: AABB = child.get_aabb()
                var centre: Vector3 = child.position + bounds.get_center()
                if BourguibaHeroArea.contains_world(centre):
                    child.visible = false
