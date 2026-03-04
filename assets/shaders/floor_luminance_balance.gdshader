shader_type canvas_item;
render_mode unshaded;

uniform float blend_neighbors : hint_range(0.0, 1.0) = 0.70;
uniform float luma_mix : hint_range(0.0, 1.0) = 0.54;
uniform float contrast : hint_range(0.2, 1.2) = 0.46;
uniform float gamma : hint_range(0.5, 2.0) = 1.05;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec4 base = texture(TEXTURE, UV);
	vec3 neighbors = (
		texture(TEXTURE, UV + vec2(px.x, 0.0)).rgb +
		texture(TEXTURE, UV - vec2(px.x, 0.0)).rgb +
		texture(TEXTURE, UV + vec2(0.0, px.y)).rgb +
		texture(TEXTURE, UV - vec2(0.0, px.y)).rgb
	) * 0.25;

	vec3 balanced = mix(base.rgb, neighbors, blend_neighbors);
	float lum = luma(balanced);
	balanced = mix(balanced, vec3(lum), luma_mix);
	balanced = (balanced - vec3(0.5)) * contrast + vec3(0.5);
	balanced = pow(clamp(balanced, vec3(0.0), vec3(1.0)), vec3(gamma));
	COLOR = vec4(balanced, base.a);
}
