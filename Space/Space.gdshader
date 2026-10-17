shader_type canvas_item;
render_mode unshaded;

group_uniforms Noise;
uniform sampler2D nebula_noise : filter_linear, repeat_enable;
uniform sampler2D dust_noise : filter_linear, repeat_enable;
uniform sampler2D star_noise : filter_nearest, repeat_enable;

group_uniforms Nebula;
uniform vec4 outer_gas_color : source_color = vec4(0.29, 0.17, 0.32, 1.0);
uniform vec4 ionized_gas_color : source_color = vec4(0.66, 0.39, 0.57, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.83, 0.81, 1.0);
uniform vec4 hydrogen_color : source_color = vec4(0.25, 0.035, 0.055, 1.0);
uniform float cloud_scale : hint_range(0.1, 2.0) = 0.85;
uniform float warp_strength : hint_range(0.0, 0.5) = 0.16;
uniform float cloud_brightness : hint_range(0.1, 5.0) = 1.5;
uniform float dust_strength : hint_range(0.0, 1.0) = 0.8;
uniform float animation_speed : hint_range(0.0, 0.1) = 0.056;

group_uniforms Stars;
uniform vec4 cool_star_color : source_color = vec4(0.55, 0.77, 1.0, 1.0);
uniform vec4 warm_star_color : source_color = vec4(1.0, 0.86, 0.66, 1.0);
uniform float star_brightness : hint_range(0.0, 3.0) = 1.0;
uniform float twinkle_strength : hint_range(0.0, 1.0) = 0.25;

group_uniforms Composition;
uniform vec4 background_color : source_color = vec4(0.006, 0.012, 0.03, 1.0);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.25;

group_uniforms Parallax;
uniform float parallax_strength : hint_range(0.0, 0.05) = 0.012;
uniform float nebula_parallax : hint_range(0.0, 1.0) = 0.02;
uniform float dust_parallax : hint_range(0.0, 1.0) = 0.04;
// Set by SpaceBackground.gd from the target's absolute world position.
uniform vec2 viewer_position = vec2(0.0);
group_uniforms;

// Two decorrelated samples form a flow field. Each stage bends the next;
// the fractal detail itself lives in the editable NoiseTexture2D resource.
vec2 sample_flow(vec2 position) {
	return vec2(
		texture(nebula_noise, position).r,
		texture(nebula_noise, position + vec2(0.37, 0.61)).r
	) - 0.5;
}


// Emission follows density, while a nearer dust layer cuts dark lanes through it.
// RGB contains emitted light; alpha is background transmission.
vec4 render_nebula(vec2 screen_position, vec2 travel, float time) {
	vec2 position = (screen_position + travel * nebula_parallax) * cloud_scale + vec2(0.31, 0.57);
	vec2 broad_flow = sample_flow(position * 0.7 + vec2(time * 0.12, 0.0));
	vec2 fine_flow = sample_flow(position + broad_flow * warp_strength - vec2(0.0, time * 0.09));
	vec2 gas_uv = position + fine_flow * warp_strength;
	float gas = texture(nebula_noise, gas_uv).r;
	float tendrils = texture(nebula_noise, gas_uv * 2.7 + broad_flow * 0.12).r;
	float density = smoothstep(0.12, 1.0, gas);
	float emission = density * density * density;
	emission *= mix(0.65, 1.25, tendrils);

	vec2 dust_uv = (screen_position + travel * dust_parallax) * cloud_scale;
	float dust = texture(dust_noise, dust_uv + fine_flow * 0.15 + vec2(time * 0.03, 0.0)).r;
	float dust_opacity = smoothstep(0.48, 0.82, dust) * dust_strength;
	float gas_transmission = exp(-emission * 1.5);
	vec3 gas_color = mix(outer_gas_color.rgb, ionized_gas_color.rgb, smoothstep(0.05, 0.6, emission));
	gas_color = mix(gas_color, core_color.rgb, smoothstep(0.45, 1.15, emission));
	vec3 light = gas_color * emission * cloud_brightness * (1.0 - dust_opacity);
	light = vec3(1.0) - exp(-light);

	// A broad, dim hydrogen veil gives the filaments a warmer surrounding glow.
	float veil = texture(dust_noise, position * 0.45 + vec2(0.4, 0.2)).r;
	light += hydrogen_color.rgb * veil * veil * 0.4;
	return vec4(light, gas_transmission * (1.0 - dust_opacity));
}


// Each layer gets its placement, brightness and color from the noise texture.
vec3 render_star_layer(vec2 position, float density, float radius, float threshold, vec2 seed_offset, float glare) {
	vec2 grid = position * density;
	vec2 cell_uv = (floor(grid) + 0.5) / vec2(textureSize(star_noise, 0)) + seed_offset;
	float presence = texture(star_noise, cell_uv).r;
	vec2 star_values = vec2(
		texture(star_noise, cell_uv + vec2(0.5, 0.0)).r,
		texture(star_noise, cell_uv + vec2(0.0, 0.5)).r
	);
	vec2 center = mix(vec2(0.22), vec2(0.78), star_values);
	vec2 offset = fract(grid) - center;
	float distance_to_star = length(offset);
	float pixel_width = fwidth(grid.x);
	float core = 1.0 - smoothstep(radius, radius + pixel_width, distance_to_star);
	float halo = exp(-distance_to_star * distance_to_star * 160.0) * 0.15;
	halo += exp(-distance_to_star * distance_to_star * 30.0) * glare * 0.14;
	vec2 axis_distance = abs(offset);
	float rays = exp(-axis_distance.x * 220.0 - axis_distance.y * 18.0);
	rays += exp(-axis_distance.y * 220.0 - axis_distance.x * 18.0);

	float twinkle = 1.0 + sin(TIME * (0.7 + star_values.x) + star_values.y * TAU) * twinkle_strength;
	vec3 color = mix(cool_star_color.rgb, warm_star_color.rgb, star_values.x);
	float visible = step(threshold, presence);
	return color * (core + halo + rays * glare) * visible * twinkle * star_brightness;
}


void fragment() {
	float aspect_ratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 screen_position = (UV - 0.5) * vec2(aspect_ratio, 1.0);
	vec2 travel = viewer_position * parallax_strength;
	float time = TIME * animation_speed;

	// Stars at infinity stay fixed; intervening gas and dust can obscure them.
	vec3 distant_stars = render_star_layer(screen_position, 140.0, 0.018, 0.975, vec2(0.0), 0.0);
	vec4 nebula = render_nebula(screen_position, travel, time);
	vec3 color = (background_color.rgb + distant_stars * 0.45) * nebula.a + nebula.rgb;

	// Most stars barely move; the sparse nearest layer keeps its stronger parallax.
	color += render_star_layer(screen_position + travel * 0.06, 65.0, 0.025, 0.96, vec2(0.23, 0.41), 0.0) * 0.8;
	color += render_star_layer(screen_position + travel * 0.85, 23.0, 0.035, 0.985, vec2(0.67, 0.19), 0.7);

	float vignette = smoothstep(0.2, 1.2, length(screen_position * vec2(0.6, 1.0)));
	color *= 1.0 - vignette * vignette_strength;
	COLOR = vec4(color, 1.0);
}
