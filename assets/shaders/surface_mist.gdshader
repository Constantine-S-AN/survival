shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform bool effect_enabled = true;
uniform vec4 mist_tint : source_color = vec4(0.10, 0.17, 0.24, 1.0);
uniform float mist_density : hint_range(0.0, 0.45) = 0.13;
uniform float mist_softness : hint_range(0.1, 0.95) = 0.66;
uniform float mist_scale : hint_range(0.2, 8.0) = 2.2;
uniform vec2 flow_velocity = vec2(0.032, -0.022);
uniform float pulse_speed : hint_range(0.05, 2.5) = 0.58;
uniform float flare_reveal : hint_range(0.0, 1.0) = 0.0;

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

float fbm(vec2 p) {
	float value = 0.0;
	float amp = 0.55;
	float freq = 1.0;
	for (int i = 0; i < 4; i++) {
		value += value_noise(p * freq) * amp;
		freq *= 2.03;
		amp *= 0.52;
	}
	return value;
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	if (!effect_enabled) {
		COLOR = vec4(0.0);
	} else {
		vec2 uv = SCREEN_UV;
		vec2 flow = flow_velocity * TIME * (0.45 + pulse_speed * 0.55);
		float n_a = fbm(uv * vec2(mist_scale * 2.1, mist_scale * 1.6) + flow);
		float n_b = fbm(uv * vec2(mist_scale * 3.8, mist_scale * 2.7) - flow * 1.31);
		float pattern = mix(n_a, n_b, 0.58);
		float softness = mix(0.32, 0.06, mist_softness);
		float mist_mask = smoothstep(0.34 - softness, 0.92 + softness, pattern);

		float wave = sin((uv.x + uv.y * 0.8 + TIME * 0.21 * pulse_speed) * 5.4) * 0.5 + 0.5;
		mist_mask *= mix(0.84, 1.10, wave);

		vec3 scene = texture(screen_texture, uv).rgb;
		float shadow_weight = 1.0 - smoothstep(0.25, 0.85, luma(scene));
		float reveal_factor = mix(1.0, 0.16, clamp(flare_reveal, 0.0, 1.0));
		float alpha = mist_density * mist_mask * mix(0.55, 1.0, shadow_weight) * reveal_factor;

		float grain = (hash21(uv * vec2(1600.0, 920.0) + TIME * vec2(42.0, 27.0)) - 0.5) * 0.06;
		vec3 color = clamp(mist_tint.rgb + vec3(grain), vec3(0.0), vec3(1.0));
		COLOR = vec4(color, clamp(alpha, 0.0, 1.0));
	}
}
