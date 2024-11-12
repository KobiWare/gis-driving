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
\tfloat z = sin(uv.x * frequency) * 0.5 + 0.5;
\treturn z;
}

float windowPattern(vec2 uv) {
\tvec2 window_grid = fract(uv * window_frequency);
\tfloat window = step(0.1, window_grid.x) * step(0.1, window_grid.y);
\treturn window;
}

float artDecoPattern(vec2 uv) {
\t// Create geometric patterns
\tfloat pattern = 0.0;
\t
\t// Vertical lines
\tpattern += step(0.98, fract(uv.x * pattern_scale));
\t
\t// Horizontal bands
\tpattern += step(0.95, fract(uv.y * (pattern_scale * 0.5)));
\t
\t// Zigzag pattern
\tpattern += zigzag(uv * 2.0, pattern_scale) * 0.3;
\t
\t// Add windows
\tpattern += windowPattern(uv) * 0.5;
\t
\t// Stepped pattern at the top
\tfloat steps = step(0.95, fract(uv.y * (pattern_scale * 0.25)));
\tpattern += steps;
\t
\treturn clamp(pattern, 0.0, 1.0);
}

void vertex() {
\tvec3 normal = NORMAL;
\t
\tTANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
\tTANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
\tTANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
\tTANGENT = normalize(TANGENT);
\t
\tBINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
\tBINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
\tBINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
\tBINORMAL = normalize(BINORMAL);
\t
\tuv1_power_normal = pow(abs(NORMAL), vec3(uv1_blend_sharpness));
\tuv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
\tuv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
\tuv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

void fragment() {
\t// Generate patterns for each face using triplanar mapping
\tfloat pattern_front = artDecoPattern(uv1_triplanar_pos.xy);
\tfloat pattern_side = artDecoPattern(uv1_triplanar_pos.zy);
\tfloat pattern_top = artDecoPattern(uv1_triplanar_pos.xz);
\t
\t// Combine patterns based on normal weights
\tfloat final_pattern = pattern_front * uv1_power_normal.z +
\t\t\t\t\t\t pattern_side * uv1_power_normal.x +
\t\t\t\t\t\t pattern_top * uv1_power_normal.y;
\t
\t// Mix colors based on pattern
\tvec3 final_color = mix(primary_color.rgb, secondary_color.rgb, final_pattern);
\t
\t// Add metallic highlights
\tfinal_color = mix(final_color, metallic_color.rgb, final_pattern * 0.5);
\t
\tALBEDO = final_color;
\tMETALLIC = metallic * final_pattern;
\tROUGHNESS = roughness + (1.0 - roughness) * (1.0 - final_pattern);
\t
\t// Add slight emission for windows
\tfloat window_emission = windowPattern(uv1_triplanar_pos.xy) * 0.2;
\tEMISSION = vec3(window_emission);
}