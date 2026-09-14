extends Node3D
class_name OsmWorldLoader

@export_file("*.json") var processed_map_path := "res://data/osm/tunis_bourguiba_processed.json"
@export var meters_per_unit := 1.0
@export var road_y := 0.055
@export var default_building_height := 9.0

var loaded_real_map := false
var building_count := 0
var road_count := 0
var building_visibility_budget := 95.0

func _ready() -> void:
    add_to_group("osm_world")

func has_real_map() -> bool:
    return FileAccess.file_exists(processed_map_path)

func load_real_map() -> bool:
    if not has_real_map():
        return false
    var f := FileAccess.open(processed_map_path, FileAccess.READ)
    if f == null:
        return false
    var parsed = JSON.parse_string(f.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return false
    if not _validate_processed_document(parsed):
        push_warning("OSM loader rejected map: processed-map validation failed")
        return false
    _clear_generated()
    for b in parsed.get("buildings", []):
        _build_building(b)
    for r in parsed.get("roads", []):
        _build_road(r)
    loaded_real_map = true
    return true

func _validate_processed_document(doc: Dictionary) -> bool:
    var meta = doc.get("meta", {})
    if typeof(meta) != TYPE_DICTIONARY:
        return false
    if int(meta.get("schema_version", 0)) < 2:
        return false
    if str(meta.get("source", "")) != "OpenStreetMap":
        return false
    if str(meta.get("license", "")) != "ODbL-1.0":
        return false
    if str(meta.get("projection", "")) != "local_equirectangular":
        return false
    var buildings = doc.get("buildings", [])
    var roads = doc.get("roads", [])
    var graph = doc.get("road_graph", {})
    if typeof(buildings) != TYPE_ARRAY or typeof(roads) != TYPE_ARRAY or typeof(graph) != TYPE_DICTIONARY:
        return false
    if int(meta.get("building_count", -1)) != buildings.size():
        return false
    if int(meta.get("road_count", -1)) != roads.size():
        return false
    var nodes = graph.get("nodes", [])
    var edges = graph.get("edges", [])
    if typeof(nodes) != TYPE_ARRAY or typeof(edges) != TYPE_ARRAY:
        return false
    if int(meta.get("graph_node_count", -1)) != nodes.size():
        return false
    if int(meta.get("graph_edge_count", -1)) != edges.size():
        return false
    for edge in edges:
        if typeof(edge) != TYPE_ARRAY or edge.size() < 2:
            return false
        var a := int(edge[0])
        var b := int(edge[1])
        if a < 0 or b < 0 or a >= nodes.size() or b >= nodes.size() or a == b:
            return false
    var bounds = meta.get("content_bounds_m", {})
    if typeof(bounds) != TYPE_DICTIONARY:
        return false
    for key in ["min_x", "max_x", "min_z", "max_z"]:
        if not bounds.has(key):
            return false
    var extent := maxf(maxf(absf(float(bounds.get("min_x", 0.0))), absf(float(bounds.get("max_x", 0.0)))), maxf(absf(float(bounds.get("min_z", 0.0))), absf(float(bounds.get("max_z", 0.0)))))
    if not is_finite(extent) or extent > 2500.0:
        return false
    return true

func _clear_generated() -> void:
    for child in get_children():
        child.queue_free()
    building_count = 0
    road_count = 0

func _material(color: Color, roughness := 0.85) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    return m

func _build_building(data: Dictionary) -> void:
    var pts: Array[Vector2] = []
    for p in data.get("points", []):
        if p.size() >= 2:
            pts.append(Vector2(float(p[0]), float(p[1])) / meters_per_unit)
    if pts.size() < 3:
        return
    if pts[0].distance_to(pts[pts.size()-1]) < 0.01:
        pts.pop_back()
    if pts.size() < 3:
        return
    var height := float(data.get("height_m", default_building_height))
    height = clampf(height, 2.8, 80.0)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var indices := Geometry2D.triangulate_polygon(PackedVector2Array(pts))
    for idx in indices:
        var p := pts[idx]
        st.set_normal(Vector3.UP)
        st.add_vertex(Vector3(p.x, height, p.y))
    for i in range(pts.size()):
        var a := pts[i]
        var b := pts[(i+1) % pts.size()]
        var va := Vector3(a.x, 0.0, a.y)
        var vb := Vector3(b.x, 0.0, b.y)
        var ta := Vector3(a.x, height, a.y)
        var tb := Vector3(b.x, height, b.y)
        var edge := vb - va
        var normal := Vector3(-edge.z, 0.0, edge.x).normalized()
        st.set_normal(normal); st.add_vertex(va)
        st.set_normal(normal); st.add_vertex(vb)
        st.set_normal(normal); st.add_vertex(tb)
        st.set_normal(normal); st.add_vertex(va)
        st.set_normal(normal); st.add_vertex(tb)
        st.set_normal(normal); st.add_vertex(ta)
    var mesh := st.commit()
    if mesh == null:
        return
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = _material(_building_color(int(data.get("id", 0))))
    mi.visibility_range_end = building_visibility_budget
    mi.visibility_range_end_margin = 12.0
    add_child(mi)
    var minp := pts[0]
    var maxp := pts[0]
    for p in pts:
        minp.x = minf(minp.x, p.x); minp.y = minf(minp.y, p.y)
        maxp.x = maxf(maxp.x, p.x); maxp.y = maxf(maxp.y, p.y)
    var size2 := maxp - minp
    if size2.x > 0.5 and size2.y > 0.5:
        var body := StaticBody3D.new()
        var cs := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(size2.x, height, size2.y)
        cs.shape = shape
        cs.position = Vector3((minp.x+maxp.x)*0.5, height*0.5, (minp.y+maxp.y)*0.5)
        body.add_child(cs)
        add_child(body)
    building_count += 1

func _build_road(data: Dictionary) -> void:
    var pts: Array[Vector2] = []
    for p in data.get("points", []):
        if p.size() >= 2:
            pts.append(Vector2(float(p[0]), float(p[1])) / meters_per_unit)
    if pts.size() < 2:
        return
    var width := float(data.get("width_m", 6.0)) / meters_per_unit
    width = clampf(width, 1.4, 18.0)
    for i in range(pts.size()-1):
        var a := pts[i]
        var b := pts[i+1]
        var d := b - a
        var length := d.length()
        if length < 0.2:
            continue
        var road := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(width, 0.08, length)
        road.mesh = box
        road.position = Vector3((a.x+b.x)*0.5, road_y, (a.y+b.y)*0.5)
        road.rotation.y = atan2(d.x, d.y)
        road.material_override = _material(Color("#343536"), 0.94)
        add_child(road)
    road_count += 1

func _building_color(id: int) -> Color:
    var colors := [Color("#d9c5a6"), Color("#c9b08d"), Color("#dfd6c5"), Color("#b7a78c"), Color("#e2cfae")]
    return colors[abs(id) % colors.size()]

func apply_visibility_budget(distance_m: float) -> void:
    building_visibility_budget = maxf(30.0, distance_m)
    for child in get_children():
        if child is MeshInstance3D:
            var mi := child as MeshInstance3D
            if mi.mesh is ArrayMesh:
                mi.visibility_range_end = building_visibility_budget
                mi.visibility_range_end_margin = 12.0
