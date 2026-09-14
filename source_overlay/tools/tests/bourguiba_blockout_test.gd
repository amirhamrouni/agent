extends SceneTree

const PublicRealmPass = preload("res://scripts/world/art/TunisPublicRealmPass.gd")

func _initialize() -> void:
    var scene := PublicRealmPass.new()
    root.add_child(scene)
    scene.build()

    var required_nodes := [
        "BourguibaRoadSurface",
        "BourguibaSidewalks",
        "BourguibaLaneMarkings",
        "BourguibaCrosswalks",
        "BourguibaRedWhiteCurbs",
        "BourguibaCenterMedian",
        "BourguibaTreeGrates",
        "BourguibaStreetDrainage",
        "BourguibaBenches",
        "BourguibaBollards",
        "BourguibaPlanters",
        "BourguibaStreetLamps",
    ]

    for node_name in required_nodes:
        if scene.get_node_or_null(NodePath(node_name)) == null:
            push_error("BOURGUIBA_BLOCKOUT_MISSING_NODE:%s" % node_name)
            quit(41)
            return

    if scene.generated_count < 250:
        push_error("BOURGUIBA_BLOCKOUT_INSUFFICIENT_GEOMETRY:%d" % scene.generated_count)
        quit(42)
        return

    var road := scene.get_node("BourguibaRoadSurface") as Node3D
    var sidewalks := scene.get_node("BourguibaSidewalks") as Node3D
    var crossings := scene.get_node("BourguibaCrosswalks") as Node3D
    if road.get_child_count() < 1 or sidewalks.get_child_count() < 2 or crossings.get_child_count() < 20:
        push_error("BOURGUIBA_BLOCKOUT_GEOMETRY_CONTRACT_FAILED")
        quit(43)
        return

    print("BOURGUIBA_BLOCKOUT_GATE_PASS generated=%d required_nodes=%d" % [scene.generated_count, required_nodes.size()])
    quit(0)
