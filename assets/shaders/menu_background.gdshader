shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.018, 0.035, 0.070, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.004, 0.010, 0.028, 1.0);
uniform vec4 accent_color : source_color = vec4(0.180, 0.640, 0.920, 1.0);
uniform float scanline_strength : hint_range(0.0, 0.08) = 0.024;
uniform float noise_strength : hint_range(0.0, 0.08) = 0.018;
uniform float pulse_strength : hint_range(0.0, 0.08) = 0.026;
uniform float time_sec = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	vec3 base = mix(top_color.rgb, bottom_color.rgb, uv.y);
	float scan = sin((uv.y + time_sec * 0.05) * 900.0) * 0.5 + 0.5;
	float n = hash(floor(uv * vec2(1100.0, 650.0) + vec2(time_sec * 18.0, time_sec * 11.0)));
	float pulse = sin(time_sec * 0.55 + uv.y * 2.2) * 0.5 + 0.5;
	base += accent_color.rgb * pulse * pulse_strength;
	base += (scan - 0.5) * scanline_strength;
	base += (n - 0.5) * noise_strength;
	COLOR = vec4(base, 1.0);
}
