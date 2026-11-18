shader_type spatial;
// Gentle wind sway for the rounded trees/bushes baked into the room glbs.
// Displacement grows with world height, so trunks stay planted and canopies drift.
// wind_strength is raised for the storm mood by WindSway.set_strength().

uniform vec4 albedo : source_color = vec4(0.36, 0.68, 0.29, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float wind_strength = 1.0;
uniform float ground_y = 0.3;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = max(world.y - ground_y, 0.0);
	float phase = TIME * (1.4 + 0.6 * wind_strength) + world.x * 0.35 + world.z * 0.27;
	float sway = (sin(phase) * 0.035 + sin(phase * 2.3 + 1.7) * 0.012) * h * wind_strength;
	// Push along world X/Z, converted back to model space so rotated nodes sway the same way.
	vec3 push = (inverse(MODEL_MATRIX) * vec4(sway, 0.0, sway * 0.4, 0.0)).xyz;
	VERTEX += push;
}

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness;
}
