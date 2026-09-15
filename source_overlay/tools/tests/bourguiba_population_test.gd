extends SceneTree

const PopulationSpawnerScript = preload("res://scripts/world/PopulationSpawner.gd")

func _initialize() -> void:
    # Structural runtime gate: attach the spawner to a real scene root before spawn_all(),
    # because PopulationSpawner applies budgets through get_tree() groups.
    var test_world := Node3D.new()
    test_world.name = "BourguibaPopulationGateWorld"
    root.add_child(test_world)

    var spawner = PopulationSpawnerScript.new()
    spawner.name = "PopulationSpawner"
    spawner.process_mode = Node.PROCESS_MODE_DISABLED
    test_world.add_child(spawner)

    # SceneTree attachment is synchronous, but fail closed if a future engine/runtime
    # change leaves this structural test detached.
    if spawner.get_tree() == null:
        push_error("BOURGUIBA_POPULATION_TREE_ATTACHMENT_INVALID")
        quit(60)
        return

    var expected := {
        "LOW": [12, 4],
        "MEDIUM": [24, 8],
        "HIGH": [36, 12],
        "AUTO": [24, 8]
    }
    for tier in expected.keys():
        var budget: Dictionary = spawner.population_budget_for_tier(tier)
        var target: Array = expected[tier]
        if int(budget.get("pedestrians", -1)) != int(target[0]) or int(budget.get("traffic", -1)) != int(target[1]):
            push_error("BOURGUIBA_POPULATION_BUDGET_INVALID tier=%s budget=%s" % [tier, budget])
            quit(61)
            return

    var fallback: Dictionary = spawner.population_budget_for_tier("UNKNOWN")
    if int(fallback.get("pedestrians", -1)) != 24 or int(fallback.get("traffic", -1)) != 8:
        push_error("BOURGUIBA_POPULATION_AUTO_FALLBACK_INVALID:%s" % fallback)
        quit(62)
        return

    if spawner.PEDESTRIAN_VARIANTS.size() < 5:
        push_error("BOURGUIBA_PEDESTRIAN_VARIANTS_TOO_LOW:%d" % spawner.PEDESTRIAN_VARIANTS.size())
        quit(63)
        return

    spawner.pedestrian_count = 12
    spawner.traffic_count = 4
    spawner.current_quality_tier = "LOW"
    spawner.spawn_all()

    var peds := get_nodes_in_group("hayat_pedestrian")
    var cars := get_nodes_in_group("hayat_traffic")
    if peds.size() != 12 or cars.size() != 4:
        push_error("BOURGUIBA_POPULATION_SPAWN_COUNT_INVALID peds=%d cars=%d" % [peds.size(), cars.size()])
        quit(64)
        return

    var variants := {}
    for ped in peds:
        if not ped.has_meta("streetlife_variant"):
            push_error("BOURGUIBA_PEDESTRIAN_VARIANT_METADATA_MISSING:%s" % ped.name)
            quit(65)
            return
        variants[str(ped.get_meta("streetlife_variant"))] = true
        var visual := ped.get_node_or_null("CitizenVisual")
        if visual == null:
            push_error("BOURGUIBA_PEDESTRIAN_VISUAL_MISSING:%s" % ped.name)
            quit(66)
            return
    if variants.size() < 5:
        push_error("BOURGUIBA_PEDESTRIAN_VARIANT_COVERAGE_LOW:%d" % variants.size())
        quit(67)
        return

    var traffic_ids := {}
    for car in cars:
        if not car.has_meta("traffic_visual_id"):
            push_error("BOURGUIBA_TRAFFIC_VISUAL_ID_MISSING:%s" % car.name)
            quit(68)
            return
        traffic_ids[str(car.get_meta("traffic_visual_id"))] = true
    if not traffic_ids.has("taxi_01") or traffic_ids.size() < 3:
        push_error("BOURGUIBA_TRAFFIC_VARIETY_LOW:%s" % traffic_ids.keys())
        quit(69)
        return

    var high_result: Dictionary = spawner.apply_quality_tier("HIGH")
    if int(high_result.get("pedestrians", -1)) > spawner.MAX_PEDESTRIANS or int(high_result.get("traffic", -1)) > spawner.MAX_TRAFFIC:
        push_error("BOURGUIBA_POPULATION_CAP_VIOLATION:%s" % high_result)
        quit(70)
        return

    print("BOURGUIBA_POPULATION_GATE_PASS peds=%d cars=%d variants=%d traffic_ids=%d low=%s high=%s" % [
        peds.size(), cars.size(), variants.size(), traffic_ids.size(),
        spawner.population_budget_for_tier("LOW"), spawner.population_budget_for_tier("HIGH")
    ])
    quit(0)
