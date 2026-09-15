extends RefCounted
class_name HeroMeshKit

# Original authored mesh construction. Geometry is merged per material, not one
# MeshInstance per architectural detail. Metres; facade front is negative Z.
var surfaces: Dictionary = {}
var materials: Dictionary = {}
static var foliage_texture: ImageTexture

func material(id: String, color: Color, roughness: float = 0.85, metallic: float = 0.0) -> void:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    m.metallic = metallic
    if id.begins_with("leaf"):
        m.cull_mode = BaseMaterial3D.CULL_DISABLED
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
        m.alpha_scissor_threshold = 0.45
        m.albedo_texture = leaf_texture()
    materials[id] = m

func triangle(id: String, a: Vector3, b: Vector3, c: Vector3) -> void:
    if not surfaces.has(id):
        var s := SurfaceTool.new()
        s.begin(Mesh.PRIMITIVE_TRIANGLES)
        surfaces[id] = s
    var s: SurfaceTool = surfaces[id]
    var n := (b - a).cross(c - a).normalized()
    # Godot clockwise winding viewed from front.
    for p: Vector3 in [a, c, b]:
        s.set_normal(n)
        s.set_uv(Vector2(p.x + p.z, p.y))
        s.add_vertex(p)

func quad(id: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
    triangle(id, a, b, c)
    triangle(id, a, c, d)

func box(id: String, p: Vector3, size: Vector3) -> void:
    var a := p - size * 0.5
    var b := p + size * 0.5
    quad(id, Vector3(a.x,a.y,a.z),Vector3(a.x,b.y,a.z),Vector3(b.x,b.y,a.z),Vector3(b.x,a.y,a.z))
    quad(id, Vector3(b.x,a.y,b.z),Vector3(b.x,b.y,b.z),Vector3(a.x,b.y,b.z),Vector3(a.x,a.y,b.z))
    quad(id, Vector3(a.x,b.y,a.z),Vector3(a.x,b.y,b.z),Vector3(b.x,b.y,b.z),Vector3(b.x,b.y,a.z))
    quad(id, Vector3(a.x,a.y,b.z),Vector3(a.x,a.y,a.z),Vector3(b.x,a.y,a.z),Vector3(b.x,a.y,b.z))
    quad(id, Vector3(a.x,a.y,b.z),Vector3(a.x,b.y,b.z),Vector3(a.x,b.y,a.z),Vector3(a.x,a.y,a.z))
    quad(id, Vector3(b.x,a.y,a.z),Vector3(b.x,b.y,a.z),Vector3(b.x,b.y,b.z),Vector3(b.x,a.y,b.z))

func tube(id: String, a: Vector3, b: Vector3, r1: float, r2: float, segments: int = 8) -> void:
    var axis := (b-a).normalized()
    var u := axis.cross(Vector3.FORWARD).normalized()
    if u.length_squared() < 0.1:
        u = axis.cross(Vector3.UP).normalized()
    var v := axis.cross(u).normalized()
    for i in range(segments):
        var t := TAU * float(i) / segments
        var t2 := TAU * float(i+1) / segments
        var d := u*cos(t)+v*sin(t)
        var e := u*cos(t2)+v*sin(t2)
        quad(id,a+d*r1,a+e*r1,b+e*r2,b+d*r2)
        triangle(id, a, a+e*r1, a+d*r1)
        triangle(id, b, b+d*r2, b+e*r2)

func arch(id: String, x: float, y: float, z: float, radius: float, thickness: float) -> void:
    for i in range(20):
        var a := PI * float(i) / 20.0
        var b := PI * float(i+1) / 20.0
        var p := Vector3(x+radius*cos(a),y+radius*sin(a),z)
        var q := Vector3(x+radius*cos(b),y+radius*sin(b),z)
        tube(id, p, q, thickness, thickness, 6)

func mesh() -> ArrayMesh:
    var result := ArrayMesh.new()
    for id: String in surfaces:
        var s: SurfaceTool = surfaces[id]
        s.set_material(materials[id])
        s.index()
        s.commit(result)
    return result

func palette(tone: Color) -> void:
    material("wall",tone)
    material("stone",Color("#cfc4af"))
    material("trim",Color("#e0d8c6"))
    material("glass",Color("#263b43"),0.23,0.25)
    material("iron",Color("#252c29"),0.6,0.45)
    material("shutter",Color("#48665b"))
    material("wood",Color("#574335"))
    material("fabric",Color("#7b3434"),1.0)

func window(x: float, y: float, width: float, height: float, balcony: bool, detail: bool = true) -> void:
    box("glass",Vector3(x,y,0.18),Vector3(width,height,0.08))
    for dx in [-width/2-0.09,width/2+0.09]:
        box("trim",Vector3(x+dx,y,-0.10),Vector3(0.16,height+0.28,0.26))
        box("shutter",Vector3(x+dx+signf(dx)*0.30,y,-0.035),Vector3(0.42,height,0.10))
        for j in range(12 if detail else 0):
            box("iron",Vector3(x+dx+signf(dx)*0.30,y-height/2+0.08+j*height/12,-0.098),Vector3(0.34,0.027,0.025))
    box("trim",Vector3(x,y+height/2+0.10,-0.12),Vector3(width+0.38,0.17,0.30))
    box("stone",Vector3(x,y-height/2-0.07,-0.22),Vector3(width+0.45,0.13,0.48))
    box("wood",Vector3(x,y,0.11),Vector3(0.065,height,0.07))
    box("wood",Vector3(x,y+0.30,0.11),Vector3(width,0.065,0.07))
    if balcony:
        var floor_y := y-height/2-0.15
        box("stone",Vector3(x,floor_y,-0.58),Vector3(width+0.75,0.16,1.12))
        tube("iron",Vector3(x-width/2-0.3,floor_y+1.05,-1.06),Vector3(x+width/2+0.3,floor_y+1.05,-1.06),0.028,0.028)
        for j in range(10 if detail else 0):
            var bx: float = x-width/2-0.23+j*(width+0.46)/9
            tube("iron",Vector3(bx,floor_y+0.08,-1.06),Vector3(bx,floor_y+1.03,-1.06),0.015,0.015,5)
        for dx in [-width/2-0.30,width/2+0.30]:
            tube("iron",Vector3(x+dx,floor_y+1.05,-1.06),Vector3(x+dx,floor_y+1.05,0),0.025,0.025)

static func facade(variant: int, detail: bool = true) -> ArrayMesh:
    var k := HeroMeshKit.new()
    var tones := [Color("#c4b496"),Color("#d2cbbd"),Color("#c3b6a3"),Color("#dacbb4")]
    k.palette(tones[variant%4])
    var height := 14.5 + float(variant%3)*3.3
    k.box("wall",Vector3(0,height/2,6.0),Vector3(18,height,11.4))
    # Street facade is an assembled open wall: windows sit behind the piers.
    for bay in range(6):
        var x := -7.5+bay*3.0
        k.box("stone",Vector3(x-1.35,2.1,-0.10),Vector3(0.30,4.2,0.65))
        k.box("glass",Vector3(x,1.95,0.12),Vector3(2.40,3.70,0.10))
        k.box("wood",Vector3(x-0.35,1.9,-0.04),Vector3(0.08,3.7,0.12))
        k.box("stone",Vector3(x,4.15,-0.15),Vector3(3.0,0.30,0.7))
        k.box("wood",Vector3(x,3.45,-0.10),Vector3(2.5,0.48,0.15))
        # Sloping fabric awning, front valance.
        k.quad("fabric",Vector3(x-1.3,3.30,-0.2),Vector3(x-1.3,2.85,-1.65),Vector3(x+1.3,2.85,-1.65),Vector3(x+1.3,3.30,-0.2))
        k.box("fabric",Vector3(x,2.73,-1.65),Vector3(2.6,0.24,0.045))
        var y := 5.8
        while y < height-1.0:
            k.box("wall",Vector3(x-1.11,y,0),Vector3(0.78,3.3,0.42))
            k.box("wall",Vector3(x+1.11,y,0),Vector3(0.78,3.3,0.42))
            k.box("wall",Vector3(x,y+1.32,0),Vector3(1.44,0.66,0.42))
            k.box("wall",Vector3(x,y-1.36,0),Vector3(1.44,0.58,0.42))
            k.window(x,y,1.34,2.05,(bay+variant)%2==0,detail)
            y += 3.3
    for y in [4.35,7.95,11.25,height-0.60,height-0.30,height]:
        k.box("trim",Vector3(0,y,-0.10),Vector3(18.12,0.15,0.60 if y>height-1 else 0.26))
    for x in [-8.85,8.85]:
        k.box("stone",Vector3(x,height/2,-0.08),Vector3(0.22,height,0.35))
    k.box("wall",Vector3(0,height+0.35,0.2),Vector3(18,0.65,0.35))
    for x in [-6.0,3.0]:
        k.box("stone",Vector3(x,7.7,-0.42),Vector3(0.82,0.54,0.55))
        for j in range(6):
            k.box("iron",Vector3(x,7.48+j*0.075,-0.71),Vector3(0.65,0.022,0.025))
    return k.mesh()

static func palm(detail: bool = true) -> ArrayMesh:
    var k := HeroMeshKit.new()
    k.material("bark",Color("#74674b"))
    k.material("leaf",Color("#385330"))
    k.material("leaf_light",Color("#677444"))
    for j in range(24):
        var y := float(j)*0.32
        k.tube("bark",Vector3(sin(y*.24)*.22,y,0),Vector3(sin((y+.32)*.24)*.22,y+.32,0),.23-j*.002,.25-j*.002,10)
    var count := 18 if detail else 10
    for i in range(count):
        var angle := float(i)*2.39996
        var dir := Vector3(cos(angle),0,sin(angle))
        var side := Vector3(-dir.z,0,dir.x)
        var length := 3.4+sin(float(i)*4.1)*.5
        var steps := 16 if detail else 8
        for j in range(steps):
            var t := float(j)/steps
            var t2 := float(j+1)/steps
            var a := Vector3(.2,7.6,0)+dir*(length*t)+Vector3(0,sin(t*PI)*1.05-t*t*1.4,0)
            var b := Vector3(.2,7.6,0)+dir*(length*t2)+Vector3(0,sin(t2*PI)*1.05-t2*t2*1.4,0)
            k.tube("bark",a,b,.025*(1-t)+.005,.025*(1-t2)+.005,4)
            for sign_value: float in [-1.0,1.0]:
                var tip := a+side*sign_value*(.65*sin(PI*t)+.05)-dir*.38+Vector3(0,-.18,0)
                k.leaf_card("leaf" if j%3 else "leaf_light",(a+tip)*.5,(tip-a)*.5,(b-a)*.45)
    return k.mesh()

static func ficus(detail: bool = true) -> ArrayMesh:
    var k := HeroMeshKit.new()
    k.material("bark",Color("#827b67"))
    k.material("leaf",Color("#344825"))
    k.material("leaf_light",Color("#526b2d"))
    k.tube("bark",Vector3.ZERO,Vector3(.13,3.8,.08),.24,.14,10)
    for j in range(5):
        var a := TAU*j/5.0
        k.tube("bark",Vector3(.1,2.6,0),Vector3(cos(a)*1.2,5,sin(a)*1.1),.13,.045,7)
    var rng := RandomNumberGenerator.new()
    rng.seed = 64291
    var count := 700 if detail else 160
    for j in range(count):
        var p := Vector3(rng.randf_range(-2.2,2.2),rng.randf_range(3.7,7.5),rng.randf_range(-2.0,2.0))
        if Vector2(p.x,p.z).length()>2.65:
            continue
        var size := .42 if detail else .85
        var u := Vector3(rng.randf_range(.3,1),rng.randf_range(-.5,.5),rng.randf_range(-1,1)).normalized()*size
        var v := u.cross(Vector3.UP).normalized()*size*.65
        var id := "leaf_light" if j%4==0 else "leaf"
        k.leaf_card(id,p,u,v)
        k.leaf_card(id,p,u,Vector3(0,size,0))
    return k.mesh()

static func theatre() -> ArrayMesh:
    var k := HeroMeshKit.new()
    k.palette(Color("#d8d1bf"))
    k.box("wall",Vector3(0,8.5,12),Vector3(29,17,23))
    for x in [-12.0,12.0]:
        k.box("wall",Vector3(x,8.0,-.05),Vector3(5.0,16.0,1.0))
        for y in [4.0,9.0,12.7]:
            k.window(x,y,1.35,2.2,false)
    for x in [-6.0,0.0,6.0]:
        k.box("wood",Vector3(x,2.8,-.1),Vector3(3.6,4.0,.18))
        k.arch("trim",x,4.2,-.4,1.9,.22)
        for dx in [-1.9,1.9]:
            k.tube("trim",Vector3(x+dx,.8,-.35),Vector3(x+dx,4.2,-.35),.18,.18)
        # Deep loggia: dark interior with forward columns and arched architrave.
        k.box("glass",Vector3(x,9.1,.05),Vector3(4.4,5.0,.12))
        k.arch("trim",x,10.0,-1.10,2.35,.24)
        for dx in [-2.35,2.35]:
            k.tube("trim",Vector3(x+dx,6.2,-1.10),Vector3(x+dx,10,-1.10),.22,.19,10)
        k.box("stone",Vector3(x,6.1,-.70),Vector3(5.6,.35,1.6))
        for j in range(14):
            var bx: float = x-2.5+j*5.0/13
            k.tube("trim",Vector3(bx,6.3,-1.35),Vector3(bx,7.25,-1.35),.085,.075,7)
        k.box("trim",Vector3(x,7.3,-1.35),Vector3(5.5,.12,.24))
    for j in range(50):
        var x := -14.5+j*29.0/50
        var next_x := x+29.0/50
        var y := 15.8+2.6*cos(x/14.5*PI/2)
        var y2 := 15.8+2.6*cos(next_x/14.5*PI/2)
        k.box("wall",Vector3(x+.29,(y+13)/2,-.10),Vector3(.60,y-13,.60))
        k.tube("trim",Vector3(x,y,-.5),Vector3(next_x,y2,-.5),.18,.18,8)
        k.tube("stone",Vector3(x,y-.45,-.5),Vector3(next_x,y2-.45,-.5),.08,.08,6)
    # Original abstract floral relief; no copied proprietary sculpture mesh.
    for x in [-8.0,-4.0,0.0,4.0,8.0]:
        for j in range(8):
            var a := TAU*j/8.0
            k.tube("trim",Vector3(x,13.9,-.55),Vector3(x+cos(a)*.75,13.9+sin(a)*.5,-.65),.08,.015,6)
    for step in range(7):
        k.box("stone",Vector3(0,.075+step*.15,-2.0+step*.32),Vector3(27-step*.1,.15,4.0-step*.64))
    return k.mesh()

static func leaf_texture() -> ImageTexture:
    if foliage_texture != null:
        return foliage_texture
    var image := Image.create(128,128,false,Image.FORMAT_RGBA8)
    image.fill(Color(0,0,0,0))
    # Original 3x3 foliage atlas, pointed oval leaves with a central vein.
    for y in range(128):
        for x in range(128):
            var cell_x := x%43
            var cell_y := y%43
            var u := (float(cell_x)-21.0)/18.0
            var v := (float(cell_y)-21.0)/20.0
            if absf(u) < (1.0-v*v)*.62 and absf(v)<1.0:
                var vein := .15 if absf(u)<.035 else 0.0
                var shade := .72+.20*(1.0-absf(u))+vein
                image.set_pixel(x,y,Color(shade,shade,.82*shade,1.0))
    image.generate_mipmaps()
    foliage_texture = ImageTexture.create_from_image(image)
    return foliage_texture

func leaf_card(id: String, p: Vector3, u: Vector3, v: Vector3) -> void:
    if not surfaces.has(id):
        var new_surface := SurfaceTool.new()
        new_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
        surfaces[id] = new_surface
    var s: SurfaceTool = surfaces[id]
    var normal := u.cross(v).normalized()
    var points := [p-u-v,p+u-v,p+u+v,p-u+v]
    var uv := [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]
    for index in [0,2,1,0,3,2]:
        s.set_normal(normal)
        s.set_uv(uv[index])
        s.add_vertex(points[index])
