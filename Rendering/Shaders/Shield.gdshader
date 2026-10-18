shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;

// Regular hexagon geometry: unit width and rows separated by sqrt(3).
const float SQRT_THREE = 1.7320508075688772;
const vec2 HEX_SPACING = vec2(1.0, SQRT_THREE);
const vec2 HEX_FACE_NORMAL = HEX_SPACING * 0.5;
const float HEX_INRADIUS = 0.5;

group_uniforms Surface;
uniform vec4 shield_color : source_color = vec4(0.15, 0.65, 1.0, 1.0);
uniform float brightness : hint_range(0.0, 5.0) = 1.5;
uniform float maximum_opacity : hint_range(0.0, 1.0) = 0.85;
uniform float rim_power : hint_range(1.0, 8.0) = 3.0;
uniform float rim_opacity : hint_range(0.0, 1.0) = 0.42;

group_uniforms Cells;
uniform float cell_scale : hint_range(0.5, 4.0) = 1.5;
uniform float cell_line_width : hint_range(0.001, 0.1) = 0.03;
uniform float projection_sharpness : hint_range(1.0, 16.0) = 8.0;
uniform float cell_idle_opacity : hint_range(0.0, 1.0) = 0.012;
uniform float cell_rim_opacity : hint_range(0.0, 1.0) = 0.05;
uniform float cell_scan_opacity : hint_range(0.0, 1.0) = 0.12;

group_uniforms Flow;
uniform sampler2D flow_noise : repeat_enable, filter_linear_mipmap;
uniform float noise_scale : hint_range(0.001, 1.0) = 0.06;
uniform vec2 noise_scroll = vec2(0.025, 0.0); // Texture units per second.
uniform float noise_minimum_brightness : hint_range(0.0, 1.0) = 0.5;
uniform float flow_speed : hint_range(0.0, 1.0) = 0.12; // Scans per second.
uniform float scan_width : hint_range(0.001, 0.2) = 0.01;
uniform float scan_softness : hint_range(0.001, 0.2) = 0.045;
uniform float scan_opacity : hint_range(0.0, 1.0) = 0.08;

group_uniforms Impact;
uniform vec3 impact_origin = vec3(0.0);
uniform float impact_progress : hint_range(0.0, 1.0) = 1.0;
uniform float impact_radius : hint_range(0.1, 20.0) = 7.0; // Object-space metres.
uniform float impact_width : hint_range(0.001, 1.0) = 0.08;
uniform float impact_softness : hint_range(0.001, 1.0) = 0.27;
uniform float impact_opacity : hint_range(0.0, 1.0) = 0.9;
group_uniforms;

varying vec3 surface_position;
varying vec3 surface_normal;

float hex_outline(vec2 position) {
	vec2 a = mod(position, HEX_SPACING) - HEX_SPACING * 0.5;
	vec2 b = mod(position - HEX_SPACING * 0.5, HEX_SPACING) - HEX_SPACING * 0.5;
	vec2 cell = abs(dot(a, a) < dot(b, b) ? a : b);
	float edge = max(dot(cell, HEX_FACE_NORMAL), cell.x);
	return smoothstep(HEX_INRADIUS - cell_line_width - fwidth(edge), HEX_INRADIUS, edge);
}

float surface_cells(vec3 position, vec3 weights) {
	vec3 projections = vec3(hex_outline(position.yz), hex_outline(position.xz), hex_outline(position.xy));
	return dot(projections, weights);
}

float surface_noise(vec3 position, vec3 weights) {
	vec2 scroll = TIME * noise_scroll;
	vec3 projections = vec3(texture(flow_noise, position.yz + scroll).r,
		texture(flow_noise, position.xz + scroll).r, texture(flow_noise, position.xy + scroll).r);
	return dot(projections, weights);
}

void vertex() {
	surface_position = VERTEX;
	surface_normal = NORMAL;
}

void fragment() {
	vec3 weights = pow(abs(normalize(surface_normal)), vec3(projection_sharpness));
	weights /= dot(weights, vec3(1.0));
	float cells = surface_cells(surface_position * cell_scale, weights);
	float noise = surface_noise(surface_position * noise_scale, weights);
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), rim_power);

	float scan_distance = abs(fract(UV.y - TIME * flow_speed) - 0.5);
	float scan = 1.0 - smoothstep(scan_width, scan_width + scan_softness, scan_distance);
	float impact_distance = abs(distance(surface_position, impact_origin) - impact_progress * impact_radius);
	float impact_ring = 1.0 - smoothstep(impact_width, impact_width + impact_softness, impact_distance);
	float impact = impact_ring * (1.0 - impact_progress);
	float cell_light = cells * (cell_idle_opacity + rim * cell_rim_opacity + scan * cell_scan_opacity);
	cell_light *= mix(noise_minimum_brightness, 1.0, noise);
	float energy = rim * rim_opacity + cell_light + scan * noise * scan_opacity + impact * impact_opacity;

	ALBEDO = shield_color.rgb;
	EMISSION = shield_color.rgb * brightness;
	ALPHA = clamp(energy, 0.0, maximum_opacity);
}
