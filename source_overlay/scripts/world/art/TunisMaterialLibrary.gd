extends RefCounted
class_name TunisMaterialLibrary

const PLASTER_SHADER := preload("res://shaders/tunis_plaster.gdshader")
const ASPHALT_SHADER := preload("res://shaders/tunis_asphalt.gdshader")

static func plaster(color: Color) -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = PLASTER_SHADER
    material.set_shader_parameter("base_color", color)
    material.set_shader_parameter("dirt_strength", 0.15)
    return material

static func asphalt() -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = ASPHALT_SHADER
    return material

static func stone(color: Color = Color("#c8b99e")) -> StandardMaterial3D:
    return _standard(color, 0.92, 0.0)

static func metal(color: Color = Color("#373b3d")) -> StandardMaterial3D:
    return _standard(color, 0.56, 0.28)

static func wood(color: Color = Color("#6c4b35")) -> StandardMaterial3D:
    return _standard(color, 0.78, 0.0)

static func pavement(color: Color = Color("#bdb4a4")) -> StandardMaterial3D:
    return _standard(color, 0.96, 0.0)

static func fabric(color: Color) -> StandardMaterial3D:
    return _standard(color, 0.98, 0.0)

static func glass_tinted() -> StandardMaterial3D:
    var material := _standard(Color(0.14, 0.23, 0.28, 0.72), 0.18, 0.04)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return material

static func mobile_contract() -> Dictionary:
    return {
        "texture_budget_bytes": 0,
        "uses_runtime_textures": false,
        "material_types": ["plaster", "stone", "glass", "metal", "wood", "pavement", "fabric", "asphalt"],
        "max_transparent_layers": 1,
        "target": "mobile",
    }

static func _standard(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = clampf(roughness, 0.0, 1.0)
    material.metallic = clampf(metallic, 0.0, 1.0)
    return material
