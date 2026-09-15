shader_type spatial;
render_mode diffuse_burley;
uniform vec4 base_color : source_color = vec4(0.36,0.34,0.30,1.0);
uniform bool asphalt = false;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
    vec2 p = world_position.xz;
    float grain = hash(floor(p*160.0));
    if (asphalt) {
        ALBEDO = base_color.rgb * (0.92 + grain*0.16);
        ROUGHNESS = 0.93;
    } else {
        vec2 tile = p/vec2(0.45,0.30);
        vec2 f = fract(tile);
        float seam = step(0.025,min(min(f.x,1.0-f.x),min(f.y,1.0-f.y)));
        float variation = hash(floor(tile));
        ALBEDO = base_color.rgb * mix(0.56,0.88+variation*0.20,seam) * (0.96+grain*0.08);
        ROUGHNESS = 0.89;
        NORMAL_MAP = vec3(0.5+0.06*(grain-0.5),0.5,1.0);
        NORMAL_MAP_DEPTH = 0.35;
    }
}
