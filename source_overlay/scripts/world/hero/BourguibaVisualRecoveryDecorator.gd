extends Node3D
class_name BourguibaVisualRecoveryDecorator

# Additive recovery layer for the production hero slice. Keeping the pass
# separate makes it easy to iterate/rollback without destroying the OSM and
# Astra hero reconstruction underneath it.
const HERO_NAME := "BourguibaHeroArea"
const DETAIL_RANGE := 115.0

var hero: Node3D
var recovery_root: Node3D

func _ready() -> void:
    call_deferred("_decorate")

func _decorate() -> void:
    hero = _find_hero()
    if hero == null:
        push_warning("BOURGUIBA_VISUAL_RECOVERY_HERO_NOT_FOUND")
        return
    if hero.has_node("VisualRecoveryLayer"):
        return
    recovery_root = Node3D.new()
    recovery_root.name = "VisualRecoveryLayer"
    hero.add_child(recovery_root)
    _recover_facade_depth()
    _recover_public_life()
    _recover_tunis_identity()
    _recover_theatre_front()
    _naturalize_ficus_rows()
    print("BOURGUIBA_VISUAL_RECOVERY_LAYER_READY")

func _find_hero() -> Node3D:
    var world := get_parent()
    if world == null:
        return null
    for child in world.get_children():
        if child is Node3D and child.name == HERO_NAME:
            return child as Node3D
    return null

func _recover_facade_depth() -> void:
    var k := HeroMeshKit.new()
    k.material("interior_warm", Color("#ad7c48"), .70)
    k.material("interior_cool", Color("#49626a"), .52, .10)
    k.material("glass_deep", Color("#102834"), .13, .28)
    k.material("frame", Color("#3c3029"), .68)
    k.material("brass", Color("#9f7d42"), .30, .58)
    k.material("stone_dark", Color("#9f927c"), .91)
    k.material("awning_red", Color("#7c2f31"), .96)
    k.material("awning_green", Color("#35534a"), .96)
    k.material("awning_blue", Color("#314d62"), .96)
    k.material("awning_gold", Color("#87683b"), .96)
    k.material("sign_red", Color("#4c2928"), .64)
    k.material("sign_green", Color("#223d39"), .64)
    k.material("sign_blue", Color("#253e50"), .64)
    k.material("sign_gold", Color("#51422d"), .64)
    var awnings := ["awning_red", "awning_green", "awning_blue", "awning_gold"]
    var signs := ["sign_green", "sign_red", "sign_blue", "sign_gold"]
    for side: float in [-1.0, 1.0]:
        for building_index in range(13):
            var bx := -108.0 + float(building_index) * 18.0
            if side > 0.0 and bx > -48.0 and bx < 0.0:
                continue
            var variant := building_index % 4
            var facade_z := side * 29.72
            var outward_z := side * 28.42
            for bay in range(6):
                var x := bx - 7.5 + float(bay) * 3.0
                var interior_id := "interior_warm" if (bay + building_index) % 3 != 0 else "interior_cool"
                # Recessed shop light and dark reflective pane give the ground floor
                # actual depth instead of six identical opaque rectangles.
                k.box(interior_id, Vector3(x, 1.88, side * 29.86), Vector3(2.34, 3.45, .055))
                k.box("glass_deep", Vector3(x, 1.90, facade_z), Vector3(2.24, 3.34, .045))
                k.box("frame", Vector3(x-.43, 1.90, side*29.64), Vector3(.07, 3.34, .11))
                k.box("frame", Vector3(x+.43, 1.90, side*29.64), Vector3(.07, 3.34, .11))
                k.box("frame", Vector3(x, 2.90, side*29.64), Vector3(2.25, .075, .11))
                if (bay + building_index) % 3 == 0:
                    k.box("frame", Vector3(x, 1.55, side*29.55), Vector3(.84, 2.92, .14))
                    k.box("glass_deep", Vector3(x, 1.82, side*29.46), Vector3(.60, 2.18, .045))
                    k.box("brass", Vector3(x+.27, 1.55, side*29.40), Vector3(.04, .12, .035))
                k.box(signs[variant], Vector3(x, 3.47, side*29.49), Vector3(2.58, .54, .18))
                k.box("brass", Vector3(x, 3.16, side*29.38), Vector3(2.58, .045, .04))
                # A projecting valance is readable at phone resolution and creates
                # strong repeated shadows without adding many draw calls.
                k.box(awnings[variant], Vector3(x, 2.70, outward_z), Vector3(2.68, .26, .62))
                if (bay + variant) % 2 == 0:
                    k.box("stone_dark", Vector3(x, .42, side*29.48), Vector3(2.76, .80, .34))
            # Break the rectangular roof line with restrained parapet posts.
            for px in range(-8, 9, 2):
                k.box("stone_dark", Vector3(bx+float(px), 15.15+float(variant%3)*3.3, side*29.78), Vector3(.34, .54, .34))
    var node := _mesh_node(k.mesh(), "RecoveredFacadeDepth")
    node.visibility_range_end = DETAIL_RANGE

