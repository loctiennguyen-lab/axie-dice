shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
// Venom pool and low mist that hide the flat waist cut of the Venom Chimera boss.
// mode 0 = pool disc (UV centred, 0..1), mode 1 = open tube of mist (UV.y 0 = top, 1 = bottom).
// `motion` 0 freezes the drift and the pulse (Reduce flashing).
uniform int mode = 0;
uniform vec3 deep_color : source_color = vec3(0.07, 0.30, 0.05);
uniform vec3 glow_color : source_color = vec3(0.55, 0.95, 0.15);
uniform float strength = 0.9;
uniform float motion = 1.0;
uniform float seed = 0.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21) + seed);
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	return vnoise(p) * 0.6 + vnoise(p * 2.07 + 7.1) * 0.4;
}

void fragment() {
	float t = TIME * motion;
	if (mode == 0) {
		vec2 c = UV * 2.0 - 1.0;
		float r = length(c);
		float edge = 1.0 - smoothstep(0.55, 1.0, r);
		float n = fbm(c * 3.2 + vec2(t * 0.10, -t * 0.07));
		float blobs = smoothstep(0.55, 0.78, fbm(c * 5.5 + vec2(-t * 0.18, t * 0.12) + 3.0));
		float rim = smoothstep(0.55, 0.9, r) * (1.0 - smoothstep(0.9, 1.0, r));
		vec3 col = mix(deep_color, glow_color, clamp(n * 0.5 + blobs * 0.7 + rim * 0.5, 0.0, 1.0));
		ALBEDO = col;
		ALPHA = clamp(edge * strength + rim * 0.25, 0.0, 1.0) * 0.95;
	} else {
		float v = UV.y;                       // 1 at the pool, 0 at the top of the mist
		float h = 1.0 - v;
		float fade = smoothstep(0.0, 0.25, v) * (0.35 + 0.65 * v);
		vec2 p = vec2(UV.x * 7.0, h * 2.6 - t * 0.22);
		float n = fbm(p + seed * 3.0);
		float wisps = smoothstep(0.18, 0.62, n + h * 0.0) * 0.8 + 0.2 * v * v;
		ALBEDO = mix(deep_color * 1.4, glow_color, h * 0.5 + wisps * 0.4);
		float facing = pow(clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 0.7);   // soft silhouette, no glass wall
		ALPHA = clamp(wisps * fade * strength * 1.3 * mix(0.15, 1.0, facing), 0.0, 0.92);
	}
}
