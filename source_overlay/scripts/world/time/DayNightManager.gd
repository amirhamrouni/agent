extends Node
class_name DayNightManager

var world_clock: WorldClock
var sun: DirectionalLight3D
var world_environment: WorldEnvironment

func configure(clock: WorldClock, sun_light: DirectionalLight3D, environment_node: WorldEnvironment) -> void:
    world_clock = clock
    sun = sun_light
    world_environment = environment_node
    if world_clock and not world_clock.minute_changed.is_connected(_on_minute_changed):
        world_clock.minute_changed.connect(_on_minute_changed)
    _apply_time_state()

func _on_minute_changed(_day: int, _hour: int, _minute: int) -> void:
    _apply_time_state()

func _apply_time_state() -> void:
    if world_clock == null or sun == null:
        return
    var hours: float = float(world_clock.current_hour()) + float(world_clock.current_minute()) / 60.0
    var daylight: float = clampf(sin(((hours - 6.0) / 12.0) * PI), 0.0, 1.0)
    sun.rotation_degrees.x = lerpf(-8.0, -62.0, daylight)

    # Physical-device calibrated curve: enough fill for shaded shopfronts and
    # characters, while ACES keeps bright Tunisian stone below clipping.
    var sun_energy := 0.03
    var ambient_energy := 0.08
    if daylight > 0.01:
        sun_energy = lerpf(0.50, 0.82, daylight)
        ambient_energy = lerpf(0.28, 0.42, daylight)
    sun.light_energy = sun_energy
    sun.light_color = Color("#f1d4a4")

    if world_environment and world_environment.environment:
        world_environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
        world_environment.environment.ambient_light_color = Color("#aeb8bb")
        world_environment.environment.ambient_light_energy = ambient_energy
        world_environment.environment.fog_enabled = false
        world_environment.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