func _recover_public_life() -> void:
    var k := HeroMeshKit.new()
    k.material("iron", Color("#272d2e"), .56, .34)
    k.material("wood", Color("#684a32"), .82)
    k.material("canvas", Color("#c4a66e"), .96)
    k.material("red", Color("#9f2730"), .90)
    k.material("ceramic", Color("#a9997c"), .94)
    k.material("plant", Color("#3f5c31"), .98)
    k.material("kiosk", Color("#314c49"), .82)
    k.material("glass", Color("#29434a"), .19, .16)
    k.material("paper", Color("#e7ddc5"), .92)
    k.material("white", Color("#e8e3d5"), .88)
    # Café clusters sit against shop fronts, leaving the kerb-side walking line open.
    var cafe_xs := [-84.0, -50.0, -12.0, 42.0, 78.0]
    for side: float in [-1.0, 1.0]:
        for ci in range(cafe_xs.size()):
            if side > 0.0 and ci == 2:
                continue
            var cx: float = cafe_xs[ci] + (3.0 if side > 0.0 else 0.0)
            var cz := side * 25.25
            for table_index in range(2):
                var tx := cx + float(table_index) * 2.15
                k.tube("iron", Vector3(tx,.17,cz), Vector3(tx,.75,cz), .055, .055, 8)
                k.tube("wood", Vector3(tx,.75,cz), Vector3(tx,.82,cz), .45, .45, 12)
                for chair_side: float in [-1.0, 1.0]:
                    var chair_z := cz + chair_side*.82
                    k.box("wood", Vector3(tx,.45,chair_z), Vector3(.50,.07,.46))
                    k.box("wood", Vector3(tx,.76,chair_z+chair_side*.18), Vector3(.50,.58,.065))
                    for leg_x: float in [-.17,.17]:
                        k.tube("iron", Vector3(tx+leg_x,.12,chair_z), Vector3(tx+leg_x,.43,chair_z), .024,.024,5)
            var umbrella_x := cx+1.05
            k.tube("iron", Vector3(umbrella_x,.16,cz), Vector3(umbrella_x,2.58,cz), .04,.035,8)
            k.box("canvas", Vector3(umbrella_x,2.58,cz), Vector3(3.55,.10,2.25))
            k.box("red", Vector3(umbrella_x,2.49,cz-side*1.09), Vector3(3.57,.20,.055))
            for planter_dx: float in [-1.7, 3.75]:
                var px := cx+planter_dx
                k.box("ceramic", Vector3(px,.40,side*26.35), Vector3(.72,.66,.72))
                k.box("plant", Vector3(px,.88,side*26.35), Vector3(.88,.42,.88))
    # Newspaper/refreshment kiosks create recognisable street-service nodes.
    for index in range(2):
        var kx := -64.0 if index == 0 else 58.0
        var side := -1.0 if index == 0 else 1.0
        var kz := side*23.9
        k.box("kiosk", Vector3(kx,1.26,kz), Vector3(3.0,2.20,2.0))
        k.box("glass", Vector3(kx,1.42,kz-side*1.02), Vector3(2.18,.82,.045))
        k.box("red", Vector3(kx,2.50,kz), Vector3(3.45,.18,2.40))
        k.box("paper", Vector3(kx,2.66,kz-side*.86), Vector3(2.0,.25,.07))
    # Bollards give the sidewalks scale in close gameplay shots.
    for side: float in [-1.0,1.0]:
        for x in range(-102, 103, 12):
            k.tube("iron", Vector3(float(x),.14,side*20.0), Vector3(float(x),.80,side*20.0), .085,.07,8)
            k.tube("white", Vector3(float(x),.61,side*20.0), Vector3(float(x),.68,side*20.0), .09,.09,8)
    var node := _mesh_node(k.mesh(), "RecoveredStreetLife")
    node.visibility_range_end = 135.0

