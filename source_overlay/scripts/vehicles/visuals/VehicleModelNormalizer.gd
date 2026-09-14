extends RefCounted
class_name VehicleModelNormalizer

func validate_target_size(size: Vector3) -> bool:
    return (
        size.x >= 1.2 and size.x <= 3.2
        and size.y >= 0.8 and size.y <= 3.2
        and size.z >= 2.5 and size.z <= 7.5
    )

func estimate_bounds(root: Node3D) -> AABB:
    var first := true
    var combined := AABB()
    for child in root.find_children("*", "MeshInstance3D", true, false):
        var mi := child as MeshInstance3D
        if mi.mesh == null:
            continue
        var bounds := mi.mesh.get_aabb()
        if first:
            combined = bounds
            first = false
        else:
            combined = combined.merge(bounds)
    return combined

func normalize_to_target(root: Node3D, target_size: Vector3) -> Dictionary:
    if not validate_target_size(target_size):
        return {"ok": false, "reason": "invalid_target"}
    var bounds := estimate_bounds(root)
    if bounds.size.length() < 0.01:
        return {"ok": false, "reason": "no_mesh_bounds"}
    var source := bounds.size
    var sx := target_size.x / maxf(source.x, 0.001)
    var sy := target_size.y / maxf(source.y, 0.001)
    var sz := target_size.z / maxf(source.z, 0.001)
    var uniform := clampf(minf(sx, minf(sy, sz)), 0.05, 20.0)
    root.scale *= Vector3.ONE * uniform
    return {"ok": true, "scale_applied": uniform, "source_size": source, "target_size": target_size}
