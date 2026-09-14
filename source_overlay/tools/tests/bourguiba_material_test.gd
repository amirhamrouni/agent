extends SceneTree

const FacadePass = preload("res://scripts/world/art/TunisFacadePass.gd")
const MaterialLibrary = preload("res://scripts/world/art/TunisMaterialLibrary.gd")

const REQUIRED_MATERIALS := ["plaster", "stone", "glass", "metal", "wood", "fabric"]
const CONTRACT_TYPES := ["plaster", "stone", "glass", "metal", "wood", "pavement", "fabric", "asphalt"]

func _initialize() -> void:
    var environment := FacadePass.new()
    root.add_child(environment)
    environment.build()

    var summary: Dictionary = environment.get_runtime_summary()
    var usage: Dictionary = summary.get("material_usage", {})
    var contract: Dictionary = summary.get("mobile_material_contract", {})

    for material_name in REQUIRED_MATERIALS:
        var count := int(usage.get(material_name, 0))
        if count <= 0:
            push_error("BOURGUIBA_MATERIAL_USAGE_MISSING:%s" % material_name)
            quit(60)
            return

    if int(usage.get("plaster", 0)) != int(summary.get("facade_count", 0)):
        push_error("BOURGUIBA_MATERIAL_PLASTER_FACADE_MISMATCH plaster=%d facades=%d" % [
            int(usage.get("plaster", 0)), int(summary.get("facade_count", 0))
        ])
        quit(61)
        return

    if bool(contract.get("uses_runtime_textures", true)):
        push_error("BOURGUIBA_MATERIAL_RUNTIME_TEXTURES_FORBIDDEN")
        quit(62)
        return
    if int(contract.get("texture_budget_bytes", -1)) != 0:
        push_error("BOURGUIBA_MATERIAL_TEXTURE_BUDGET_INVALID:%d" % int(contract.get("texture_budget_bytes", -1)))
        quit(63)
        return
    if int(contract.get("max_transparent_layers", 0)) > 1:
        push_error("BOURGUIBA_MATERIAL_TRANSPARENCY_BUDGET_EXCEEDED:%d" % int(contract.get("max_transparent_layers", 0)))
        quit(64)
        return
    if String(contract.get("target", "")) != "mobile":
        push_error("BOURGUIBA_MATERIAL_TARGET_INVALID:%s" % String(contract.get("target", "")))
        quit(65)
        return

    var types_variant = contract.get("material_types", [])
    if not (types_variant is Array):
        push_error("BOURGUIBA_MATERIAL_TYPES_INVALID")
        quit(66)
        return
    var types: Array = types_variant
    for material_name in CONTRACT_TYPES:
        if not types.has(material_name):
            push_error("BOURGUIBA_MATERIAL_CONTRACT_TYPE_MISSING:%s" % material_name)
            quit(67)
            return

    var plaster_sample = MaterialLibrary.plaster(Color("#d9c9ae"))
    var asphalt_sample = MaterialLibrary.asphalt()
    var glass_sample = MaterialLibrary.glass_tinted()
    if not (plaster_sample is ShaderMaterial) or plaster_sample.shader == null:
        push_error("BOURGUIBA_MATERIAL_PLASTER_SHADER_INVALID")
        quit(68)
        return
    if not (asphalt_sample is ShaderMaterial) or asphalt_sample.shader == null:
        push_error("BOURGUIBA_MATERIAL_ASPHALT_SHADER_INVALID")
        quit(69)
        return
    if not (glass_sample is StandardMaterial3D) or glass_sample.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA:
        push_error("BOURGUIBA_MATERIAL_GLASS_CONTRACT_INVALID")
        quit(70)
        return

    print("BOURGUIBA_MATERIAL_GATE_PASS facades=%d plaster=%d stone=%d glass=%d metal=%d wood=%d fabric=%d runtime_textures=%s texture_budget=%d transparent_layers=%d" % [
        int(summary.get("facade_count", 0)),
        int(usage.get("plaster", 0)), int(usage.get("stone", 0)), int(usage.get("glass", 0)),
        int(usage.get("metal", 0)), int(usage.get("wood", 0)), int(usage.get("fabric", 0)),
        str(contract.get("uses_runtime_textures", true)), int(contract.get("texture_budget_bytes", -1)),
        int(contract.get("max_transparent_layers", 0))
    ])
    quit(0)