func _recover_tunis_identity() -> void:
    var k := HeroMeshKit.new()
    k.material("flag_red", Color("#b01823"), .90)
    k.material("flag_white", Color("#f2eee2"), .86)
    k.material("pole", Color("#32383a"), .52, .40)
    # Banners use two shallow discs to read as Tunisia's crescent at gameplay distance.
    for side: float in [-1.0, 1.0]:
        for x: float in [-86.0, -38.0, 22.0, 76.0]:
            var z := side*22.0
            k.tube("pole", Vector3(x-.80,3.45,z), Vector3(x-.80,5.75,z), .035,.045,8)
            k.box("flag_red", Vector3(x,4.80,z), Vector3(1.45,.88,.035))
            k.tube("flag_white", Vector3(x+.05,4.80,z-side*.035), Vector3(x+.05,4.80,z+side*.035), .255,.255,20)
            k.tube("flag_red", Vector3(x+.13,4.81,z-side*.060), Vector3(x+.13,4.81,z+side*.060), .175,.175,20)
            k.tube("flag_red", Vector3(x-.03,4.80,z-side*.085), Vector3(x-.03,4.80,z+side*.085), .052,.052,8)
    var node := _mesh_node(k.mesh(), "RecoveredTunisianFlags")
    node.visibility_range_end = 165.0
    _identity_label(Vector3(18,5.42,29.28), PI, "AVENUE HABIB BOURGUIBA  •  شارع الحبيب بورقيبة", 42, 95.0)
    _identity_label(Vector3(-64,2.68,-22.82), 0.0, "PRESSE  •  صحافة", 30, 70.0)
    _identity_label(Vector3(58,2.68,22.82), PI, "KIOSQUE  •  كشك", 30, 70.0)

