extends RefCounted
class_name PlayerModelNormalizer

const MIN_HEIGHT_M := 1.20
const MAX_HEIGHT_M := 2.20
const MIN_WIDTH_M := 0.30
const MAX_WIDTH_M := 1.20
const MIN_DEPTH_M := 0.20
const MAX_DEPTH_M := 1.00
const MIN_SCALE := 0.02
const MAX_SCALE := 25.0

func validate_target_size(size: Vector3) -> bool:
    return (
        size.x >= MIN_WIDTH_M and size.x <= MAX_WIDTH_M
        and size.y >= MIN_HEIGHT_M and size.y <= MAX_HEIGHT_M
        and size.z >= MIN_DEPTH_M and size.z <= MAX_DEPTH_M
        and size.is_finite()
    )

func estimate_bounds(root: Node3D) -> AABB:
    var has_bounds := false
    var combined := AABB()
    for child in root.find_children("*", "MeshInstance3D", true, false):
        var mesh_instance := child as MeshInstance3D
        if mesh_instance.mesh == null:
            continue
        var local_bounds := mesh_instance.mesh.get_aabb()
        var relative_transform := root.global_transform.affine_inverse() * mesh_instance.global_transform
        var transformed_bounds := relative_transform * local_bounds
        if not has_bounds:
            combined = transformed_bounds
            has_bounds = true
        else:
            combined = combined.merge(transformed_bounds)
    return combined

func normalize_to_target(root: Node3D, target_size: Vector3) -> Dictionary:
    if root == null:
        return {"ok": false, "reason": "null_root"}
    if not validate_target_size(target_size):
        return {"ok": false, "reason": "invalid_target"}
    var bounds := estimate_bounds(root)
    if not bounds.position.is_finite() or not bounds.size.is_finite():
        return {"ok": false, "reason": "non_finite_bounds"}
    if bounds.size.y < 0.01 or bounds.size.length() < 0.01:
        return {"ok": false, "reason": "no_mesh_bounds"}
    var scale_factor := clampf(target_size.y / bounds.size.y, MIN_SCALE, MAX_SCALE)
    root.scale *= Vector3.ONE * scale_factor
    var scaled_min_y := bounds.position.y * scale_factor
    root.position.y -= scaled_min_y
    var normalized_size := bounds.size * scale_factor
    if normalized_size.x > target_size.x * 1.65 or normalized_size.z > target_size.z * 1.85:
        return {"ok": false, "reason": "proportion_outlier", "source_size": bounds.size, "normalized_size": normalized_size, "scale_applied": scale_factor}
    return {"ok": true, "scale_applied": scale_factor, "ground_offset": -scaled_min_y, "source_size": bounds.size, "normalized_size": normalized_size, "target_size": target_size}
