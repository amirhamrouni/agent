extends RefCounted
class_name VehicleVisualCatalog

const VEHICLES := {
    "pickup_01": {
        "display_name": "D-MAX inspired",
        "candidate_paths": ["res://assets/external/kenney_car_kit/Models/GLB format/suv.glb", "res://assets/external/quaternius_cars/Cars/OBJ/Pickup.obj"],
        "fallback_color": Color("#e6e4dd"), "fallback_size": Vector3(2.2, 1.2, 5.2), "visual_scale": Vector3(1.0, 1.0, 1.0), "visual_rotation_deg": Vector3(0, 180, 0), "seat_offset": Vector3(-0.48, 1.18, -0.62), "exit_offset": Vector3(1.65, 0.7, 0)
    },
    "pickup_404": {
        "display_name": "404 bâchée inspired",
        "candidate_paths": ["res://assets/external/kenney_car_kit/Models/GLB format/truck.glb", "res://assets/external/quaternius_cars/Cars/OBJ/Pickup.obj"],
        "fallback_color": Color("#789278"), "fallback_size": Vector3(2.0, 1.15, 4.8), "visual_scale": Vector3(1.0, 1.0, 1.0), "visual_rotation_deg": Vector3(0, 180, 0), "seat_offset": Vector3(-0.44, 1.12, -0.52), "exit_offset": Vector3(1.55, 0.68, 0)
    },
    "louage_01": {
        "display_name": "لواج",
        "candidate_paths": ["res://assets/external/kenney_car_kit/Models/GLB format/sedan.glb", "res://assets/external/quaternius_cars/Cars/OBJ/Sedan.obj"],
        "fallback_color": Color("#f2f2ec"), "fallback_size": Vector3(2.05, 1.2, 4.5), "visual_scale": Vector3(1.0, 1.0, 1.0), "visual_rotation_deg": Vector3(0, 180, 0), "seat_offset": Vector3(-0.45, 1.14, -0.35), "exit_offset": Vector3(1.58, 0.68, 0)
    },
    "taxi_01": {
        "display_name": "تاكسي تونس",
        "candidate_paths": ["res://assets/vertical_slice/tunis_taxi.tscn", "res://assets/external/kenney_car_kit/Models/GLB format/taxi.glb", "res://assets/external/kenney_car_kit/Models/GLB format/sedan.glb", "res://assets/external/quaternius_cars/Cars/OBJ/Sedan.obj"],
        "fallback_color": Color("#e6c319"), "fallback_size": Vector3(2.0, 1.15, 4.4), "visual_scale": Vector3(1.0, 1.0, 1.0), "visual_rotation_deg": Vector3(0, 180, 0), "seat_offset": Vector3(-0.44, 1.10, -0.32), "exit_offset": Vector3(1.52, 0.66, 0)
    }
}

static func definition(vehicle_id: String) -> Dictionary:
    return VEHICLES.get(vehicle_id, {})

static func resolve_scene_path(vehicle_id: String) -> String:
    var data := definition(vehicle_id)
    for path in data.get("candidate_paths", []):
        if ResourceLoader.exists(path):
            return path
    var preferred := _preferred_filenames(vehicle_id)
    for base in ["res://assets/external/kenney_car_kit", "res://assets/external/quaternius_cars"]:
        var found := _find_asset_recursive(base, preferred)
        if not found.is_empty():
            return found
    return ""

static func _preferred_filenames(vehicle_id: String) -> Array[String]:
    match vehicle_id:
        "taxi_01": return ["taxi.glb", "taxi.obj", "sedan.glb", "sedan.obj"]
        "louage_01": return ["sedan.glb", "sedan.obj", "van.glb", "van.obj"]
        "pickup_404": return ["truck.glb", "truck.obj", "delivery-flat.glb", "delivery-flat.obj"]
        "pickup_01": return ["suv.glb", "suv.obj", "truck.glb", "truck.obj"]
        _: return []

static func _find_asset_recursive(base: String, preferred: Array[String]) -> String:
    if not DirAccess.dir_exists_absolute(base):
        return ""
    var stack: Array[String] = [base]
    while not stack.is_empty():
        var current: String = str(stack.pop_back())
        var dir := DirAccess.open(current)
        if dir == null:
            continue
        dir.list_dir_begin()
        var name := dir.get_next()
        while not name.is_empty():
            if name.begins_with("."):
                name = dir.get_next()
                continue
            var path := current.path_join(name)
            if dir.current_is_dir():
                stack.append(path)
            elif preferred.has(name.to_lower()):
                dir.list_dir_end()
                return path
            name = dir.get_next()
        dir.list_dir_end()
    return ""
