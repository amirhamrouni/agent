shader_type spatial;
render_mode diffuse_burley;
uniform vec4 base_color : source_color = vec4(0.36,0.34,0.30,1.0);
uniform bool asphalt = false;
varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
}

float hash21(vec2 p) {
    return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}

void fragment() {
    vec2 p = world_position.xz;
    float micro = hash21(floor(p*110.0));
    float macro = sin(p.x*0.095 + sin(p.y*0.071))*0.5 + 0.5;

    if (asphalt) {
        float asphalt_tone = 0.90 + micro*0.075 + (macro-0.5)*0.035;
        ALBEDO = base_color.rgb * asphalt_tone;
        ROUGHNESS = 0.94;
        NORMAL_MAP = vec3(0.5 + (micro-0.5)*0.025, 0.5, 1.0);
        NORMAL_MAP_DEPTH = 0.16;
    } else {
        // Staggered rectangular stone courses replace the old perfect square grid.
        // Wider joints are avoided because they produced high-frequency moire on
        // the 1280x720 production cameras and made the avenue look synthetic.
        float course_h = 0.36;
        float stone_w = 0.58;
        float row = floor(p.y/course_h);
        float stagger = mod(abs(row),2.0)*0.5;
        vec2 tile = vec2(p.x/stone_w + stagger, p.y/course_h);
        vec2 cell = floor(tile);
        vec2 f = fract(tile);
        float edge = min(min(f.x,1.0-f.x),min(f.y,1.0-f.y));
        float joint = smoothstep(0.018,0.046,edge);
        float variation = hash21(cell);
        float warm_shift = hash21(cell + vec2(19.0,7.0));
        float stone_tone = 0.87 + variation*0.11 + (macro-0.5)*0.045;
        vec3 stone = base_color.rgb * stone_tone;
        stone *= mix(vec3(0.98,0.985,1.0),vec3(1.025,1.005,0.97),warm_shift*0.45);
        vec3 mortar = base_color.rgb * (0.69 + micro*0.035);
        ALBEDO = mix(mortar,stone,joint);
        ROUGHNESS = mix(0.96,0.88,joint);
        NORMAL_MAP = vec3(0.5+(micro-0.5)*0.035,0.5,1.0);
        NORMAL_MAP_DEPTH = 0.20;
    }
}
