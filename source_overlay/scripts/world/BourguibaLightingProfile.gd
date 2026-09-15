extends RefCounted
class_name BourguibaLightingProfile

const PROFILES := {
    "LOW": {
        "ambient_energy": 0.16,
        "fog_enabled": false,
        "fog_density": 0.0,
        "sun_energy": 0.50,
        "shadows": false,
        "shadow_distance": 0.0,
        "reflection_budget": 0
    },
    "MEDIUM": {
        "ambient_energy": 0.22,
        "fog_enabled": false,
        "fog_density": 0.0,
        "sun_energy": 0.62,
        "shadows": true,
        "shadow_distance": 72.0,
        "reflection_budget": 1
    },
    "HIGH": {
        "ambient_energy": 0.26,
        "fog_enabled": true,
        "fog_density": 0.00035,
        "sun_energy": 0.72,
        "shadows": true,
        "shadow_distance": 112.0,
        "reflection_budget": 2
    }
}

static func resolved_mode(requested: String, mobile: bool = true) -> String:
    var mode := requested.to_upper()
    if mode == "AUTO":
        return "MEDIUM" if mobile else "HIGH"
    if not PROFILES.has(mode):
        return "LOW"
    return mode

static func profile(requested: String, mobile: bool = true) -> Dictionary:
    return PROFILES[resolved_mode(requested, mobile)].duplicate(true)

static func apply(environment: Environment, sun: DirectionalLight3D, requested: String, mobile: bool = true) -> Dictionary:
    var mode := resolved_mode(requested, mobile)
    var p: Dictionary = PROFILES[mode]
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#668ca8")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#9eabb0")
    environment.ambient_light_energy = float(p.ambient_energy)
    environment.fog_enabled = bool(p.fog_enabled)
    environment.fog_density = float(p.fog_density)
    environment.fog_light_color = Color("#9faeb3")
    environment.tonemap_mode = Environment.TONE_MAPPER_ACES
    sun.light_color = Color("#f1d4a4")
    sun.light_energy = float(p.sun_energy)
    sun.shadow_enabled = bool(p.shadows)
    sun.directional_shadow_max_distance = float(p.shadow_distance)
    return {"mode": mode, "reflection_budget": int(p.reflection_budget)}
