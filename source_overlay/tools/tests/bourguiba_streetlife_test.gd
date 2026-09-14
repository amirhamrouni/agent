extends SceneTree

const PublicRealmPass = preload("res://scripts/world/art/TunisPublicRealmPass.gd")

func _initialize() -> void:
    var scene := PublicRealmPass.new()
    root.add_child(scene)
    scene.build()

    var palms := scene.get_node_or_null("BourguibaPalms")
    var streetlife := scene.get_node_or_null("BourguibaCafeKiosks")
    if palms == null or streetlife == null:
        push_error("BOURGUIBA_STREETLIFE_REQUIRED_NODE_MISSING")
        quit(51)
        return
    if scene.palm_count < 14:
        push_error("BOURGUIBA_STREETLIFE_PALM_COUNT_LOW:%d" % scene.palm_count)
        quit(52)
        return
    if scene.kiosk_count < 2:
        push_error("BOURGUIBA_STREETLIFE_KIOSK_COUNT_LOW:%d" % scene.kiosk_count)
        quit(53)
        return
    if scene.cafe_count < 3:
        push_error("BOURGUIBA_STREETLIFE_CAFE_COUNT_LOW:%d" % scene.cafe_count)
        quit(54)
        return
    if palms.get_child_count() < 100 or streetlife.get_child_count() < 30:
        push_error("BOURGUIBA_STREETLIFE_GEOMETRY_LOW palms=%d streetlife=%d" % [palms.get_child_count(), streetlife.get_child_count()])
        quit(55)
        return

    scene.apply_visual_budget(0)
    for detail in scene.medium_detail_nodes:
        if is_instance_valid(detail) and detail.visible:
            push_error("BOURGUIBA_STREETLIFE_LOD_MEDIUM_VISIBLE_AT_LOW")
            quit(56)
            return
    for detail in scene.high_detail_nodes:
        if is_instance_valid(detail) and detail.visible:
            push_error("BOURGUIBA_STREETLIFE_LOD_HIGH_VISIBLE_AT_LOW")
            quit(57)
            return

    print("BOURGUIBA_STREETLIFE_GATE_PASS palms=%d kiosks=%d cafes=%d generated=%d" % [
        scene.palm_count, scene.kiosk_count, scene.cafe_count, scene.generated_count
    ])
    quit(0)
