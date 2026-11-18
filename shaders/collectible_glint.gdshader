shader_type spatial;
// Overlay glint for unmarked collectibles: soft rim pulse plus a sweep that strengthens as the player nears.
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform vec4 glint_color : source_color = vec4(1.0, 0.86, 0.45, 1.0);
uniform float proximity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	float pulse = 0.55 + 0.45 * sin(TIME * 2.6);
	float world_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
	float sweep = smoothstep(0.93, 1.0, sin(TIME * 1.4 - world_y * 18.0));
	ALBEDO = glint_color.rgb;
	ALPHA = (rim * pulse * (0.3 + 0.7 * proximity) + sweep * proximity * 0.5) * glint_color.a;
}
