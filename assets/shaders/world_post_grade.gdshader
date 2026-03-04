shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float exposure : hint_range(0.5, 2.0) = 1.07;
uniform float contrast : hint_range(0.5, 1.8) = 1.10;
uniform float saturation : hint_range(0.0, 2.0) = 1.10;
uniform float tone_strength : hint_range(0.0, 1.0) = 0.16;
uniform vec4 shadow_tint : source_color = vec4(0.90, 0.92, 1.0, 1.0);
uniform vec4 highlight_tint : source_color = vec4(1.0, 0.99, 0.93, 1.0);
uniform float sharpen_strength : hint_range(0.0, 1.0) = 0.23;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.24;
uniform float vignette_softness : hint_range(0.01, 0.8) = 0.30;
uniform float grain_strength : hint_range(0.0, 0.08) = 0.012;
uniform float flare_lift : hint_range(0.0, 0.6) = 0.0;
uniform float hit_trail_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec2 hit_trail_direction = vec2(0.0, -1.0);
uniform float hit_trail_pixels : hint_range(0.0, 10.0) = 2.4;
uniform vec4 hit_trail_tint : source_color = vec4(0.80, 0.94, 1.0, 1.0);
uniform float hit_tint_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hit_tint_color : source_color = vec4(0.84, 0.97, 1.0, 1.0);
uniform float lut_pulse_strength : hint_range(0.0, 1.0) = 0.0;
uniform float lut_palette_phase : hint_range(0.0, 1.0) = 0.0;
uniform float chroma_strength : hint_range(0.0, 4.0) = 0.0;
uniform float radial_warp_strength : hint_range(0.0, 0.08) = 0.0;
uniform float scanline_strength : hint_range(0.0, 0.5) = 0.0;
uniform float scanline_density : hint_range(120.0, 1800.0) = 540.0;
uniform float phase_tint_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 phase_tint_color : source_color = vec4(1.0, 0.92, 0.90, 1.0);
uniform float energy_wave_strength : hint_range(0.0, 0.6) = 0.0;
uniform float energy_wave_density : hint_range(1.0, 20.0) = 8.0;
uniform float energy_wave_speed : hint_range(0.0, 4.0) = 1.1;
uniform vec4 energy_wave_color : source_color = vec4(0.62, 0.90, 1.0, 1.0);

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec3 apply_lut_pulse(vec3 color, float phase, float strength) {
	float amount = clamp(strength, 0.0, 1.0);
	float wave = 0.5 + 0.5 * sin((phase + TIME * 0.08) * 6.2831853);
	vec3 lut_a = vec3(
		color.r * 1.04 + color.b * 0.03,
		color.g * 0.97 + color.r * 0.02,
		color.b * 1.06 + color.g * 0.02
	);
	vec3 lut_b = vec3(
		color.r * 0.95 + color.g * 0.04,
		color.g * 1.07 + color.b * 0.02,
		color.b * 0.93 + color.r * 0.07
	);
	return mix(color, mix(lut_a, lut_b, wave), amount);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 center = uv - vec2(0.5, 0.5);
	float dist = length(center);
	vec2 warp_uv = uv + center * dist * radial_warp_strength;
	vec2 sample_uv = clamp(warp_uv, vec2(0.0), vec2(1.0));

	vec3 base = texture(screen_texture, sample_uv).rgb;
	vec2 trail_dir = hit_trail_direction;
	float trail_len = length(trail_dir);
	if (trail_len <= 0.0001) {
		trail_dir = vec2(0.0, -1.0);
	} else {
		trail_dir /= trail_len;
	}
	vec2 trail_step = trail_dir * px * hit_trail_pixels;
	vec3 trail = (
		texture(screen_texture, clamp(sample_uv - trail_step, vec2(0.0), vec2(1.0))).rgb * 0.52 +
		texture(screen_texture, clamp(sample_uv - trail_step * 2.05, vec2(0.0), vec2(1.0))).rgb * 0.32 +
		texture(screen_texture, clamp(sample_uv - trail_step * 3.25, vec2(0.0), vec2(1.0))).rgb * 0.16
	);
	base = mix(base, max(base, trail * hit_trail_tint.rgb), clamp(hit_trail_amount, 0.0, 1.0));
	float chroma = clamp(chroma_strength, 0.0, 4.0);
	if (chroma > 0.0001) {
		vec2 radial = vec2(0.0, -1.0);
		float radial_len = length(center);
		if (radial_len > 0.0001) {
			radial = center / radial_len;
		}
		vec2 chroma_offset = radial * px * chroma * (0.4 + dist * 1.6);
		float red = texture(screen_texture, clamp(sample_uv + chroma_offset, vec2(0.0), vec2(1.0))).r;
		float blue = texture(screen_texture, clamp(sample_uv - chroma_offset, vec2(0.0), vec2(1.0))).b;
		base = vec3(red, base.g, blue);
	}
	vec3 blur = (
		texture(screen_texture, clamp(sample_uv + vec2(px.x, 0.0), vec2(0.0), vec2(1.0))).rgb +
		texture(screen_texture, clamp(sample_uv - vec2(px.x, 0.0), vec2(0.0), vec2(1.0))).rgb +
		texture(screen_texture, clamp(sample_uv + vec2(0.0, px.y), vec2(0.0), vec2(1.0))).rgb +
		texture(screen_texture, clamp(sample_uv - vec2(0.0, px.y), vec2(0.0), vec2(1.0))).rgb
	) * 0.25;

	vec3 color = base + (base - blur) * sharpen_strength;
	color *= exposure + flare_lift;

	float lum = luma(color);
	vec3 tone = mix(shadow_tint.rgb, highlight_tint.rgb, smoothstep(0.18, 0.85, lum));
	color = mix(color, color * tone, tone_strength);
	color = mix(color, color * hit_tint_color.rgb, clamp(hit_tint_strength, 0.0, 1.0));
	color = apply_lut_pulse(color, lut_palette_phase, lut_pulse_strength);
	color = mix(color, color * phase_tint_color.rgb, clamp(phase_tint_strength, 0.0, 1.0));

	color = (color - vec3(0.5)) * contrast + vec3(0.5);
	float gray = luma(color);
	color = mix(vec3(gray), color, saturation);

	float vignette = smoothstep(vignette_softness, 0.82, dist);
	color *= 1.0 - (vignette * vignette_strength);
	float scanline = sin((uv.y + TIME * 0.03) * scanline_density) * 0.5 + 0.5;
	color *= 1.0 - clamp(scanline_strength, 0.0, 0.5) * (0.30 + scanline * 0.70);
	float wave_strength = clamp(energy_wave_strength, 0.0, 0.6);
	if (wave_strength > 0.0001) {
		float wave = 0.5 + 0.5 * sin((dist * energy_wave_density - TIME * energy_wave_speed) * 6.2831853);
		float wave_band = smoothstep(0.26, 0.98, wave);
		float wave_falloff = 1.0 - smoothstep(0.08, 0.96, dist);
		color += energy_wave_color.rgb * wave_band * wave_falloff * wave_strength;
	}

	float grain = (hash21(uv * vec2(1430.0, 970.0) + TIME * vec2(51.0, 37.0)) - 0.5) * grain_strength;
	color += vec3(grain);

	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
