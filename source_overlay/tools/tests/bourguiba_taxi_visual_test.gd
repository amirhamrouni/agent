extends SceneTree

const TAXI_SCENE := preload("res://assets/vertical_slice/tunis_taxi.tscn")
const VehicleVisualCatalog = preload("res://scripts/vehicles/visuals/VehicleVisualCatalog.gd")

func _initialize() -> void:
    var resolved := VehicleVisualCatalog.resolve_scene_path("taxi_01")
    if resolved != "res://assets/vertical_slice/tunis_taxi.tscn":
        push_error("BOURGUIBA_TAXI_RESOLVE_FAILED:%s" % resolved)
        quit(61)
        return

    var taxi := TAXI_SCENE.instantiate()
    root.add_child(taxi)
    if not taxi.is_in_group("tunis_taxi_visual"):
        push_error("BOURGUIBA_TAXI_GROUP_MISSING")
        quit(62)
        return

    var required := [
        "Body", "Cabin", "Windshield", "RearWindow",
        "BlackSideStripeLeft", "BlackSideStripeRight", "TaxiRoofSign",
        "WheelFL", "WheelFR", "WheelRL", "WheelRR"
    ]
    for node_name in required:
        if taxi.get_node_or_null(node_name) == null:
            push_error("BOURGUIBA_TAXI_NODE_MISSING:%s" % node_name)
            quit(63)
            return

    var roof_sign := taxi.get_node("TaxiRoofSign")
    if not roof_sign.is_in_group("taxi_identifier"):
        push_error("BOURGUIBA_TAXI_IDENTIFIER_MISSING")
        quit(64)
        return

    var body := taxi.get_node("Body") as MeshInstance3D
    var body_material := body.material_override as StandardMaterial3D
    if body_material == null:
        push_error("BOURGUIBA_TAXI_BODY_MATERIAL_MISSING")
        quit(65)
        return
    var yellow := body_material.albedo_color
    if yellow.r < 0.8 or yellow.g < 0.55 or yellow.b > 0.2:
        push_error("BOURGUIBA_TAXI_YELLOW_TREATMENT_INVALID:%s" % yellow)
        quit(66)
        return

    var visual_count := _count_meshes_recursive(taxi)
    if visual_count < 14:
        push_error("BOURGUIBA_TAXI_GEOMETRY_TOO_LOW:%d" % visual_count)
        quit(67)
        return

    print("BOURGUIBA_TAXI_VISUAL_GATE_PASS resolved=%s meshes=%d yellow=%s" % [resolved, visual_count, yellow])
    quit(0)

func _count_meshes_recursive(node: Node) -> int:
    var count := 1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count += _count_meshes_recursive(child)
    return count
