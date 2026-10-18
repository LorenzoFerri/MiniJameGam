shader_type spatial;
render_mode diffuse_toon, specular_toon;

group_uniforms Surface;
uniform vec4 cable_color : source_color = vec4(0.28, 0.32, 0.35, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.55;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;

group_uniforms Braid;
uniform float braid_frequency : hint_range(1.0, 64.0) = 28.0; // Radians per longitudinal UV unit.
uniform float strands_per_turn : hint_range(1.0, 8.0) = 4.0;
uniform float braid_shadow_threshold : hint_range(-1.0, 1.0) = -0.3;
uniform float braid_highlight_threshold : hint_range(-1.0, 1.0) = 0.65;
uniform float braid_shadow_level : hint_range(0.0, 2.0) = 0.55;
uniform float braid_highlight_level : hint_range(0.0, 2.0) = 1.4;

group_uniforms Tracer;
uniform vec4 tracer_color : source_color = vec4(0.15, 0.65, 0.95, 1.0);
uniform float tracer_sharpness : hint_range(1.0, 32.0) = 20.0;
uniform float tracer_idle_strength : hint_range(0.0, 2.0) = 0.12;
uniform float tracer_pulse_strength : hint_range(0.0, 2.0) = 0.6;
uniform float pulse_frequency : hint_range(0.0, 20.0) = 5.0; // Radians per longitudinal UV unit.
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0; // Radians per second.
uniform float pulse_sharpness : hint_range(1.0, 16.0) = 6.0;
group_uniforms;

void fragment() {
	float along_cable = UV.x * braid_frequency;
	float around_cable = UV.y * TAU * strands_per_turn;
	float strand_a = sin(along_cable + around_cable);
	float strand_b = sin(along_cable - around_cable);
	float braid = smoothstep(braid_shadow_threshold, braid_highlight_threshold, max(strand_a, strand_b));
	float tracer = pow(max(0.0, sin(UV.y * TAU)), tracer_sharpness);
	float pulse = pow(max(0.0, sin(UV.x * pulse_frequency - TIME * pulse_speed)), pulse_sharpness);

	ALBEDO = cable_color.rgb * mix(braid_shadow_level, braid_highlight_level, braid);
	METALLIC = metallic;
	ROUGHNESS = roughness;
	EMISSION = tracer_color.rgb * tracer * (tracer_idle_strength + pulse * tracer_pulse_strength);
}
