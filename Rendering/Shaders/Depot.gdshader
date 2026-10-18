shader_type spatial;
render_mode diffuse_toon, specular_toon;

group_uniforms Surface;
uniform sampler2D surface_noise : repeat_enable, filter_linear_mipmap;
uniform vec4 floor_color : source_color = vec4(0.19, 0.22, 0.25, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.55;
uniform float roughness : hint_range(0.0, 1.0) = 0.68;
uniform float noise_scale : hint_range(0.1, 10.0) = 3.0;
uniform float surface_variation : hint_range(0.0, 1.0) = 0.4;

group_uniforms Markings;

uniform float border_position : hint_range(0.0, 1.0) = 0.95;
uniform float border_width : hint_range(0.001, 0.1) = 0.008;
uniform float landing_radius : hint_range(0.0, 1.0) = 0.55;
uniform float landing_width : hint_range(0.001, 0.1) = 0.007;
uniform float guide_offset : hint_range(0.0, 1.0) = 0.73;
uniform float guide_half_length : hint_range(0.0, 1.0) = 0.35;
uniform float guide_width : hint_range(0.001, 0.1) = 0.006;
uniform float grid_cells : hint_range(1.0, 30.0) = 10.0;
uniform float grid_width : hint_range(0.001, 0.1) = 0.004;
uniform float grid_softness : hint_range(0.001, 0.1) = 0.01;
uniform float grid_brightness : hint_range(0.0, 0.1) = 0.008;

group_uniforms Lighting;
uniform vec4 light_color : source_color = vec4(0.2, 0.7, 1.0, 1.0);
uniform float light_strength : hint_range(0.0, 5.0) = 1.8;
uniform float border_intensity : hint_range(0.0, 3.0) = 0.7;
uniform float landing_intensity : hint_range(0.0, 3.0) = 0.35;
uniform float guide_intensity : hint_range(0.0, 3.0) = 0.45;
uniform float scan_speed : hint_range(0.0, 3.0) = 0.6; // Radians per second.
uniform float scan_sharpness : hint_range(1.0, 64.0) = 32.0;

group_uniforms Delivery;
uniform float delivery_glow : hint_range(0.0, 1.0) = 0.0;
uniform float delivery_expansion : hint_range(0.0, 1.0) = 0.4;
uniform float delivery_width : hint_range(0.001, 0.1) = 0.015;
uniform float delivery_intensity : hint_range(0.0, 5.0) = 2.0;
group_uniforms;

float line(float value, float centre, float width) {
	return 1.0 - smoothstep(width, width + fwidth(value), abs(value - centre));
}

void fragment() {
	vec2 position = UV * 2.0 - 1.0; // Convert UV [0, 1] to centred coordinates [-1, 1].
	float radius = length(position);
	float edge = max(abs(position.x), abs(position.y));
	float border = line(edge, border_position, border_width);
	float landing_ring = line(radius, landing_radius, landing_width);
	float guides = line(abs(position.x), guide_offset, guide_width) * (1.0 - step(guide_half_length, abs(position.y)));
	vec2 grid_distance = abs(fract(UV * grid_cells - 0.5) - 0.5);
	float grid = 1.0 - smoothstep(grid_width, grid_width + grid_softness, min(grid_distance.x, grid_distance.y));

	float scan_angle = atan(position.y, position.x) - TIME * scan_speed;
	float scan = pow(max(0.0, cos(scan_angle)), scan_sharpness);
	float delivery_radius = landing_radius + (1.0 - delivery_glow) * delivery_expansion;
	float delivery_ring = line(radius, delivery_radius, delivery_width) * delivery_glow;
	float noise = texture(surface_noise, UV * noise_scale).r;
	float surface_shading = 1.0 + (noise - 0.5) * surface_variation;
	float lights = border * (border_intensity + delivery_glow) + landing_ring * (landing_intensity + scan) + guides * guide_intensity;

	ALBEDO = floor_color.rgb * surface_shading + vec3(grid * grid_brightness);
	METALLIC = metallic;
	ROUGHNESS = roughness;
	EMISSION = light_color.rgb * light_strength * (lights + delivery_ring * delivery_intensity);
}
