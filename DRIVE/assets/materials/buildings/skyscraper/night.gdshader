shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 primary_color : source_color = vec4(0.8, 0.7, 0.5, 1.0); // Warm golden color
uniform vec4 secondary_color : source_color = vec4(0.2, 0.2, 0.25, 1.0); // Dark accent color
uniform vec4 metallic_color : source_color = vec4(0.85, 0.75, 0.55, 1.0); // Brass-like color

uniform float pattern_scale : hint_range(1.0, 50.0) = 20.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.8;
uniform float roughness : hint_range(0.0, 1.0) = 0.2;
uniform float window_frequency : hint_range(1.0, 50.0) = 30.0;

varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power_normal;

uniform float uv1_blend_sharpness;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

// Art deco pattern generation
float zigzag(vec2 uv, float frequency) {
    float z = sin(uv.x * frequency) * 0.5 + 0.5;
    return z;
}

float windowPattern(vec2 uv) {
    vec2 window_grid = fract(uv * window_frequency);
    float window = step(0.1, window_grid.x) * step(0.1, window_grid.y);
    return window;
}

float artDecoPattern(vec2 uv) {
    // Create geometric patterns
    float pattern = 0.0;
    
    // Vertical lines
    pattern += step(0.98, fract(uv.x * pattern_scale));
    
    // Horizontal bands
    pattern += step(0.95, fract(uv.y * (pattern_scale * 0.5)));
    
    // Zigzag pattern
    pattern += zigzag(uv * 2.0, pattern_scale) * 0.3;
    
    // Add windows
    pattern += windowPattern(uv) * 0.5;
    
    // Stepped pattern at the top
    float steps = step(0.95, fract(uv.y * (pattern_scale * 0.25)));
    pattern += steps;
    
    return clamp(pattern, 0.0, 1.0);
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
    // Generate patterns for each face using triplanar mapping
    float pattern_front = artDecoPattern(uv1_triplanar_pos.xy);
    float pattern_side = artDecoPattern(uv1_triplanar_pos.zy);
    float pattern_top = artDecoPattern(uv1_triplanar_pos.xz);
    
    // Combine patterns based on normal weights
    float final_pattern = pattern_front * uv1_power_normal.z +
                         pattern_side * uv1_power_normal.x +
                         pattern_top * uv1_power_normal.y;
    
    // Mix colors based on pattern
    vec3 final_color = mix(primary_color.rgb, secondary_color.rgb, final_pattern);
    
    // Add metallic highlights
    final_color = mix(final_color, metallic_color.rgb, final_pattern * 0.5);
    
    ALBEDO = final_color;
    METALLIC = metallic * final_pattern;
    ROUGHNESS = roughness + (1.0 - roughness) * (1.0 - final_pattern);
    
    // Add slight emission for windows
    float window_emission = windowPattern(uv1_triplanar_pos.xy) * 0.2;
    EMISSION = vec3(window_emission);
}