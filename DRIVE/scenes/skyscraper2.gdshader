shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.1, 0.5, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float rim_power : hint_range(0.1, 10.0) = 5.0;
uniform float wave_speed : hint_range(0.1, 5.0) = 1.0;
uniform float wave_frequency : hint_range(1.0, 20.0) = 5.0;
uniform float wave_width : hint_range(0.1, 2.0) = 0.5;
uniform float transparency : hint_range(0.0, 1.0) = 0.5;

varying vec3 vertex_pos;
varying vec3 normal;

void vertex() {
    vertex_pos = VERTEX;
    normal = NORMAL;
    
    // Add vertex displacement based on waves
    float wave = sin(TIME * wave_speed + vertex_pos.y * wave_frequency) * wave_width;
    VERTEX += NORMAL * wave;
}

void fragment() {
    // Calculate rim lighting
    vec3 view_dir = normalize(VIEW);
    float rim = 1.0 - abs(dot(view_dir, normal));
    rim = pow(rim, rim_power);
    
    // Create hexagonal pattern
    vec2 hex_uv = vertex_pos.xy * 5.0;
    float hex_pattern = 0.0;
    
    // Animate the pattern
    hex_uv.x += sin(TIME * 0.5) * 0.5;
    hex_uv.y += cos(TIME * 0.3) * 0.5;
    
    // Create base color with waves
    vec3 final_color = base_color.rgb;
    final_color += rim_color.rgb * rim;
    
    // Add scrolling energy lines
    float energy_lines = sin(vertex_pos.y * 20.0 + TIME * 2.0) * 0.5 + 0.5;
    energy_lines *= step(0.97, energy_lines);
    final_color += rim_color.rgb * energy_lines;
    
    // Apply pulsing effect
    float pulse = sin(TIME * 2.0) * 0.5 + 0.5;
    final_color *= (1.0 + pulse * 0.2);
    
    ALBEDO = final_color;
    ALPHA = transparency + rim * 0.5 + energy_lines;
    
    // Add emission
    EMISSION = final_color * (rim * 0.5 + energy_lines);
    
    // Metallic and roughness settings
    METALLIC = 0.8;
    ROUGHNESS = 0.2;
}