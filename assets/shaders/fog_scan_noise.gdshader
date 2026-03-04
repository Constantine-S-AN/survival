shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform bool effect_enabled = true;
uniform float line_density : hint_range(50.0, 800.0) = 320.0;
uniform float line_strength : hint_range(0.0, 0.4) = 0.08;
uniform float noise_strength : hint_range(0.0, 0.25) = 0.05;
uniform float noise_scale : hint_range(80.0, 2200.0) = 920.0;
uniform float noise_scroll_speed : hint_range(0.0, 4.0) = 0.82;
uniform float noise_softness : hint_range(0.0, 1.0) = 0.74;
uniform vec4 tint_color : source_color = vec4(0.05, 0.12, 0.18, 1.0);
uniform float tint_alpha : hint_range(0.0, 0.8) = 0.30;
uniform float pulse_speed : hint_range(0.1, 2.0) = 0.65;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	if (!effect_enabled) {
		COLOR = vec4(0.0);
	} else {
		vec2 uv = SCREEN_UV;
		float scan = sin((uv.y * line_density) + (TIME * 36.0 * pulse_speed)) * 0.5 + 0.5;
		float line_mod = mix(1.0 - line_strength, 1.0, scan);
		vec2 flow = vec2(TIME * 0.13 * noise_scroll_speed, -TIME * 0.19 * noise_scroll_speed);
		float n_a = value_noise(uv * vec2(noise_scale, noise_scale * 0.84) + flow);
		float n_b = value_noise(uv * vec2(noise_scale * 1.74, noise_scale * 1.42) - flow * 1.37);
		float n = mix(n_a, n_b, noise_softness);
		float grain = (n - 0.5) * 2.0 * noise_strength;

		vec3 color = clamp(tint_color.rgb + vec3(grain), vec3(0.0), vec3(1.0));
		float alpha = clamp(tint_alpha, 0.0, 1.0) * line_mod;
		COLOR = vec4(color, alpha);
	}
}
