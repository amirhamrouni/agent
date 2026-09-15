extends Node

func _ready() -> void:
    var env := Environment.new()
    var sun := DirectionalLight3D.new()
    for mode in ["LOW", "MEDIUM", "HIGH", "AUTO"]:
        var result := BourguibaLightingProfile.apply(env, sun, mode, true)
        var resolved := str(result.get("mode", ""))
        if resolved not in ["LOW", "MEDIUM", "HIGH"]:
            _fail("BOURGUIBA_LIGHTING_MODE_INVALID:%s" % resolved)
            return
        var p := BourguibaLightingProfile.profile(mode, true)
        if env.ambient_light_energy < 0.14 or env.ambient_light_energy > 0.30:
            _fail("BOURGUIBA_LIGHTING_AMBIENT_INVALID:%s" % env.ambient_light_energy)
            return
        if sun.light_energy < 0.45 or sun.light_energy > 0.76:
            _fail("BOURGUIBA_LIGHTING_SUN_INVALID:%s" % sun.light_energy)
            return
        if bool(p.shadows) != sun.shadow_enabled:
            _fail("BOURGUIBA_LIGHTING_SHADOW_INVALID:%s" % mode)
            return
        if resolved == "LOW" and (env.fog_enabled or sun.shadow_enabled or int(result.reflection_budget) != 0):
            _fail("BOURGUIBA_LIGHTING_LOW_BUDGET_INVALID")
            return
        if resolved == "HIGH" and (not env.fog_enabled or not sun.shadow_enabled or sun.directional_shadow_max_distance < 100.0):
            _fail("BOURGUIBA_LIGHTING_HIGH_BUDGET_INVALID")
            return
    if BourguibaLightingProfile.resolved_mode("AUTO", true) != "MEDIUM":
        _fail("BOURGUIBA_LIGHTING_AUTO_MOBILE_INVALID")
        return
    if BourguibaLightingProfile.resolved_mode("AUTO", false) != "HIGH":
        _fail("BOURGUIBA_LIGHTING_AUTO_DESKTOP_INVALID")
        return
    print("BOURGUIBA_LIGHTING_GATE_PASS")
    get_tree().quit(0)

func _fail(message: String) -> void:
    push_error(message)
    get_tree().quit(1)
