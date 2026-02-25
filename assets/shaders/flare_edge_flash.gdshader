shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float edge_strength : hint_range(0.0, 2.0) = 0.0;
uniform float edge_softness : hint_range(0.02, 0.40) = 0.18;
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float edge = 1.0 - smoothstep(0.0, edge_softness, edge_dist);
	float glow = pow(clamp(edge, 0.0, 1.0), 0.48) * edge_strength;
	COLOR = vec4(edge_color.rgb * glow, edge_color.a * glow);
}
