extends Node3D
class_name BourguibaHeroArea

const ORIGIN := Vector3(-130,0,30)
const LENGTH_M := 240.0
const PAVING := preload("res://shaders/hero_paving.gdshader")
var shared_meshes: Dictionary = {}
var detail_meshes: Array[GeometryInstance3D] = []

func build() -> void:
    name = "BourguibaHeroArea"
    position = ORIGIN
    rotation.y = atan(0.12)
    add_to_group("quality_visual_detail")
    _street()
    for i in range(4):
        shared_meshes["facade%d"%i] = HeroMeshKit.facade(i)
    shared_meshes["palm"] = HeroMeshKit.palm(true)
    shared_meshes["palm_lod"] = HeroMeshKit.palm(false)
    shared_meshes["ficus"] = HeroMeshKit.ficus(true)
    shared_meshes["ficus_lod"] = HeroMeshKit.ficus(false)
    shared_meshes["theatre"] = HeroMeshKit.theatre()
    for side: float in [-1.0,1.0]:
        for i in range(13):
            var x := -108.0+i*18.0
            if side>0 and x>-48 and x<0:
                continue
            var node := _instance(shared_meshes["facade%d"%(i%4)],Vector3(x,.18,side*30),"Facade_%s_%02d"%[str(side),i])
            node.rotation.y = PI if side<0 else 0.0
            node.visibility_range_end = 260.0
            _shop_sign(Vector3(x,3.7,side*29.7),side,i)
    _instance(shared_meshes["theatre"],Vector3(-24,.18,32),"MunicipalTheatre")
    var title := Label3D.new()
    title.text = "المسرح البلدي بتونس"
    title.position = Vector3(-24,16.4,31.1)
    title.rotation.y = PI
    title.font_size = 52
    title.pixel_size = .007
    title.modulate = Color("#514c43")
    title.outline_size = 0
    add_child(title)
    for side: float in [-1.0,1.0]:
        for i in range(21):
            var x := -114.0+i*11.4
            var tree := _instance(shared_meshes["ficus"],Vector3(x,.18,side*8.6),"Ficus_%s_%02d"%[str(side),i])
            tree.rotation.y = float(i)*1.719
            tree.scale = Vector3(1.0,0.94+float(i%4)*.035,1.0)
            tree.visibility_range_end = 75
            var lod := _instance(shared_meshes["ficus_lod"],tree.position,"FicusLOD")
            lod.rotation = tree.rotation
            lod.scale = tree.scale
            lod.visibility_range_begin = 75
            lod.visibility_range_end = 260
            lod.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    for x: float in [-112.0,108.0]:
        for z: float in [-25.0,25.0]:
            var palm := _instance(shared_meshes["palm"],Vector3(x,.18,z),"Palm")
            palm.rotation.y = x*.17
            palm.visibility_range_end = 70
            var lod := _instance(shared_meshes["palm_lod"],palm.position,"PalmLOD")
            lod.rotation = palm.rotation
            lod.visibility_range_begin = 70
            lod.visibility_range_end = 250
    _furniture()

func _instance(mesh: Mesh, pos: Vector3, node_name: String) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = node_name
    instance.mesh = mesh
    instance.position = pos
    add_child(instance)
    return instance

func _surface(pos: Vector3, size: Vector3, color: Color, is_asphalt: bool) -> void:
    var mesh := BoxMesh.new()
    mesh.size = size
    var m := ShaderMaterial.new()
    m.shader = PAVING
    m.set_shader_parameter("base_color",color)
    m.set_shader_parameter("asphalt",is_asphalt)
    var node := _instance(mesh,pos,"Asphalt" if is_asphalt else "Pavement")
    node.material_override = m

func _street() -> void:
    # Carriageway centre distance derives from OSM ways 577010717 / 100081140.
    _surface(Vector3(0,.025,0),Vector3(248,.08,63),Color("#66645b"),false)
    _surface(Vector3(0,.075,0),Vector3(240,.12,20),Color("#868078"),false)
    for side: float in [-1.0,1.0]:
        _surface(Vector3(0,.035,side*14.65),Vector3(248,.08,9.3),Color("#34383b"),true)
        _surface(Vector3(0,.08,side*24.4),Vector3(240,.16,10.2),Color("#918b7e"),false)
    var k := HeroMeshKit.new()
    k.palette(Color("#ada99b"))
    k.material("paint",Color("#c7c4b7"))
    for z: float in [-19.4,-10,10,19.4]:
        k.box("stone",Vector3(0,.15,z),Vector3(240,.22,.20))
    for side: float in [-1.0,1.0]:
        for x in range(-116,117,9):
            k.box("paint",Vector3(x,.087,side*14.7),Vector3(3,.012,.11))
        for x: float in [-103.0,102.0]:
            for j in range(7):
                k.box("paint",Vector3(x-2.5+j*.8,.088,side*14.7),Vector3(.43,.012,8.8))
    _instance(k.mesh(),Vector3.ZERO,"CurbsAndMarkings")

func _furniture() -> void:
    var k := HeroMeshKit.new()
    k.palette(Color("#c4b89f"))
    k.material("lamp",Color("#d7d5c4"),.32)
    for x in range(-108,109,18):
        for side: float in [-1.0,1.0]:
            var z := side*7.4
            for j in range(5):
                k.box("wood",Vector3(x,.55,z+j*.095),Vector3(1.8,.065,.075))
                k.box("wood",Vector3(x,.74+j*.11,z+.48),Vector3(1.8,.075,.06))
            for dx: float in [-.65,.65]:
                k.tube("iron",Vector3(x+dx,.15,z+.10),Vector3(x+dx,.6,z+.10),.04,.04)
                k.tube("iron",Vector3(x+dx,.15,z+.4),Vector3(x+dx,1.25,z+.48),.04,.04)
            var lamp_pos := Vector3(x+4,0,side*9.3)
            k.tube("iron",lamp_pos,lamp_pos+Vector3(0,4.9,0),.075,.045,8)
            k.tube("iron",lamp_pos,lamp_pos+Vector3(0,.5,0),.18,.11,10)
            k.tube("lamp",lamp_pos+Vector3(0,4.9,0),lamp_pos+Vector3(0,5.3,0),.18,.24,8)
            k.tube("iron",lamp_pos+Vector3(0,5.3,0),lamp_pos+Vector3(0,5.65,0),.27,.015,8)
    var node := _instance(k.mesh(),Vector3.ZERO,"StreetFurniture")
    node.visibility_range_end = 150
    detail_meshes.append(node)

func _shop_sign(pos: Vector3, side: float, index: int) -> void:
    var label := Label3D.new()
    var names := ["CAFÉ DE L'AVENUE", "LIBRAIRIE", "مقهى العاصمة", "PATISSERIE", "مكتبة تونس"]
    label.text = names[index%names.size()]
    label.position = pos
    label.rotation.y = PI if side>0 else 0.0
    label.font_size = 36
    label.pixel_size = .006
    label.modulate = Color("#dfd5b9")
    label.outline_size = 0
    label.visibility_range_end = 65
    add_child(label)

func apply_visual_budget(level: int) -> void:
    for node in detail_meshes:
        node.visibility_range_end = 85.0 if level==0 else 150.0

static func contains_world(p: Vector3) -> bool:
    var local := Basis(Vector3.UP,atan(.12)).inverse()*(p-ORIGIN)
    return absf(local.x)<126 and absf(local.z)<55
