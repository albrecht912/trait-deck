shader_type sky;
// Stylised "Cozy Campus" sky: soft gradient, puffy toon clouds, round sun, green ground below the horizon.
// `overcast` (0..1) is driven by session_manager.gd for the storm mood.

uniform vec3 top_color : source_color = vec3(0.33, 0.62, 0.96);
uniform vec3 horizon_color : source_color = vec3(0.78, 0.90, 1.0);
uniform vec3 ground_color : source_color = vec3(0.50, 0.72, 0.38);
uniform vec3 cloud_color : source_color = vec3(1.0, 0.98, 0.95);
uniform vec3 storm_top : source_color = vec3(0.30, 0.36, 0.46);
uniform vec3 storm_horizon : source_color = vec3(0.52, 0.57, 0.64);
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.45;
uniform float overcast : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0, a = 0.5;
	for (int k = 0; k < 4; k++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}

void sky() {
	vec3 d = EYEDIR;
	vec3 top = mix(top_color, storm_top, overcast);
	vec3 hor = mix(horizon_color, storm_horizon, overcast);
	vec3 col = mix(hor, top, smoothstep(0.0, 0.6, d.y));
	if (d.y > 0.0) {
		vec2 uv = d.xz / (d.y + 0.25) * 1.4 + vec2(TIME * 0.006, 0.0);
		float n = fbm(uv);
		float cover = mix(cloud_cover, 0.95, overcast);
		float c = smoothstep(1.0 - cover, 1.0 - cover + 0.04, n);  // crisp, cartoon edges
		float shade = smoothstep(0.3, 0.9, fbm(uv + 0.15));
		vec3 cc = mix(cloud_color, cloud_color * vec3(0.82, 0.86, 0.95), shade);
		cc = mix(cc, vec3(0.45, 0.49, 0.56), overcast);
		col = mix(col, cc, c * smoothstep(0.0, 0.12, d.y));
		if (LIGHT0_ENABLED) {
			float sun = smoothstep(0.9975, 0.999, dot(d, LIGHT0_DIRECTION));
			col = mix(col, vec3(1.0, 0.95, 0.75), sun * (1.0 - overcast) * (1.0 - c));
		}
	} else {
		col = mix(hor, ground_color * mix(1.0, 0.6, overcast), smoothstep(0.0, -0.08, d.y));
	}
	COLOR = col;
}