func _recover_theatre_front() -> void:
    var k := HeroMeshKit.new()
    k.material("theatre_red", Color("#6e2529"), .90)
    k.material("theatre_dark", Color("#172b33"), .50, .08)
    k.material("brass", Color("#a98444"), .27, .60)
    k.material("warm", Color("#b67d45"), .62)
    k.material("stone_mid", Color("#8f8878"), .86)
    k.material("stone_shadow", Color("#68665f"), .90)
    k.material("poster", Color("#d9c8a3"), .70)

    # Municipal Theatre front is the visual anchor of this slice. Build shallow
    # architectural relief over Astra's base mesh so the facade reads in grazing
    # morning light instead of as one flat grey polygon.
    k.box("stone_shadow", Vector3(-24,.60,30.92), Vector3(22.2,1.05,.22))
    k.box("theatre_dark", Vector3(-24,5.52,30.86), Vector3(14.8,.72,.18))
    k.box("brass", Vector3(-24,5.13,30.72), Vector3(14.8,.055,.04))
    k.box("theatre_red", Vector3(-24,4.66,29.80), Vector3(16.0,.22,1.92))

    # Vertical pilasters and stepped cornices add the depth cues missing from the
    # fixed close camera. End pilasters also separate the theatre from neighbours.
    for x: float in [-34.2, -31.0, -27.0, -21.0, -17.0, -13.8]:
        var height := 8.0 if x in [-31.0, -27.0, -21.0, -17.0] else 10.8
        var centre_y := 7.45 if height < 10.0 else 8.30
        k.box("stone_mid", Vector3(x,centre_y,30.83), Vector3(.38,height,.34))
        k.box("stone_shadow", Vector3(x,centre_y-.05,30.64), Vector3(.14,height-.35,.12))
    k.box("stone_mid", Vector3(-24,12.22,30.87), Vector3(21.0,.34,.42))
    k.box("stone_shadow", Vector3(-24,12.51,30.78), Vector3(19.6,.18,.20))
    k.box("brass", Vector3(-24,12.69,30.68), Vector3(17.8,.055,.055))

    # Recessed entrance doors, transoms and poster cases make the ground floor
    # read as an operating theatre instead of three black holes.
    for x: float in [-30.0,-24.0,-18.0]:
        k.box("warm", Vector3(x,2.66,31.72), Vector3(3.2,3.70,.055))
        k.box("theatre_dark", Vector3(x,2.66,31.60), Vector3(2.90,3.42,.05))
        k.box("brass", Vector3(x,4.02,31.47), Vector3(2.86,.065,.045))
        k.box("brass", Vector3(x,2.65,31.46), Vector3(.06,3.36,.045))
        k.box("warm", Vector3(x,4.30,31.44), Vector3(2.55,.32,.04))
    for poster_x: float in [-34.5,-13.5]:
        k.box("brass", Vector3(poster_x,2.33,30.47), Vector3(1.55,2.55,.10))
        k.box("poster", Vector3(poster_x,2.33,30.40), Vector3(1.34,2.30,.035))
        k.box("theatre_red", Vector3(poster_x,1.52,30.36), Vector3(1.12,.28,.025))

    # Small marquee lamps are modeled, not real lights, to keep the mobile light
    # budget unchanged while adding readable warm punctuation at phone resolution.
    for lamp_i in range(9):
        var lx := -31.2 + float(lamp_i) * 1.8
        k.box("brass", Vector3(lx,4.48,29.61), Vector3(.13,.13,.13))

    var node := _mesh_node(k.mesh(), "RecoveredTheatreFront")
    node.visibility_range_end = 120.0
    _identity_label(Vector3(-24,5.52,30.58), PI, "THÉÂTRE MUNICIPAL  •  المسرح البلدي", 44, 90.0)

func _naturalize_ficus_rows() -> void:
    var children := hero.get_children()
    var i := 0
    while i < children.size():
        var child = children[i]
        if child is MeshInstance3D and str(child.name).begins_with("Ficus_"):
            var mesh_node := child as MeshInstance3D
            var token := float(i)
            var delta := Vector3(sin(token*1.71)*.58, 0.0, cos(token*1.13)*.28)
            mesh_node.position += delta
            var width_scale := .90 + float((i*7)%6)*.042
            var height_scale := .90 + float((i*5)%7)*.036
            # Trees immediately beside the terminal crossings are intentionally
            # narrower, as real street trees are crown-lifted/pruned for sightlines.
            # This fixes the production intersection view without deleting foliage.
            if absf(mesh_node.position.x) > 92.0:
                width_scale *= .66
                height_scale *= 1.04
            mesh_node.scale = Vector3(width_scale,height_scale,width_scale*.96)
            mesh_node.rotation.y += sin(token*.63)*.24
            if i+1 < children.size() and children[i+1] is MeshInstance3D and str(children[i+1].name).begins_with("FicusLOD"):
                var lod := children[i+1] as MeshInstance3D
                lod.position = mesh_node.position
                lod.scale = mesh_node.scale
                lod.rotation = mesh_node.rotation
        i += 1

func _identity_label(pos: Vector3, yaw: float, text_value: String, size: int, range_end: float) -> void:
    var label := Label3D.new()
    label.text = text_value
    label.position = pos
    label.rotation.y = yaw
    label.font_size = size
    label.pixel_size = .006
    label.modulate = Color("#eadfc3")
    label.outline_size = 8
    label.outline_modulate = Color("#202526")
    label.visibility_range_end = range_end
    recovery_root.add_child(label)

func _mesh_node(mesh: Mesh, node_name: String) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = node_name
    node.mesh = mesh
    recovery_root.add_child(node)
    return node
