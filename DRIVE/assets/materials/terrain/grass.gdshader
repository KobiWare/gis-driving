shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 grass_color : source_color = vec4(0.2, 0.5, 0.1, 1.0);
uniform vec4 grass_color_variation : source_color = vec4(0.1, 0.3, 0.05, 1.0);
uniform sampler2D grass_texture : source_color, filter_linear_mipmap, repeat_enable;

// Wind parameters
uniform float wind_strength : hint_range(0.0, 2.0) = 0.5;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wind_scale : hint_range(0.1, 10.0) = 1.0;

// Grass properties
uniform float grass_height : hint_range(0.1, 2.0) = 1.0;
uniform float grass_width : hint_range(0.1, 2.0) = 0.1;
uniform float grass_randomness : hint_range(0.0, 1.0) = 0.4;

varying float wind_factor;
varying float height_factor;

// Random function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void vertex() {
    // Calculate base position
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Height factor (0 at bottom, 1 at top)
    height_factor = VERTEX.y / grass_height;

    // Wind movement
    float time = TIME * wind_speed;
    float wind = sin(time + world_pos.x * wind_scale + world_pos.z * wind_scale) * wind_strength;

    // Random offset per vertex
    float random_offset = random(world_pos.xz) * grass_randomness;

    // Apply wind and random movement only to upper vertices
    if (height_factor > 0.2) {
        VERTEX.x += wind * height_factor + random_offset;
        VERTEX.z += (cos(time * 0.5) * wind_strength * 0.5) * height_factor + random_offset;
    }

    wind_factor = wind;

    // Basic vertex color variation based on height
    COLOR = vec4(1.0);
}

void fragment() {
    // Base grass color with variation
    vec3 base_color = mix(grass_color.rgb, grass_color_variation.rgb, random(vec2(wind_factor, height_factor)));

    // Darken bottom parts of grass
    base_color *= mix(0.7, 1.0, height_factor);

    // Add slight transparency at grass tips
    float alpha = mix(1.0, 0.9, pow(height_factor, 2.0));

    // Apply texture
    vec4 texture_color = texture(grass_texture, UV);

    // Final color
    ALBEDO = base_color * texture_color.rgb;

    // Metallic and roughness properties
    METALLIC = 0.0;
    ROUGHNESS = mix(0.8, 1.0, height_factor);

    // Subsurface scattering effect
    SSS_STRENGTH = 0.5;

    // Transparency
    ALPHA = alpha * texture_color.a;
}