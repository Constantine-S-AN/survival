shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform bool effect_enabled = true;
uniform float line_density : hint_range(50.0, 800.0) = 320.0;
uniform float line_strength : hint_range(0.0, 0.4) = 0.08;
uniform float noise_strength : hint_range(0.0, 0.25) = 0.05;
uniform vec4 tint_color : source_color = vec4(0.05, 0.12, 0.18, 1.0);
uniform float tint_alpha : hint_range(0.0, 0.8) = 0.30;
uniform float pulse_speed : hint_range(0.1, 2.0) = 0.65;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	if (!effect_enabled) {
		COLOR = vec4(0.0);
	} else {
		vec2 uv = SCREEN_UV;
		float scan = sin((uv.y * line_density) + (TIME * 36.0 * pulse_speed)) * 0.5 + 0.5;
		float line_mod = mix(1.0 - line_strength, 1.0, scan);
		float n = hash(uv * vec2(240.0, 180.0) + TIME * vec2(0.23, 0.41));
		float grain = (n - 0.5) * 2.0 * noise_strength;

		vec3 color = tint_color.rgb + vec3(grain);
		float alpha = clamp(tint_alpha, 0.0, 1.0) * line_mod;
		COLOR = vec4(color, alpha);
	}
}
