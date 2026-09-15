extends RefCounted
class_name NaturalFicusFactory

# Mobile-friendly Avenue Habib Bourguiba ficus canopy.
# The previous crown sampled leaves from a rectangular volume, which read as a cube
# at street distance. This version uses overlapping ellipsoidal crown lobes and a
# slightly irregular trunk/branch structure while keeping the geometry batched.

static func make(detail: bool = true) -> ArrayMesh:
    var k := HeroMeshKit.new()
    k.material("bark", Color("#746b58"), 0.92)
    k.material("bark_dark", Color("#514a3d"), 0.94)
    k.material("leaf", Color("#2f4828"), 0.96)
    k.material("leaf_mid", Color("#496b35"), 0.95)
    k.material("leaf_light", Color("#6f874a"), 0.94)

    # Trunk: three offset segments avoid the lamp-post-straight silhouette.
    var t0 := Vector3(0.0, 0.0, 0.0)
    var t1 := Vector3(0.06, 1.45, -0.02)
    var t2 := Vector3(-0.04, 2.85, 0.08)
    var t3 := Vector3(0.10, 4.15, 0.02)
    k.tube("bark", t0, t1, 0.29, 0.245, 10)
    k.tube("bark", t1, t2, 0.245, 0.19, 10)
    k.tube("bark", t2, t3, 0.19, 0.12, 9)

    # Visible radial scaffold through gaps in the crown.
    var branch_count := 8 if detail else 6
    for i in range(branch_count):
        var a := TAU * float(i) / float(branch_count) + sin(float(i) * 1.73) * 0.17
        var start := Vector3(0.08, 3.05 + float(i % 3) * 0.22, 0.04)
        var reach := 1.15 + float((i * 7) % 5) * 0.17
        var end := Vector3(cos(a) * reach, 4.85 + sin(float(i) * 2.11) * 0.38, sin(a) * reach * 0.90)
        k.tube("bark_dark", start, end, 0.11, 0.035, 7)

    var rng := RandomNumberGenerator.new()
    rng.seed = 918273
    var lobes := [
        {"c": Vector3(-0.95, 5.58, -0.20), "r": Vector3(1.55, 1.55, 1.35)},
        {"c": Vector3(0.85, 5.72, 0.05), "r": Vector3(1.62, 1.62, 1.42)},
        {"c": Vector3(-0.10, 6.52, 0.10), "r": Vector3(1.72, 1.42, 1.50)},
        {"c": Vector3(-0.15, 5.35, 0.82), "r": Vector3(1.55, 1.36, 1.30)},
        {"c": Vector3(0.20, 5.48, -0.92), "r": Vector3(1.48, 1.32, 1.28)}
    ]
    var cards_per_lobe := 78 if detail else 24
    var base_size := 0.34 if detail else 0.68

    for li in range(lobes.size()):
        var lobe: Dictionary = lobes[li]
        var center: Vector3 = lobe["c"]
        var radius: Vector3 = lobe["r"]
        var accepted := 0
        var guard := 0
        while accepted < cards_per_lobe and guard < cards_per_lobe * 7:
            guard += 1
            var q := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
            # Rounded ellipsoid instead of a clipped box. Bias slightly toward the shell
            # so the canopy reads dense without filling the whole volume with geometry.
            var d2 := q.x*q.x + q.y*q.y + q.z*q.z
            if d2 > 1.0 or d2 < 0.15:
                continue
            var p := center + Vector3(q.x * radius.x, q.y * radius.y, q.z * radius.z)
            var size := base_size * rng.randf_range(0.78, 1.18)
            var yaw := rng.randf_range(0.0, TAU)
            var u := Vector3(cos(yaw), rng.randf_range(-0.22, 0.32), sin(yaw)).normalized() * size
            var v := Vector3(-sin(yaw), rng.randf_range(0.48, 0.92), cos(yaw) * 0.30).normalized() * size * 0.72
            var selector := (accepted + li * 3) % 7
            var id := "leaf"
            if selector == 0 or selector == 4:
                id = "leaf_mid"
            elif selector == 2:
                id = "leaf_light"
            k.leaf_card(id, p, u, v)
            # Detail crown gets a second crossing card only on part of the foliage,
            # avoiding the old solid cube while keeping phone-distance volume.
            if detail and (accepted + li) % 3 == 0:
                var u2 := Vector3(-u.z, u.y * 0.25, u.x)
                k.leaf_card(id, p, u2, Vector3(0.0, size * 0.82, 0.0))
            accepted += 1

    return k.mesh()
