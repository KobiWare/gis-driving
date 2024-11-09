shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.7, 0.65, 0.6, 1.0); // Limestone/granite color
uniform vec4 trim_color : source_color = vec4(0.8, 0.6, 0.2, 1.0); // Brass/gold trim color
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform float roughness : hint_range(0.0, 1.0) = 0.7;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 0.5;

uniform float window_frequency : hint_range(0.1, 50.0) = 15.0;
uniform float floor_height : hint_range(0.1, 5.0) = 0.3;
uniform float art_deco_pattern_scale : hint_range(0.1, 10.0) = 2.0;

varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power_normal;
uniform float uv1_blend_sharpness;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

// Art Deco pattern function
float artDecoPattern(vec2 uv) {
    vec2 grid = fract(uv * art_deco_pattern_scale);
    float pattern = 0.0;
    
    float zigzag = abs(fract((grid.x + grid.y) * 2.0) - 0.5) * 2.0;
    float steps = step(0.5, fract(grid.y * 3.0));
    
    pattern = mix(zigzag, steps, 0.5);
    return pattern;
}

// Window pattern function for a single face
float windowPattern(vec2 pos) {
    vec2 window_grid = fract(pos * window_frequency);
    float window = step(0.1, window_grid.x) * step(0.1, window_grid.y);
    window *= step(window_grid.x, 0.9) * step(window_grid.y, 0.9);
    
    // Add floor separation
    float floor_pattern = step(0.1, fract(pos.y / floor_height));
    
    return window * floor_pattern;
}

// Triplanar window mapping
float triplanarWindows(vec3 pos, vec3 normal) {
    float windows = 0.0;
    
    // Front/Back windows (Z axis)
    windows += windowPattern(pos.xy) * normal.z;
    
    // Side windows (X axis)
    windows += windowPattern(pos.zy) * normal.x;
    
    // Optional: Top/Bottom windows (Y axis)
    // windows += windowPattern(pos.xz) * normal.y;
    
    return windows;
}

void vertex() {
    vec3 normal = NORMAL;
    
    TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
    TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
    TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
    TANGENT = normalize(TANGENT);
    
    BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
    BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
    BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
    BINORMAL = normalize(BINORMAL);
    
    uv1_power_normal = pow(abs(NORMAL), vec3(uv1_blend_sharpness));
    uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
    uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
    uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

void fragment() {
    // Base building color
    vec3 final_color = base_color.rgb;
    
    // Add windows using triplanar mapping
    float window = triplanarWindows(uv1_triplanar_pos, NORMAL);
    final_color = mix(final_color, vec3(0.1, 0.12, 0.15), window * 0.8);
    
    // Add Art Deco decorative elements
    float deco_front = artDecoPattern(uv1_triplanar_pos.xy) * abs(NORMAL.z);
    float deco_side = artDecoPattern(uv1_triplanar_pos.zy) * abs(NORMAL.x);
    float deco = deco_front + deco_side;
    
    final_color = mix(final_color, trim_color.rgb, deco * (1.0 - window) * 0.7);
    
    // Add slight variation to roughness for windows
    float final_roughness = roughness;
    final_roughness = mix(roughness, 0.1, window);
    
    // Add metallic variation for decorative elements
    float final_metallic = metallic;
    final_metallic = mix(metallic, 0.8, deco * (1.0 - window));
    
    ALBEDO = final_color;
    METALLIC = final_metallic;
    ROUGHNESS = final_roughness;
    SPECULAR = specular;
}